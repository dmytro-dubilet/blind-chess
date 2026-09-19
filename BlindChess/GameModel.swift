import SwiftUI
import Combine
import AVFoundation
import AudioToolbox
import StockfishKit

@MainActor
final class GameModel: ObservableObject {
    @Published private(set) var game = ChessGame()
    @Published private(set) var language = AppLanguage.current
    @Published var difficulty: Difficulty = .beginner
    @Published var human: Side = .white
    @Published private(set) var thinking = false
    @Published private(set) var voiceEnabled = false
    @Published private(set) var authorizing = false
    struct RecoveryProposal {
        let original: String
        let corrected: String
        let move: Move
        let gameID: UUID
        let ply: Int
        let label: String
    }
    @Published private(set) var recoveryProposal: RecoveryProposal?
    @Published private(set) var undoConfirmation = false
    private var undoSnapshot: (gameID: UUID, ply: Int)?
    private struct Clarification {
        let moves: [Move]
        let gameID: UUID
        let ply: Int
        let needsConfirmation: Bool
    }
    private var pendingClarification: Clarification?
    @Published var commandFeedback: String?
    @Published var message = L("Представьте доску. Первый ход — ваш.")
    @Published var engineError: String?
    @Published var inputFeedback: String?
    @Published private(set) var showBoard = false
    @Published private(set) var selectedSquare: Int?
    @Published private(set) var promotionMoves: [Move] = []
    @Published private(set) var reviewPly: Int?
    @Published var peeks = 0
    let voice = VoiceController()
    private let boardSounds = BoardMoveSounds()
    private var errorHapticTask: Task<Void, Never>?
    private var engineTask: Task<Void, Never>?
    private var voiceStartTask: Task<Void, Never>?
    @Published private(set) var sessionID = UUID()
    private var active = true
    private var observations = Set<AnyCancellable>()
    @Published private(set) var archivedGames: [ArchivedGame] = []
    @Published var archiveError: String?
    private var archiveStore: GameArchiveStore?
    private var archiveID = UUID()
    private var gameStartedAt = Date()
    @Published private var browsingArchive = false
    private let saveKey = "blindchess.session.v1"

    private struct SavedGame: Codable {
        var game: ChessGame
        var difficulty: Difficulty
        var human: Side
        var peeks: Int
        var archiveID: UUID?
        var startedAt: Date?
    }

    init() {
        showBoard = UserDefaults.standard.bool(forKey: "blindchess.boardVisible")
        if let data = UserDefaults.standard.data(forKey: saveKey), let saved = try? JSONDecoder().decode(SavedGame.self, from: data),
           saved.game.positions.count == saved.game.records.count + 1,
           saved.game.positions.allSatisfy({ $0.board.count == 64 }) {
            game = saved.game; difficulty = saved.difficulty; human = saved.human; peeks = saved.peeks
            archiveID = saved.archiveID ?? UUID(); gameStartedAt = saved.startedAt ?? Date()
            message = game.outcome ?? L("Партия сохранена. Можно продолжать.")
        }
        do {
            let directory = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            archiveStore = try GameArchiveStore(url: directory.appendingPathComponent("GameArchive/games.json"))
            archivedGames = archiveStore?.entries ?? []
            persist()
        } catch { archiveError = L("Не удалось открыть архив. Сохранённый файл не изменён.") }
        DiagnosticLog.shared.record("app.launch", ["os": UIDevice.current.systemVersion,
            "device": UIDevice.current.model, "version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?",
            "build": Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?", "whisper": "small_216MB", "logging": "1"])
        snapshot("game.restored")
        voice.objectWillChange.sink { [weak self] _ in self?.objectWillChange.send() }.store(in: &observations)
        voice.onPhrase = { [weak self] text in self?.receive(text, source: "voice") }
        voice.onUncertainPhrase = { [weak self] text in self?.receive(text, source: "voice_uncertain") }
        voice.onWeakPhrase = { [weak self] text in
            guard let self, self.active, self.canMove,
                  let move = MoveParser.weakSpeechCandidate(text, in: self.displayedPosition) else { return false }
            self.proposeRecovery(text, move: move, reason: "weak_audio_chess_context")
            return true
        }
        voice.onSpeechFinished = nil
        voice.onFailure = { [weak self] in self?.voiceEnabled = false }
        voice.onRecognitionFailure = { [weak self] text in self?.showInputError(text) }
        NotificationCenter.default.publisher(for: AVAudioSession.routeChangeNotification)
            .sink { [weak self] _ in Task { @MainActor in
                self?.voice.audioRouteChanged()
                let audio = AVAudioSession.sharedInstance()
                DiagnosticLog.shared.record("audio.route_changed", [
                    "input": audio.currentRoute.inputs.map { $0.portType.rawValue }.joined(separator: ","),
                    "output": audio.currentRoute.outputs.map { $0.portType.rawValue }.joined(separator: ",")])
            } }.store(in: &observations)
        NotificationCenter.default.publisher(for: ProcessInfo.thermalStateDidChangeNotification)
            .sink { _ in DiagnosticLog.shared.record("device.thermal", ["state": String(ProcessInfo.processInfo.thermalState.rawValue)]) }.store(in: &observations)
        NotificationCenter.default.publisher(for: UIApplication.didReceiveMemoryWarningNotification)
            .sink { _ in DiagnosticLog.shared.record("device.memory_warning") }.store(in: &observations)
        NotificationCenter.default.publisher(for: AVAudioSession.interruptionNotification)
            .sink { [weak self] note in
                let type = (note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt).map(String.init) ?? "unknown"
                Task { @MainActor in self?.trace("audio.interruption", ["type": type]); self?.pauseVoice(); self?.voice.stopAll(deactivateAudio: true) } }.store(in: &observations)
    }

    func setLanguage(_ value: AppLanguage) {
        guard language != value else { return }
        pauseVoice()
        errorHapticTask?.cancel(); errorHapticTask = nil
        inputFeedback = nil
        engineError = nil
        voice.clearError()
        UserDefaults.standard.set(value.rawValue, forKey: "blindchess.language")
        language = value
        message = status
        trace("settings.language", ["language": value.rawValue])
    }

    private func spokenMove(_ record: MoveRecord) -> String {
        game.positions[record.id].spoken(record.move)
    }

    var displayedPly: Int { reviewPly ?? game.records.count }
    var inputGame: ChessGame { game.prefix(through: displayedPly) }
    var isReviewing: Bool { reviewPly != nil }
    var displayedPosition: Position { game.positions[displayedPly] }
    var displayedRecords: [MoveRecord] { Array(game.records.prefix(displayedPly)) }

    func stepHistory(_ delta: Int) {
        let target = min(game.records.count, max(0, displayedPly + delta))
        guard target != displayedPly else { return }
        clearBoardSelection()
        pauseVoice()
        pendingClarification = nil
        dismissRecovery()
        inputFeedback = nil
        reviewPly = target == game.records.count ? nil : target
        trace("history.step", ["displayed_ply": String(target), "direction": delta < 0 ? "back" : "forward"])
        prepareDisplayedGame()

    }

    func returnToLive() {
        pauseVoice()
        pendingClarification = nil
        dismissRecovery()
        reviewPly = nil
        clearBoardSelection()
        trace("history.live")
    }

    var canMove: Bool { !browsingArchive && (isReviewing || !thinking) && displayedPosition.turn == human && inputGame.outcome == nil }
    var status: String {
        if inputGame.outcome != nil { return L("Партия завершена") }
        if voice.preparing { return L("Микрофон пока выключен") }
        if authorizing { return L("Включаю микрофон…") }
        if thinking && !isReviewing { return L("Компьютер думает") }
        if voice.decoding { return L("Распознаю ход") }
        if voice.speaking { return L("Озвучиваю ход") }
        if voice.listening { return L("Слушаю ваш ход") }
        return displayedPosition.inCheck(human) ? L("Вам шах") : L("Ваш ход")
    }
    var lastComputerMove: MoveRecord? { game.records.last(where: { $0.side != human }) }

    private func prepareDisplayedGame() {
        guard active, !browsingArchive, inputGame.outcome == nil else { return }
        voice.preloadCachedModel()
        voice.prepareCaptureSession()
    }

    func resume() {
        trace("app.active")
        active = true
        prepareDisplayedGame()
        guard game.outcome == nil else { return }
        if game.position.turn != human && game.outcome == nil && !thinking { computerMove() }
    }

    func suspend() {
        errorHapticTask?.cancel(); errorHapticTask = nil
        trace("app.background")
        active = false
        engineTask?.cancel(); engineTask = nil; thinking = false
        clearBoardSelection()
        pauseVoice()
        voice.stopAll(deactivateAudio: true)
    }

    func beginVoiceHold() {
        errorHapticTask?.cancel(); errorHapticTask = nil
        guard active, canMove, !voiceEnabled, !authorizing, !voice.preparing else { return }
        clearBoardSelection()
        if voice.speaking || voice.decoding { voice.stopAll(deactivateAudio: false) }
        commandFeedback = nil
        trace("ui.microphone_down")
        inputFeedback = nil
        voiceEnabled = true
        authorizing = true
        voiceStartTask = Task { [weak self] in
            guard let self else { return }
            let wasReady = self.voice.ready
            let allowed = await self.voice.authorize()
            guard !Task.isCancelled, self.voiceEnabled else { return }
            self.authorizing = false
            guard allowed, wasReady else {
                self.voiceEnabled = false
                if allowed { self.voice.prepareCaptureSession() }
                return
            }
            self.listenIfReady()
        }
    }

    func endVoiceHold() {
        guard voiceEnabled || authorizing else { return }
        trace("ui.microphone_up")
        voiceEnabled = false
        voiceStartTask?.cancel(); voiceStartTask = nil
        authorizing = false
        voice.finishHeldRecording()
    }

    func cancelVoiceHold() {
        guard voiceEnabled || authorizing else { return }
        trace("ui.microphone_cancel")
        pauseVoice()
    }

    func pauseVoice() {
        dismissUndoConfirmation()
        pendingClarification = nil
        dismissRecovery()
        trace("voice.pause")
        voiceStartTask?.cancel(); voiceStartTask = nil
        authorizing = false; voiceEnabled = false; voice.stopAll()
    }

    private func proposeUndo(_ text: String) {
        guard game.records.contains(where: { $0.side == human }) else { showInputError(L("Нет ходов для отмены")); return }
        pauseVoice()
        undoSnapshot = (sessionID, game.records.count)
        undoConfirmation = true
        trace("input.undo_proposed", ["text": text])
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }

    func dismissUndoConfirmation() { undoConfirmation = false; undoSnapshot = nil }

    func confirmVoiceUndo() {
        guard let snapshot = undoSnapshot, snapshot.gameID == sessionID,
              snapshot.ply == game.records.count else { dismissUndoConfirmation(); return }
        dismissUndoConfirmation()
        undo(source: "voice_confirmed")
    }

    private func listenIfReady() {
        guard active, voiceEnabled, canMove, !voice.speaking, !voice.listening, !voice.decoding, selectedSquare == nil, promotionMoves.isEmpty else { return }
        voice.listen()
    }

    func receive(_ text: String, source: String = "text") {
        trace("input.received", ["text": text, "source": source])
        guard canMove else { trace("input.ignored", ["reason": "not_player_turn"]); return }
        dismissRecovery()
        clearBoardSelection()
        inputFeedback = nil
        let phrase = MoveParser.normalize(text).trimmingCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters))
        if phrase.contains("пауза") || phrase == "стоп" { pauseVoice(); return }
        if phrase.contains("повтори") { repeatMove(); return }
        if MoveParser.isUndoCommand(text) {
            if source == "voice_uncertain" { proposeUndo(text) }
            else { undo(source: source) }
            return
        }
        if MoveParser.isSuspectedUndoCommand(text) { proposeUndo(text); return }
        commandFeedback = nil
        let context = pendingClarification
        pendingClarification = nil
        if let context, context.gameID == sessionID, context.ply == displayedPly,
           let choices = MoveParser.clarification(text, candidates: context.moves, in: displayedPosition) {
            trace("input.clarification", ["text": text, "candidates": choices.map(\.uci).joined(separator: ",")])
            if choices.count == 1 {
                if context.needsConfirmation || source == "voice_uncertain" {
                    proposeRecovery(text, move: choices[0], reason: "clarification_uncertain")
                } else { receive(choices[0].uci, source: "voice_clarified") }
            } else if choices.isEmpty {
                askClarification(context.moves, needsConfirmation: context.needsConfirmation)
            } else { askClarification(choices, needsConfirmation: context.needsConfirmation) }
            return
        }
        let parsed = MoveParser.parseRecovering(text, in: displayedPosition)
        if let corrected = parsed.correctedText {
            trace("input.text_recovery", ["original": text, "corrected": corrected, "result": String(describing: parsed.result)])
        }
        switch parsed.result {
        case .move(let move):
            if source == "voice_uncertain" { proposeRecovery(text, move: move, reason: "low_confidence"); return }
            voice.stopListening()
            let ply = displayedPly
            var updated = game
            guard updated.play(move, at: ply) else { trace("move.rejected"); return }
            if isReviewing {
                let removed = game.records.count - ply
                cancelWork()
                engineError = nil
                trace("history.branch", ["from_ply": String(ply), "removed_plies": String(removed), "move": move.uci])
            }
            game = updated
            if showBoard && active { boardSounds.play(san: game.records.last!.san) }
            trace("move.player", ["san": game.records.last!.san, "outcome": game.outcome ?? ""])
            message = L("Ваш ход: {0}", String(describing: game.records.last!.san))
            persist()
            if let outcome = game.outcome {
                message = outcome
                if !showBoard { announce(outcome) }
                else { trace("speech.outcome_skipped", ["reason": "board_visible"]) }
                return
            }
            computerMove()
        case .ambiguous, .invalid:
            if let match = MoveParser.contextualMatch(text, in: displayedPosition) {
                trace("input.context_recovery", ["text": text, "score": String(match.score),
                    "changed_destination": String(match.changedDestination), "candidates": match.moves.map(\.uci).joined(separator: ",")])
                if match.moves.count == 1 {
                    proposeRecovery(text, move: match.moves[0], reason: "context_phonetics")
                } else {
                    askClarification(match.moves, needsConfirmation: parsed.result != .ambiguous || source == "voice_uncertain")
                }
                return
            }
            let issue = MoveParser.explanation(parsed.correctedText ?? text, in: displayedPosition, ambiguous: parsed.result == .ambiguous)
            trace(parsed.result == .ambiguous ? "input.ambiguous" : "input.invalid", ["text": text, "reason": issue.code, "explanation": issue.message])
            showInputError(issue.message)
        }
    }

    private func proposeRecovery(_ text: String, move: Move, reason: String) {
        pauseVoice()
        let kind = displayedPosition.board[move.from]!.kind.localizedName.capitalized
        let capture = displayedPosition.san(move).contains("x")
        let label = kind + " " + squareName(move.from).uppercased() + (capture ? " × " : " – ") + squareName(move.to).uppercased()
        recoveryProposal = RecoveryProposal(original: text, corrected: move.uci, move: move, gameID: sessionID, ply: displayedPly, label: label)
        trace("input.recovery_proposed", ["original": text, "corrected": move.uci, "uci": move.uci, "reason": reason])
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }

    private func askClarification(_ moves: [Move], needsConfirmation: Bool) {
        guard let first = moves.first else { return }
        pauseVoice()
        pendingClarification = Clarification(moves: moves, gameID: sessionID, ply: displayedPly, needsConfirmation: needsConfirmation)
        let kinds = Set(moves.compactMap { displayedPosition.board[$0.from]?.kind })
        let prompt = kinds.count > 1
            ? L("Какой фигурой на {0}?", squareName(first.to).uppercased())
            : L("С какой клетки на {0}?", squareName(first.to).uppercased())
        trace("input.clarification_requested", ["destination": squareName(first.to), "candidates": moves.map(\.uci).joined(separator: ","), "needs_confirmation": String(needsConfirmation)])
        showInputError(prompt)
    }

    func confirmRecovery() {
        guard let proposal = recoveryProposal else { return }
        recoveryProposal = nil
        guard canMove, proposal.gameID == sessionID, proposal.ply == displayedPly,
              displayedPosition.legalMoves().contains(proposal.move) else {
            trace("input.recovery_stale"); return
        }
        trace("input.recovery_confirmed", ["original": proposal.original, "corrected": proposal.corrected, "uci": proposal.move.uci])
        receive(proposal.move.uci, source: "voice_confirmed")
    }

    func dismissRecovery() {
        guard let proposal = recoveryProposal else { return }
        recoveryProposal = nil
        trace("input.recovery_dismissed", ["original": proposal.original, "corrected": proposal.corrected, "uci": proposal.move.uci])
    }

    private func computerMove() {
        guard game.outcome == nil, game.position.turn != human, !thinking else { return }
        thinking = true
        engineError = nil
        trace("engine.start", ["engine": "Stockfish " + Stockfish.version, "target_elo": String(difficulty.targetElo), "skill": String(difficulty.skill), "budget_ms": String(difficulty.thinkMilliseconds)])
        let engineStarted = ProcessInfo.processInfo.systemUptime
        let snapshot = game.position, level = difficulty, token = sessionID
        let moves = game.records.map { $0.move.uci }
        engineTask = Task { [weak self] in
            let move: Move?
            do {
                let uci = try await Stockfish.bestMove(moves: moves, elo: level.engineElo,
                                                      skill: level.skill, milliseconds: level.thinkMilliseconds)
                if let preferred = snapshot.legalMoves().first(where: { $0.uci == uci }) {
                    move = await Task.detached {
                        var random = SystemRandomNumberGenerator()
                        return BeginnerOpponent.choose(in: snapshot, preferred: preferred, level: level, using: &random)
                    }.value
                    if !Task.isCancelled, let self, token == self.sessionID {
                        self.trace("engine.strength_selection", ["rating": level.rawValue, "mistake_probability": String(level.mistakeProbability), "stockfish_move": uci, "selected_move": move?.uci ?? ""])
                    }
                } else { move = nil }
            } catch {
                guard !Task.isCancelled, let self, token == self.sessionID else { return }
                self.thinking = false
                self.pauseVoice()
                self.engineError = L("Не удалось рассчитать ход Stockfish. Попробуйте ещё раз.")
                self.trace("engine.error", ["error": String(describing: error)])
                return
            }
            guard !Task.isCancelled, let self, token == self.sessionID else {
                DiagnosticLog.shared.record("engine.cancelled", ["duration_ms": diagnosticMS(since: engineStarted)])
                return
            }
            self.thinking = false
            guard let move, self.game.play(move) else {
                self.trace("engine.no_move")
                self.pauseVoice()
                self.engineError = L("Stockfish не вернул допустимый ход. Попробуйте ещё раз.")
                return
            }
            self.trace("engine.finish", ["duration_ms": diagnosticMS(since: engineStarted), "san": self.game.records.last!.san, "outcome": self.game.outcome ?? ""])
            self.persist()
            let record = self.game.records.last!
            var response = self.spokenMove(record) + "."
            if let outcome = self.game.outcome { response += " " + outcome }
            else if self.game.position.inCheck(self.human) { response += L(" Шах.") }
            self.message = self.game.outcome ?? L("Компьютер: {0}. Ваш ход.", String(describing: record.san))
            if self.active && !self.isReviewing && !self.browsingArchive {
                if self.showBoard {
                    self.boardSounds.play(san: record.san)
                    self.trace("speech.move_skipped", ["reason": "board_visible"])
                    self.listenIfReady()
                } else {
                    self.voice.speak(response)
                }
            }
        }
    }

    func retryComputerMove() { engineError = nil; computerMove() }

    private func showInputError(_ text: String) {
        voiceEnabled = false
        inputFeedback = text
        message = text
        errorHapticTask?.cancel()
        errorHapticTask = Task { @MainActor in
            let feedback = UIImpactFeedbackGenerator(style: .heavy)
            feedback.prepare()
            for pulse in 0..<3 {
                guard !Task.isCancelled else { return }
                feedback.impactOccurred(intensity: 1)
                if pulse < 2 {
                    feedback.prepare()
                    do { try await Task.sleep(for: .milliseconds(180)) }
                    catch { return }
                }
            }
        }
        trace("input.error_feedback", ["message": text, "presentation": "banner_haptic", "haptic": "three_heavy_pulses"])
    }

    private func announce(_ text: String) {
        message = text
        voice.speak(text)
    }

    func repeatMove() {
        trace("action.repeat")
        guard !thinking, !isReviewing else { return }
        if let last = lastComputerMove { announce(L("Последний ход компьютера. ") + spokenMove(last)) }
        else { announce(L("Компьютер ещё не ходил. Ваш ход.")) }
    }

    var canTapBoard: Bool { active && canMove && !authorizing }
    var highlightedMoves: [Move] {
        guard let selectedSquare, canTapBoard else { return [] }
        return displayedPosition.legalMoves().filter { $0.from == selectedSquare }
    }

    func setBoardVisible(_ visible: Bool) {
        guard showBoard != visible else { return }
        pendingClarification = nil
        clearBoardSelection()
        showBoard = visible
        if visible && voice.speaking { voice.stopAll() }
        if visible { peeks += 1; persist() }
        UserDefaults.standard.set(visible, forKey: "blindchess.boardVisible")
        trace("ui.board", ["open": String(visible), "gesture": "switch"])
        listenIfReady()
    }

    func tapSquare(_ square: Int) {
        guard showBoard, canTapBoard, (0..<64).contains(square), promotionMoves.isEmpty else { return }
        pendingClarification = nil
        trace("ui.square", ["square": squareName(square)])
        if selectedSquare == square {
            clearBoardSelection(); listenIfReady(); return
        }
        if displayedPosition.board[square]?.side == human {
            // A deliberate board selection supersedes any unfinished voice input.
            voice.stopAll()
            selectedSquare = square
            inputFeedback = nil
            return
        }
        guard let from = selectedSquare else { return }
        let candidates = displayedPosition.legalMoves().filter { $0.from == from && $0.to == square }
        guard !candidates.isEmpty else {
            if let issue = displayedPosition.moveProblem(from: from, to: square) {
                trace("board.invalid_destination", ["from": squareName(from), "to": squareName(square), "reason": issue.code])
                inputFeedback = issue.message
                announce(issue.message)
            }
            return
        }
        if candidates.count > 1 {
            promotionMoves = candidates
        } else {
            receive(candidates[0].uci, source: "board")
        }
    }

    func choosePromotion(_ move: Move) {
        guard canTapBoard, promotionMoves.contains(move), displayedPosition.legalMoves().contains(move) else { return }
        receive(move.uci, source: "board")
    }

    func cancelPromotion() { clearBoardSelection(); listenIfReady() }
    private func clearBoardSelection() { selectedSquare = nil; promotionMoves = [] }

    func undo(source: String = "ui") {
        guard game.records.contains(where: { $0.side == human }) else {
            trace("action.undo_unavailable", ["source": source])
            if source == "voice" || source == "text" { showInputError(L("Пока нечего отменять.")) }
            return
        }
        let previousPly = game.records.count
        trace("action.undo", ["source": source])
        cancelWork()
        game.undoTurn(human: human)
        snapshot("game.after_undo")
        inputFeedback = nil
        persist()
        message = L("Ход отменён. {0} ходят.", String(describing: human.label))
        commandFeedback = L("Ход отменён")
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        trace("action.undo_completed", ["source": source, "removed_plies": String(previousPly - game.records.count)])
        if source == "voice" && !showBoard { announce(L("Ход отменён")) }
        if game.position.turn != human { resume() }
    }

    func newGame(difficulty: Difficulty, human: Side) {
        persist()
        cancelWork()
        archiveID = UUID(); gameStartedAt = Date()
        self.difficulty = difficulty; self.human = human
        engineError = nil
        game = ChessGame(); peeks = 0; inputFeedback = nil
        message = human == .white ? L("Представьте доску. Первый ход — ваш.") : L("Вы играете чёрными. Компьютер начинает.")
        snapshot("game.new")
        persist(); resume()
    }

    private func cancelWork() {
        commandFeedback = nil
        reviewPly = nil
        clearBoardSelection()
        sessionID = UUID(); engineTask?.cancel(); engineTask = nil; thinking = false; pauseVoice()
    }

    func trace(_ event: String, _ fields: [String: String] = [:]) {
        var context = fields
        context["game_id"] = sessionID.uuidString
        context["ply"] = String(game.records.count)
        context["turn"] = game.position.turn.rawValue
        context["displayed_ply"] = String(displayedPly)
        context["displayed_turn"] = displayedPosition.turn.rawValue
        context["human"] = human.rawValue
        context["difficulty"] = difficulty.rawValue
        context["status"] = status
        DiagnosticLog.shared.record(event, context)
    }

    private func snapshot(_ event: String) {
        let data = try? JSONEncoder().encode(game.position)
        trace(event, ["position": data.flatMap { String(data: $0, encoding: .utf8) } ?? "",
                      "history": game.records.map(\.san).joined(separator: " ")])
    }

    func setArchiveOpen(_ open: Bool) {
        browsingArchive = open
        if open { pauseVoice(); persist() }
        trace("ui.archive", ["open": String(open)])
    }
    func deleteArchivedGame(_ id: UUID) {
        guard let archiveStore else { return }
        do {
            try archiveStore.delete(id)
            archivedGames = archiveStore.entries
            trace("archive.deleted", ["archive_id": id.uuidString])
        } catch { archiveError = L("Не удалось сохранить изменения архива. Попробуйте снова.") }
    }
    func clearArchive() {
        guard let archiveStore else { return }
        do {
            try archiveStore.clear(currentID: archiveID)
            archivedGames = archiveStore.entries
            trace("archive.cleared")
        } catch { archiveError = L("Не удалось сохранить изменения архива. Попробуйте снова.") }
    }

    private func persist() {
        let value = SavedGame(game: game, difficulty: difficulty, human: human, peeks: peeks, archiveID: archiveID, startedAt: gameStartedAt)
        if let data = try? JSONEncoder().encode(value) { UserDefaults.standard.set(data, forKey: saveKey) }
        guard let archiveStore else { return }
        do {
            try archiveStore.upsert(ArchivedGame(id: archiveID, startedAt: gameStartedAt, updatedAt: Date(), game: game, human: human, difficulty: difficulty))
            archivedGames = archiveStore.entries
        } catch { archiveError = L("Не удалось сохранить изменения архива. Попробуйте снова.") }
    }
}


/// Bundled, original wood impacts. System sounds respect the phone's silent switch
/// and do not reconfigure the shared recording/speech audio session.
private final class BoardMoveSounds {
    private var sounds: [String: SystemSoundID] = [:]
    func play(san: String) {
        // One sound per move: mate and check take precedence even on a capture.
        let name = san.hasSuffix("#") ? "mate" : san.hasSuffix("+") ? "check" : san.contains("x") ? "capture" : "move"
        if sounds[name] == nil {
            guard let url = Bundle.main.url(forResource: name, withExtension: "wav", subdirectory: "Sounds") else { return }
            var sound: SystemSoundID = 0
            guard AudioServicesCreateSystemSoundID(url as CFURL, &sound) == kAudioServicesNoError else { return }
            sounds[name] = sound
        }
        if let sound = sounds[name] { AudioServicesPlaySystemSound(sound) }
    }
    deinit {
        for sound in sounds.values { AudioServicesDisposeSystemSoundID(sound) }
    }
}
