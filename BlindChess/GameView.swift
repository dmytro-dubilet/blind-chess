import SwiftUI

private enum Palette {
    static let paper = Color(red: 0.105, green: 0.11, blue: 0.12)
    static let ink = Color(red: 0.94, green: 0.94, blue: 0.93)
    static let muted = Color(red: 0.61, green: 0.63, blue: 0.64)
    static let accent = Color(red: 0.55, green: 0.69, blue: 0.44)
    static let surface = Color(red: 0.17, green: 0.18, blue: 0.19)
    static let darkSquare = Color(red: 115/255, green: 149/255, blue: 82/255)
    static let lightSquare = Color(red: 235/255, green: 236/255, blue: 208/255)
}

struct GameView: View {
    @ObservedObject var model: GameModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .body) private var microphoneCaptionHeight: CGFloat = 76
    @State private var showSettings = false
    @State private var showArchive = false
    @State private var showSetup = false
    @State private var showHelp = false
    @State private var showText = false
    @State private var showEngineError = false
    @State private var showVoiceError = false
    @State private var logExport: LogExport?
    @State private var exportingLog = false
    @State private var logError: String?
    @State private var showLogError = false
    @State private var showShakeUndo = false
    @Environment(\.scenePhase) private var scenePhase

    private var shakeUndoEnabled: Bool {
        scenePhase == .active && !model.game.records.isEmpty
            && !showArchive && !showSettings && !showSetup && !showHelp && !showText && logExport == nil
            && !showEngineError && !showVoiceError && !showLogError && !showShakeUndo
    }

    private var mainScreen: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Menu {
                    Button(L("Новая партия"), systemImage: "plus") { model.pauseVoice(); showSetup = true }
                    Button(L("Архив партий"), systemImage: "clock.arrow.circlepath") { model.setArchiveOpen(true); showArchive = true }
                    Divider()
                    Button(L("Выбрать язык"), systemImage: "globe") { model.pauseVoice(); showSettings = true }
                    Button("Tips", systemImage: "questionmark.circle") { model.pauseVoice(); showHelp = true }
                } label: {
                    Image(systemName: "ellipsis").font(.system(size: 23, weight: .medium))
                        .foregroundStyle(Palette.muted).frame(width: 48, height: 48)
                }.background(JournalExcludedArea()).accessibilityLabel(L("Меню партии"))
            }
            VStack(spacing: 24) {
                Picker(L("Вид игры"), selection: Binding(get: { model.showBoard }, set: { model.setBoardVisible($0) })) {
                    Text(L("Вслепую")).tag(false)
                    Text(L("Доска")).tag(true)
                }.pickerStyle(.segmented).background(JournalExcludedArea()).frame(maxWidth: 280)
                    .accessibilityLabel(L("Вид игры"))
                ZStack(alignment: .top) {
                    if model.showBoard {
                        BoardView(model: model)
                    } else {
                        MoveHistoryView(model: model)
                            .id(model.sessionID)
                    }
                }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .contentShape(Rectangle())
                    .simultaneousGesture(DragGesture(minimumDistance: 30).onEnded { value in
                        let x = value.translation.width, y = value.translation.height
                        guard abs(x) > 50, abs(x) > abs(y) * 1.5 else { return }
                        model.stepHistory(x < 0 ? -1 : 1)
                    })
                    .accessibilityAction(named: L("На ход назад")) { model.stepHistory(-1) }
                    .accessibilityAction(named: L("На ход вперёд")) { model.stepHistory(1) }
            }.frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.vertical, 20)
            if let feedback = model.inputFeedback {
                InputErrorBanner(text: feedback).padding(.bottom, 16)
            } else if !model.isReviewing && model.game.outcome == nil && model.game.position.inCheck(model.human) {
                Text(L("Шах")).font(.headline).padding(.bottom, 16)
            }
            if model.inputGame.outcome != nil {
                VStack(spacing: 16) {
                    HStack(spacing: 24) {
                        historyArrow(-1)
                        Color.clear.frame(width: 96, height: 96)
                            .overlay {
                                if model.game.winner == model.human {
                                    VStack(spacing: 8) {
                                        Image(systemName: "trophy.fill")
                                            .font(.system(size: 24, weight: .medium))
                                            .accessibilityHidden(true)
                                        Text(L("Вы выиграли"))
                                            .font(.headline)
                                            .multilineTextAlignment(.center)
                                            .lineLimit(2)
                                            .minimumScaleFactor(0.8)
                                    }
                                    .foregroundStyle(Palette.accent)
                                    .frame(width: 140)
                                    .accessibilityElement(children: .combine)
                                } else if model.game.winner != model.human, let outcome = model.game.outcome {
                                    Text(outcome).font(.headline)
                                        .multilineTextAlignment(.center)
                                        .frame(width: 140)
                                }
                            }
                        historyArrow(1)
                    }
                    newGamePanel
                        .frame(height: microphoneCaptionHeight, alignment: .top)
                }.padding(.bottom, 32)
            } else if model.voice.preparing {
                preparationPanel
            } else {
            VStack(spacing: 28) {
                VStack(spacing: 16) {
                    HStack(spacing: 24) {
                        historyArrow(-1)
                    Group {
                        ZStack {
                            Circle().fill(model.voice.listening ? Palette.accent : Palette.surface)
                            if model.voice.preparing {
                                Image(systemName: "mic.slash").font(.system(size: 30)).foregroundStyle(Palette.muted)
                            } else if model.authorizing {
                                ProgressView().tint(Palette.ink)
                            } else {
                                Image(systemName: "mic")
                                    .font(.system(size: 30, weight: .regular))
                                    .foregroundStyle(model.voice.listening ? Palette.paper : Palette.ink)
                            }
                        }.frame(width: 96, height: 96)
                            .overlay {
                                if model.voice.listening {
                                    Circle().stroke(Palette.accent.opacity(0.25 + model.voice.inputLevel * 0.55), lineWidth: 3)
                                        .scaleEffect(1.08 + model.voice.inputLevel * 0.12)
                                        .animation(reduceMotion ? nil : .easeOut(duration: 0.12), value: model.voice.inputLevel)
                                }
                            }
                    }
                    .overlay {
                        MicrophoneHoldControl(
                            enabled: model.canMove && !model.voice.preparing,
                            label: L("Удерживайте, чтобы говорить"),
                            hint: L("Отпустите, чтобы отправить ход. С VoiceOver: двойное касание начинает или завершает запись."),
                            value: model.isReviewing ? voiceStatus : model.status,
                            onDown: { model.beginVoiceHold() },
                            onUp: { model.endVoiceHold() },
                            onCancel: { model.cancelVoiceHold() },
                            onActivate: {
                                if model.voiceEnabled { model.endVoiceHold() }
                                else { model.beginVoiceHold() }
                            })
                    }
                    .onDisappear { model.cancelVoiceHold() }
                        historyArrow(1)
                    }
                    ZStack(alignment: .top) {
                        if model.voice.preparing {
                            Text(L("Микрофон пока выключен"))
                                .font(.subheadline).foregroundStyle(Palette.muted)
                        } else if model.authorizing {
                            Text(L("Включаю микрофон…"))
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(Palette.muted)
                        } else {
                            VStack(spacing: 6) {
                                if model.isReviewing {
                                    Button { model.returnToLive() } label: {
                                        Text(L("Просмотр: {0} из {1}", String(model.displayedPly), String(model.game.records.count)))
                                            .font(.footnote).foregroundStyle(Palette.muted)
                                    }.accessibilityLabel(L("К текущей позиции"))
                                }
                                Text(voiceStatus).font(.system(size: 17, weight: .semibold))
                                    .foregroundStyle(model.voice.listening ? Palette.accent : Palette.ink)
                                if !voiceHint.isEmpty {
                                    Text(voiceHint).font(.footnote).foregroundStyle(Palette.muted)
                                }
                            }.multilineTextAlignment(.center)
                                .accessibilityElement(children: .combine)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: microphoneCaptionHeight, alignment: .top)
                }
            }.padding(.bottom, 32)
            }
        }
        .padding(.horizontal, 24).padding(.top, 8)
        .frame(maxWidth: 560).frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette.paper.ignoresSafeArea())
        .foregroundStyle(Palette.ink).tint(Palette.ink)
    }

    private func historyArrow(_ delta: Int) -> some View {
        Button { model.stepHistory(delta) } label: {
            Image(systemName: delta < 0 ? "chevron.left" : "chevron.right")
                .font(.system(size: 21, weight: .medium))
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(JournalSafeButtonStyle())
        .disabled(delta < 0 ? model.displayedPly == 0 : !model.isReviewing)
        .accessibilityLabel(L(delta < 0 ? "На ход назад" : "На ход вперёд"))
    }

    private var preparationPanel: some View {
                VStack(spacing: 8) {
                    Text(model.voice.preparationLabel).font(.headline)
                    Text(model.voice.downloadProgress != nil
                         ? L("Скачиваем модель на телефон, чтобы распознавать голос без интернета.")
                         : L("Модель уже на телефоне. Готовим её к работе без интернета."))
                        .font(.subheadline).foregroundStyle(Palette.muted)
                        .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
                    if let progress = model.voice.downloadProgress {
                        ProgressView(value: progress).tint(Palette.accent)
                        Text(L("{0}% · около 220 МБ, один раз", String(describing: Int(progress * 100)))).font(.caption).foregroundStyle(Palette.muted)
                    } else {
                        ProgressView(value: model.voice.preparationProgress)
                            .tint(Palette.accent)
                            .accessibilityLabel(L("Готовим распознавание голоса…"))
                            .accessibilityValue(model.voice.preparationStageLabel)
                        Text(model.voice.preparationStageLabel)
                            .font(.footnote).foregroundStyle(Palette.muted)
                            .multilineTextAlignment(.center)
                    }
                    if model.voice.preparationSlow {
                        Button(L("Повторить подготовку")) { model.voice.retryPreparation() }
                            .tint(Palette.accent)
                    }
                }.padding(.horizontal, 12).padding(.bottom, 32)
    }

    private var newGamePanel: some View {
        VStack(spacing: 16) {
            Button {
                model.pauseVoice()
                showSetup = true
            } label: {
                Label(L("Новая партия"), systemImage: "plus")
                    .font(.headline).foregroundStyle(Palette.paper)
                    .frame(maxWidth: .infinity).frame(minHeight: 54)
                    .background(Palette.accent, in: RoundedRectangle(cornerRadius: 18))
            }.buttonStyle(JournalSafeButtonStyle())
            if model.isReviewing {
                Button(L("Вернуться к игре")) { model.returnToLive() }
                    .font(.subheadline).foregroundStyle(Palette.muted)
            }
        }.padding(10)
            .background(Palette.surface.opacity(0.55), in: RoundedRectangle(cornerRadius: 24))
    }

    private var diagnosticScreen: some View {
        mainScreen
        .onChange(of: model.engineError) { _, error in showEngineError = error != nil }
        .alert(L("Ошибка движка"), isPresented: $showEngineError) {
            Button(L("Повторить")) { model.retryComputerMove() }
            Button(L("Закрыть"), role: .cancel) {}
        } message: { Text(model.engineError ?? L("Попробуйте снова.")) }
        .sheet(item: $logExport) { item in
            LogShareView(url: item.url)
        }
        .alert(L("Не удалось выгрузить журнал"), isPresented: $showLogError) {
            Button(L("Закрыть"), role: .cancel) {}
        } message: { Text(logError ?? L("Попробуйте снова.")) }
    }

    var body: some View {
        diagnosticScreen
        .background {
            JournalExportGesture { window in exportLog(from: window) }
                .frame(width: 0, height: 0)
        }
        .background {
            ShakeDetector(enabled: shakeUndoEnabled) {
                guard shakeUndoEnabled else { return }
                model.trace("ui.shake_undo")
                model.pauseVoice()
                showShakeUndo = true
            }.frame(width: 0, height: 0)
        }
        .alert(L("Отменить последний ход?"), isPresented: $showShakeUndo) {
            Button(L("Не отменять"), role: .cancel) { model.trace("action.shake_undo_cancelled") }
            Button(L("Отменить ход"), role: .destructive) { model.undo() }
        } message: {
            Text(L("Вернёмся к вашему предыдущему ходу. Ответ компьютера, если он уже сделан, тоже будет отменён."))
        }
        .alert(L("Отменить последний ход?"), isPresented: Binding(
            get: { model.undoConfirmation }, set: { _ in }
        )) {
            Button(L("Отменить ход"), role: .destructive) { model.confirmVoiceUndo() }
            Button(L("Не отменять"), role: .cancel) { model.dismissUndoConfirmation() }
        } message: {
            Text(L("Похоже, вы сказали «Отмена»."))
        }
        .alert(L("Подтвердите ход"), isPresented: Binding(
            get: { model.recoveryProposal != nil },
            set: { _ in }
        )) {
            Button(L("Сделать ход")) { model.confirmRecovery() }
            Button(L("Повторить команду"), role: .cancel) { model.dismissRecovery() }
        } message: {
            Text(L("Вы имели в виду: {0}?", model.recoveryProposal?.label ?? ""))
        }
        .sheet(isPresented: $showArchive, onDismiss: { model.setArchiveOpen(false) }) {
            GameArchiveView(model: model)
        }
        .sheet(isPresented: $showSettings) { SettingsView(model: model) }
        .sheet(isPresented: $showSetup) { SetupView(model: model)
            .onAppear { model.trace("ui.setup", ["open": "true"]) }
            .onDisappear { model.trace("ui.setup", ["open": "false"]) }
        }
        .sheet(isPresented: $showHelp) { HelpView()
            .onAppear { model.trace("ui.help", ["open": "true"]) }
            .onDisappear { model.trace("ui.help", ["open": "false"]) }
        }
        .sheet(isPresented: $showText) { TextMoveView(model: model)
            .onAppear { model.trace("ui.text_input", ["open": "true"]) }
            .onDisappear { model.trace("ui.text_input", ["open": "false"]) }
        }
        .onChange(of: model.voice.error) { _, error in
            if error != nil { showVoiceError = true }
        }
        .alert(L("Голос недоступен"), isPresented: $showVoiceError) {
            Button(L("Ввести ход")) { model.pauseVoice(); showText = true }
                .disabled(!model.canMove)
            Button(L("Закрыть"), role: .cancel) {}
        } message: {
            Text(model.voice.error ?? L("Попробуйте включить микрофон ещё раз."))
        }
        .buttonStyle(JournalSafeButtonStyle())
    }

    private func exportLog(from window: UIWindow) {
        guard !exportingLog else { return }
        var presenter = window.rootViewController
        while let next = presenter?.presentedViewController { presenter = next }
        guard !(presenter is UIActivityViewController) else { return }
        model.pauseVoice()
        model.trace("log.export_requested", ["gesture": "five_taps"])
        exportingLog = true
        Task { @MainActor in
            defer { exportingLog = false }
            do {
                let url = try await DiagnosticLog.shared.export()
                var top = window.rootViewController
                while let next = top?.presentedViewController { top = next }
                guard let top, !top.isBeingDismissed else { return }
                let share = UIActivityViewController(activityItems: [url], applicationActivities: nil)
                share.popoverPresentationController?.sourceView = top.view
                share.popoverPresentationController?.sourceRect = CGRect(x: top.view.bounds.midX, y: top.view.bounds.midY, width: 1, height: 1)
                top.present(share, animated: true)
            } catch {
                var top = window.rootViewController
                while let next = top?.presentedViewController { top = next }
                let alert = UIAlertController(title: L("Не удалось выгрузить журнал"), message: error.localizedDescription, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: L("Закрыть"), style: .cancel))
                top?.present(alert, animated: true)
            }
        }
    }

    private var voiceStatus: String {
        if model.isReviewing && model.displayedPosition.turn != model.human { return L("Здесь ход компьютера") }
        if model.selectedSquare != nil { return L("Выберите клетку назначения") }
        if model.inputGame.outcome != nil { return L("Партия завершена") }
        if model.voice.listening { return L("Слушаю — назовите ход") }
        if model.voice.decoding { return L("Микрофон выключен") }
        if model.voice.speaking { return L("Компьютер отвечает") }
        if model.thinking && !model.isReviewing { return L("Компьютер думает") }
        if !model.voice.ready { return L("Нажмите, чтобы включить голос") }
        return model.commandFeedback ?? L("Зажмите и скажите ход")
    }

    private var voiceHint: String {
        if model.isReviewing {
            return model.displayedPosition.turn == model.human
                ? L("Новый ход заменит последующие")
                : L("Перейдите к позиции с вашим ходом")
        }
        if model.selectedSquare != nil { return L("Повторное нажатие фигуры — отмена") }
        if model.game.outcome != nil { return L("Новая партия — через меню") }
        if model.voice.listening { return L("Отпустите, чтобы отправить ход") }
        if model.voice.decoding { return L("Разбираю записанный ход") }
        if model.voice.speaking || model.thinking {
            return L("Дождитесь ответа")
        }
        return ""
    }

}

private struct TextMoveView: View {
    @ObservedObject var model: GameModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focused: Bool
    @State private var text = ""

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                TextField(L("e2e4 или конь f3"), text: $text)
                    .font(.title2).textInputAutocapitalization(.never).autocorrectionDisabled()
                    .focused($focused).submitLabel(.send).onSubmit(submit)
                    .padding(.vertical, 16)
                    .accessibilityLabel(L("Ваш ход"))
                if let feedback = model.inputFeedback {
                    Text(feedback).font(.callout).foregroundStyle(Palette.muted)
                }
                Spacer()
            }.padding(24).background(Palette.paper)
                .navigationTitle(L("Ввести ход")).navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button(L("Отмена")) { dismiss() } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button(L("Готово"), action: submit)
                            .disabled(!model.canMove || text.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
        }.tint(Palette.ink).presentationDetents([.medium, .large])
            .onAppear { focused = true }
    }
    private func submit() {
        guard model.canMove, !text.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let count = model.game.records.count
        model.receive(text)
        if model.game.records.count != count || model.recoveryProposal != nil || model.undoConfirmation { dismiss() }
    }
}

private struct CheckmateExplosion: View {
    let square: Int
    let perspective: Side
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var started = Date()
    @State private var finished = false

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30, paused: finished || reduceMotion)) { timeline in
            Canvas { context, size in
                let cell = size.width / 8
                let column = perspective == .white ? square % 8 : 7 - square % 8
                let row = perspective == .white ? 7 - square / 8 : square / 8
                let center = CGPoint(x: (Double(column) + 0.5) * cell, y: (Double(row) + 0.5) * cell)
                guard !reduceMotion, !finished else { return }
                let t = max(0, timeline.date.timeIntervalSince(started))
                // Match the king's footprint: narrower flames, with their base at the piece's bottom edge.
                let baseY = (Double(row) + 0.93) * cell
                context.clip(to: Path(CGRect(x: 0, y: -size.height, width: size.width, height: size.height + baseY)))
                context.translateBy(x: center.x, y: center.y + cell * 0.23)
                context.scaleBy(x: 0.60, y: 0.80)
                context.translateBy(x: -center.x, y: -center.y)
                // Dense billowing smoke behind overlapping fire volumes, rather than radial sparks.
                for i in 0..<18 {
                    let age = t - Double(i) * 0.045
                    guard age > 0 else { continue }
                    let drift = sin(Double(i) * 2.4) * cell * 0.55
                    let x = center.x + drift * min(age * 2, 1)
                    let y = center.y - cell * age * (0.45 + Double(i % 4) * 0.08)
                    let r = cell * (0.2 + min(age, 2) * 0.3)
                    let opacity = min(age * 3, 0.8) * max(0, 1 - max(t - 1.7, 0) / 2.3)
                    context.fill(Path(ellipseIn: CGRect(x: x-r, y: y-r, width: r*2, height: r*2)),
                                 with: .radialGradient(Gradient(colors: [Color(white: 0.12).opacity(opacity),
                                                                        Color(white: 0.22).opacity(opacity * 0.85), .clear]),
                                                       center: CGPoint(x: x, y: y), startRadius: r*0.2, endRadius: r))
                }
                let fuel = min(t * 12, 1) * max(0, 1 - max(t - 0.8, 0) / 1.6)
                if fuel > 0 {
                    for i in 0..<22 {
                        let phase = Double(i) * 2.399
                        let spread = min(t * 4, 1)
                        let x = center.x + cos(phase) * cell * (0.2 + Double(i % 4) * 0.13) * spread
                        let y = center.y - cell * (0.12 + Double(i % 6) * 0.18) * spread
                            + sin(t * 11 + phase) * cell * 0.09
                        let r = cell * (0.28 + Double(i % 3) * 0.09) * fuel
                        context.fill(Path(ellipseIn: CGRect(x: x-r, y: y-r*1.35, width: r*2, height: r*2.7)),
                                     with: .radialGradient(Gradient(stops: [
                                        .init(color: Color(red: 1, green: 0.94, blue: 0.58).opacity(fuel), location: 0),
                                        .init(color: Color(red: 1, green: 0.55, blue: 0.05).opacity(fuel), location: 0.35),
                                        .init(color: Color(red: 0.85, green: 0.16, blue: 0.01).opacity(fuel*0.9), location: 0.7),
                                        .init(color: .clear, location: 1)]),
                                                           center: CGPoint(x: x, y: y), startRadius: 0, endRadius: r*1.35))
                    }
                    // Flickering tapered flame tongues rise from the burning square.
                    for i in 0..<7 {
                        let x = center.x + (Double(i)-3) * cell * 0.13
                        let height = cell * (0.7 + 0.35 * sin(t*13 + Double(i)*1.7)) * fuel
                        let base = center.y + cell*0.25
                        var flame = Path()
                        flame.move(to: CGPoint(x: x-cell*0.12, y: base))
                        flame.addQuadCurve(to: CGPoint(x: x + sin(t*9+Double(i))*cell*0.16, y: base-height),
                                           control: CGPoint(x: x-cell*0.22, y: base-height*0.5))
                        flame.addQuadCurve(to: CGPoint(x: x+cell*0.12, y: base),
                                           control: CGPoint(x: x+cell*0.25, y: base-height*0.4))
                        flame.closeSubpath()
                        context.fill(flame, with: .linearGradient(Gradient(colors: [.yellow.opacity(fuel), .orange.opacity(fuel), .red.opacity(0)]),
                                                                  startPoint: CGPoint(x: x, y: base), endPoint: CGPoint(x: x, y: base-height)))
                    }
                }
                let flash = max(0, 1-t/0.22)
                let r = cell * 0.85
                context.fill(Path(ellipseIn: CGRect(x: center.x-r, y: center.y-r, width: r*2, height: r*2)),
                             with: .radialGradient(Gradient(colors: [.white.opacity(flash), .yellow.opacity(flash*0.8), .clear]),
                                                   center: center, startRadius: 0, endRadius: r))
            }
        }
        .allowsHitTesting(false).accessibilityHidden(true)
        .task {
            started = Date()
            guard !reduceMotion else { finished = true; return }
            do { try await Task.sleep(for: .seconds(4.1)) }
            catch { return }
            finished = true
        }
    }
}

private struct BurnedKing: View {
    let asset: String
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var burned = false

    var body: some View {
        ZStack {
            ZStack {
                Rectangle().fill(LinearGradient(colors: [Color(white: 0.19), Color(white: 0.08)],
                                                startPoint: .topLeading, endPoint: .bottomTrailing))
                Canvas { context, size in
                    for i in 0..<75 {
                        let x = Double((i * 43) % 101) / 100 * size.width
                        let y = Double((i * 67) % 103) / 102 * size.height
                        let r = size.width * (0.015 + Double(i % 5) * 0.013)
                        context.fill(Path(ellipseIn: CGRect(x: x-r, y: y-r, width: r*2, height: r*2)),
                                     with: .color(i % 4 == 0 ? .white.opacity(0.07) : .black.opacity(0.18)))
                    }
                }
            }.clipped().opacity(burned ? 1 : 0)
            Image(asset).resizable().scaledToFit().opacity(burned ? 0 : 1)
            ZStack {
                Ellipse().fill(Color(white: 0.65).opacity(0.15)).scaleEffect(x: 0.9, y: 0.55).blur(radius: 3)
                Image(asset).renderingMode(.template).resizable().scaledToFit()
                    .foregroundStyle(Color(white: 0.66)).opacity(0.85).blur(radius: 0.7)
                Canvas { context, size in
                    for i in 0..<110 {
                        let x = Double((i * 37) % 101) / 100 * size.width
                        let y = Double((i * 61) % 103) / 102 * size.height
                        let r = 0.4 + Double(i % 4) * 0.3
                        context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: r*2, height: r*2)),
                                     with: .color(i % 3 == 0 ? .white.opacity(0.35) : .black.opacity(0.5)))
                    }
                }.mask(Image(asset).resizable().scaledToFit())
            }.opacity(burned ? 1 : 0)
        }
        .task {
            guard !reduceMotion else { burned = true; return }
            do { try await Task.sleep(for: .seconds(0.22)) }
            catch { return }
            withAnimation(.easeOut(duration: 0.35)) { burned = true }
        }
    }
}

private struct SettingsView: View {
    @ObservedObject var model: GameModel
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                VStack(spacing: 0) {
                    ForEach(AppLanguage.allCases) { language in
                        Button { model.setLanguage(language) } label: {
                            HStack {
                                Text(language.name).foregroundStyle(Palette.ink)
                                Spacer()
                                Image(systemName: model.language == language ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(model.language == language ? Palette.accent : Palette.muted.opacity(0.4))
                            }.padding(16).contentShape(Rectangle())
                        }.buttonStyle(JournalSafeButtonStyle())
                            .accessibilityAddTraits(model.language == language ? [.isSelected] : [])
                        if language != AppLanguage.allCases.last { Divider().padding(.horizontal, 16) }
                    }
                }.background(Palette.surface, in: RoundedRectangle(cornerRadius: 18))
                Text(L("Язык интерфейса и голосовых команд"))
                    .font(.caption).foregroundStyle(Palette.muted)
            }.padding(24)
            }.background(Palette.paper)
                .navigationTitle(L("Выбрать язык")).navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button { dismiss() } label: { Image(systemName: "xmark") }
                            .accessibilityLabel(L("Закрыть"))
                    }
                }
        }.tint(Palette.ink)
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
    }
}

private struct InputErrorBanner: View {
    let text: String
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.system(size: 21)).foregroundStyle(Color.orange)
                .accessibilityHidden(true)
            Text(text).font(.callout.weight(.medium))
                .foregroundStyle(Palette.ink)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(Color.orange.opacity(0.15), in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Color.orange.opacity(0.45), lineWidth: 1))
        .accessibilityElement(children: .combine)
    }
}

private struct SetupView: View {
    @ObservedObject var model: GameModel
    @Environment(\.dismiss) private var dismiss
    @State private var level: Difficulty = .beginner
    @State private var rating: Double = 400
    @State private var human: Side = .white
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 10) {
                        sectionTitle(L("Цвет фигур"))
                        Picker(L("Цвет фигур"), selection: $human) {
                            Text(L("○  Белые")).tag(Side.white)
                            Text(L("●  Чёрные")).tag(Side.black)
                        }.pickerStyle(.segmented).background(JournalExcludedArea())
                    }
                    VStack(alignment: .leading, spacing: 10) {
                        sectionTitle(L("Уровень игры компьютера"))
                        VStack(spacing: 12) {
                            HStack {
                                Button { adjust(-100) } label: { Image(systemName: "minus").frame(width: 44, height: 44) }
                                    .disabled(rating <= 400)
                                    .accessibilityLabel(L("Уменьшить силу"))
                                Spacer()
                                VStack(spacing: 4) {
                                    Text(level.label).font(.system(size: 32, weight: .semibold, design: .rounded))
                                        .monospacedDigit().contentTransition(.numericText())
                                    Text(level.playingLevel).font(.footnote).foregroundStyle(Palette.muted)
                                        .lineLimit(1).minimumScaleFactor(0.75)
                                }.frame(maxWidth: .infinity)
                                Spacer()
                                Button { adjust(100) } label: { Image(systemName: "plus").frame(width: 44, height: 44) }
                                    .disabled(rating >= 2900)
                                    .accessibilityLabel(L("Увеличить силу"))
                            }
                            Slider(value: $rating, in: 400...2900, step: 100)
                                .tint(Palette.accent)
                                .accessibilityLabel(L("Уровень игры компьютера"))
                                .accessibilityValue(String(Int(rating)))
                                .onChange(of: rating) { _, value in level = Difficulty(rating: Int(value)) }
                            HStack { Text("400"); Spacer(); Text("2900") }
                                .font(.caption.monospacedDigit()).foregroundStyle(Palette.muted)
                        }.padding(18)
                            .background(Palette.surface, in: RoundedRectangle(cornerRadius: 18))
                    }
                }
                .padding(.horizontal, 24).padding(.top, 18).padding(.bottom, 16)
            }
            .scrollBounceBehavior(.basedOnSize)
            .background(Palette.paper)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                VStack(spacing: 10) {
                    Button(action: start) {
                        HStack(spacing: 10) {
                            Image(systemName: "play.fill").font(.system(size: 14, weight: .semibold))
                            Text(L("Начать партию")).font(.headline)
                        }
                        .foregroundStyle(Palette.paper)
                        .frame(maxWidth: .infinity).frame(minHeight: 54)
                        .background(Palette.accent, in: RoundedRectangle(cornerRadius: 18))
                    }.buttonStyle(JournalSafeButtonStyle())
                    if !model.game.records.isEmpty {
                        Text(L("Текущая партия будет заменена"))
                            .font(.caption).foregroundStyle(Palette.muted)
                    }
                }
                .padding(.horizontal, 24).padding(.top, 12).padding(.bottom, 16)
                .background(Palette.paper)
            }
            .navigationTitle(L("Новая партия")).navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark").font(.system(size: 14, weight: .semibold))
                    }.accessibilityLabel(L("Закрыть"))
                }
            }
        }.tint(Palette.ink)
            .presentationDetents([.height(500), .large])
            .presentationDragIndicator(.visible)
            .onAppear {
                human = model.human
                level = Difficulty(rating: model.difficulty == .maximum ? 2900 : model.difficulty.targetElo)
                rating = Double(level.targetElo)
            }
            .onChange(of: level) { _, value in model.trace("ui.difficulty", ["selected": value.rawValue]) }
            .onChange(of: human) { _, value in model.trace("ui.color", ["selected": value.rawValue]) }
    }
    private func adjust(_ delta: Int) { rating = min(2900, max(400, rating + Double(delta))); level = Difficulty(rating: Int(rating)) }
    private func sectionTitle(_ title: String) -> some View {
        Text(title).font(.subheadline.weight(.medium)).foregroundStyle(Palette.muted)
    }
    private func start() { model.newGame(difficulty: level, human: human); dismiss() }
}

// Historical positions keep their full colors while square buttons are disabled.
private struct BoardSquareStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.background(JournalExcludedArea())
    }
}

private struct BoardView: View {
    @ObservedObject var model: GameModel
    var body: some View {
        chessboard.aspectRatio(1, contentMode: .fit)
            .overlay {
                if let winner = model.game.winner, !model.isReviewing,
                   let king = model.game.position.board.firstIndex(where: { $0 == Piece(side: winner.opposite, kind: .king) }) {
                    CheckmateExplosion(square: king, perspective: model.human)
                }
            }
            .confirmationDialog(L("Превратить пешку в…"), isPresented: Binding(
                get: { !model.promotionMoves.isEmpty },
                set: { if !$0 { model.cancelPromotion() } }), titleVisibility: .visible) {
                ForEach(model.promotionMoves, id: \.self) { move in
                    Button(move.promotion?.localizedName.capitalized ?? L("Ферзь")) { model.choosePromotion(move) }
                }
                Button(L("Отмена"), role: .cancel) { model.cancelPromotion() }
            }
    }

    private var chessboard: some View {
        let destinations = Set(model.highlightedMoves.map(\.to))
        let canTap = model.canTapBoard
        return VStack(spacing: 0) {
            ForEach(0..<8, id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(0..<8, id: \.self) { column in
                        let rank = model.human == .white ? 7-row : row
                        let file = model.human == .white ? column : 7-column
                        let square = rank * 8 + file
                        let piece = model.displayedPosition.board[square]
                        Button { model.tapSquare(square) } label: {
                        GeometryReader { cell in
                            ZStack(alignment: .topLeading) {
                                Rectangle().fill((rank+file) % 2 == 0 ? Palette.darkSquare : Palette.lightSquare)
                                if let move = model.displayedRecords.last?.move, move.from == square || move.to == square {
                                    Rectangle().fill(Color.yellow.opacity(0.36))
                                }
                                if model.selectedSquare == square {
                                    Rectangle().fill(Color.yellow.opacity(0.55))
                                }
                                if let piece {
                                    Group {
                                        if piece.kind == .king, let winner = model.game.winner,
                                           piece.side == winner.opposite, !model.isReviewing {
                                            BurnedKing(asset: assetName(for: piece))
                                        } else {
                                            Image(assetName(for: piece)).resizable().interpolation(.high).scaledToFit()
                                        }
                                    }.frame(width: cell.size.width, height: cell.size.height)
                                        .accessibilityHidden(true)
                                }
                                if destinations.contains(square) {
                                    if piece == nil {
                                        Circle().fill(Color.black.opacity(0.23))
                                            .frame(width: cell.size.width * 0.25, height: cell.size.height * 0.25)
                                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    } else {
                                        Circle().strokeBorder(Color.black.opacity(0.28), lineWidth: 4)
                                            .padding(2)
                                    }
                                }
                                if column == 0 {
                                    Text("\(rank+1)").font(.system(size: 9, weight: .medium))
                                        .foregroundStyle((rank+file) % 2 == 0 ? Palette.lightSquare : Palette.darkSquare).padding(3)
                                }
                                if row == 7 {
                                    Text(String(Array("abcdefgh")[file])).font(.system(size: 9, weight: .medium))
                                        .foregroundStyle((rank+file) % 2 == 0 ? Palette.lightSquare : Palette.darkSquare)
                                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing).padding(3)
                                }
                            }
                        }.aspectRatio(1, contentMode: .fit)
                        }.buttonStyle(BoardSquareStyle()).disabled(!canTap)
                            .accessibilityElement(children: .ignore)
                            .accessibilityLabel("\(squareName(square)): \(piece.map { "\($0.side.label), \($0.kind.localizedName)" } ?? L("пусто"))")
                            .accessibilityValue(model.selectedSquare == square ? L("Выбрано") : (destinations.contains(square) ? L("Доступный ход") : ""))
                    }
                }
            }
        }.clipShape(RoundedRectangle(cornerRadius: 4))
    }

    private func assetName(for piece: Piece) -> String {
        let color = piece.side == .white ? "w" : "b"
        let kind = piece.kind == .pawn ? "p" : piece.kind.san.lowercased()
        return color + kind
    }
}

private struct HelpView: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            List {
                example(L("Голос"), L("Зажмите микрофон. Когда увидите «Слушаю», назовите ход, например «е два — е четыре». Отпустите кнопку, чтобы отправить запись.") + " " + L("Последняя клетка — куда идёт фигура. Можно назвать обе: «е два — е четыре»."))
                example(L("Доска"), L("Нажмите фигуру, затем клетку назначения. В этом режиме компьютер отвечает без озвучивания."))
                example(L("Просмотр партии"), L("Свайп влево — ход назад, вправо — вперёд. Ходы не отменяются. Кнопка со стрелкой возвращает к игре."))
                example(L("Отмена хода"), L("Зажмите микрофон и скажите «Отмена». Ваш ход и ответ компьютера будут отменены. Также можно встряхнуть телефон."))
            }.scrollContentBackground(.hidden).background(Palette.paper)
                .navigationTitle("Tips").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button(L("Понятно")) { dismiss() } } }
        }.tint(Palette.ink)
    }
    private func example(_ title: String, _ detail: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).fontWeight(.medium)
            Text(detail).font(.subheadline).foregroundStyle(Palette.muted)
        }.padding(.vertical, 4)
    }
}

private struct LogExport: Identifiable {
    let id = UUID()
    let url: URL
}

private struct LogShareView: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        controller.completionWithItemsHandler = { _, completed, _, error in
            DiagnosticLog.shared.record("log.share_closed", ["completed": String(completed), "error": error?.localizedDescription ?? ""])
        }
        return controller
    }
    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}

private struct MoveHistoryView: View {
    @ObservedObject var model: GameModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private var hasNextMove: Bool { model.inputGame.outcome == nil }
    private var rowCount: Int { (model.displayedRecords.count + (hasNextMove ? 1 : 0) + 1) / 2 }
    private var lastRow: Int { max(0, rowCount - 1) }

    var body: some View {
        VStack(spacing: 12) {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 4) {
                        ForEach(0..<rowCount, id: \.self) { row in
                            HStack {
                                Text("\(row + 1)").foregroundStyle(Palette.muted)
                                    .frame(width: 32, alignment: .leading)
                                moveCell(row * 2)
                                moveCell(row * 2 + 1)
                            }
                            .font(.system(size: 19, weight: .medium, design: .monospaced))
                            .padding(.horizontal, 14).padding(.vertical, 13)
                            .background(row == lastRow ? Palette.surface : .clear,
                                        in: RoundedRectangle(cornerRadius: 10))
                            .id(row)
                        }
                    }
                }.scrollIndicators(.hidden)
                    .onAppear { proxy.scrollTo(lastRow, anchor: .bottom) }
                    .onChange(of: model.displayedRecords.count) { _, _ in
                        proxy.scrollTo(lastRow, anchor: .bottom)
                    }
            }
        }
    }

    private var nextMoveIndicator: some View {
        Group {
            if model.thinking && !model.isReviewing {
                ProgressView().tint(Palette.muted)
                    .accessibilityLabel(L("Компьютер рассчитывает следующий ход"))
            } else if model.voice.decoding && model.displayedPosition.turn == model.human {
                ProgressView().tint(Palette.accent)
                    .accessibilityLabel(L("Распознаю ваш ход"))
            } else if model.voice.listening && model.displayedPosition.turn == model.human {
                Image(systemName: "mic.fill")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(Palette.accent)
                    .scaleEffect(reduceMotion ? 1 : 1 + model.voice.inputLevel * 0.16)
                    .animation(reduceMotion ? nil : .easeOut(duration: 0.12), value: model.voice.inputLevel)
                    .accessibilityLabel(L("Слушаю ваш следующий ход"))
            } else {
                Text("·").foregroundStyle(Palette.muted)
                    .accessibilityLabel(L("Следующий ход. Микрофон выключен"))
            }
        }.frame(width: 24, height: 24)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func notationLabel(_ record: MoveRecord) -> String {
        model.game.positions[record.id].spoken(record.move)
    }

    private func notationView(_ record: MoveRecord) -> some View {
        let kind = model.game.positions[record.id].board[record.move.from]?.kind ?? .pawn
        let asset = (record.side == .white ? "w" : "b") + (kind == .pawn ? "p" : kind.san.lowercased())
        return HStack(spacing: 4) {
            Image(asset).resizable().scaledToFit().frame(width: 22, height: 26)
                .background(record.side == .black ? Palette.ink.opacity(0.88) : Color.clear,
                            in: RoundedRectangle(cornerRadius: 5))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(record.notationBody).lineLimit(1).minimumScaleFactor(0.65)
                if record.isCastling {
                    Text(record.fullCoordinates).font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(Palette.muted)
                }
            }
        }.frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(notationLabel(record))
    }

    @ViewBuilder private func moveCell(_ index: Int) -> some View {
        if index < model.displayedRecords.count {
            let record = model.displayedRecords[index]
            if !model.isReviewing && record.id == model.lastComputerMove?.id {
                Button { model.repeatMove() } label: {
                    notationView(record)
                        .foregroundStyle(Palette.accent)
                }.buttonStyle(JournalSafeButtonStyle()).accessibilityLabel(L("{0}. Повторить ход компьютера", notationLabel(record)))
            } else {
                notationView(record)
            }
        } else if index == model.displayedRecords.count && hasNextMove {
            nextMoveIndicator
        } else {
            Color.clear.frame(maxWidth: .infinity).frame(height: 24).accessibilityHidden(true)
        }
    }
}


// Receive UIKit motion events without polling sensors or taking touches from the board.
private struct ShakeDetector: UIViewControllerRepresentable {
    let enabled: Bool
    let onShake: () -> Void

    func makeUIViewController(context: Context) -> ShakeViewController {
        let controller = ShakeViewController()
        controller.onShake = onShake
        controller.enabled = enabled
        return controller
    }

    func updateUIViewController(_ controller: ShakeViewController, context: Context) {
        controller.onShake = onShake
        controller.enabled = enabled
        controller.updateResponder()
    }

    static func dismantleUIViewController(_ controller: ShakeViewController, coordinator: ()) {
        controller.enabled = false
        controller.resignFirstResponder()
        controller.onShake = nil
    }
}

private final class ShakeViewController: UIViewController {
    var enabled = false
    var onShake: (() -> Void)?
    override var canBecomeFirstResponder: Bool { enabled }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateResponder()
    }

    func updateResponder() {
        if enabled && view.window != nil {
            if !isFirstResponder { becomeFirstResponder() }
        } else if isFirstResponder {
            resignFirstResponder()
        }
    }

    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake && enabled { onShake?() }
        else { super.motionEnded(motion, with: event) }
    }
}

private struct MicrophoneHoldControl: UIViewRepresentable {
    let enabled: Bool
    let label: String
    let hint: String
    let value: String
    let onDown: () -> Void
    let onUp: () -> Void
    let onCancel: () -> Void
    let onActivate: () -> Void

    func makeUIView(context: Context) -> HoldControl { HoldControl() }
    func updateUIView(_ view: HoldControl, context: Context) {
        view.isEnabled = enabled
        view.accessibilityLabel = label
        view.accessibilityHint = hint
        view.accessibilityValue = value
        view.onDown = onDown; view.onUp = onUp
        view.onCancel = onCancel; view.onActivate = onActivate
    }

    final class HoldControl: UIControl {
        var onDown: (() -> Void)?
        var onUp: (() -> Void)?
        var onCancel: (() -> Void)?
        var onActivate: (() -> Void)?
        override init(frame: CGRect) {
            super.init(frame: frame)
            isAccessibilityElement = true
            accessibilityTraits = .button
            backgroundColor = .clear
        }
        required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
        override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
            guard isEnabled else { return false }
            onDown?()
            return true
        }
        override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool { true }
        override func endTracking(_ touch: UITouch?, with event: UIEvent?) { onUp?() }
        override func cancelTracking(with event: UIEvent?) { onCancel?() }
        override func accessibilityActivate() -> Bool {
            guard isEnabled else { return false }
            onActivate?()
            return true
        }
    }
}

private struct GameArchiveView: View {
    @ObservedObject var model: GameModel
    @Environment(\.dismiss) private var dismiss
    @State private var pendingDeletion: UUID?
    @State private var confirmClear = false
    var body: some View {
        NavigationStack {
            Group {
                if model.archivedGames.isEmpty {
                    ContentUnavailableView(L("Архив пока пуст"), systemImage: "clock.arrow.circlepath",
                        description: Text(L("Начатые партии сохраняются здесь автоматически.")))
                } else {
                    List {
                        ForEach(model.archivedGames) { entry in
                            NavigationLink {
                                ArchiveReplayView(entry: entry)
                            } label: {
                                VStack(alignment: .leading, spacing: 7) {
                                    HStack {
                                        Text(entry.resultLabel).font(.headline)
                                        Spacer()
                                        Text(entry.startedAt, format: .dateTime.day().month().hour().minute())
                                            .font(.caption).foregroundStyle(Palette.muted)
                                    }
                                    Text(L("{0} · сила {1} · ходов: {2}", entry.human.label, entry.difficulty.label,
                                           String((entry.game.records.count + 1) / 2)))
                                        .font(.subheadline).foregroundStyle(Palette.muted)
                                }.padding(.vertical, 5)
                            }
                            .background(JournalExcludedArea())
                            .listRowBackground(Palette.surface)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button { pendingDeletion = entry.id } label: {
                                    Label(L("Удалить"), systemImage: "trash")
                                }.tint(.red)
                            }
                        }
                    }.scrollContentBackground(.hidden)
                }
            }
            .background(Palette.paper)
            .navigationTitle(L("Архив партий"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(L("Очистить")) { confirmClear = true }
                        .disabled(model.archivedGames.isEmpty)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: { Image(systemName: "xmark") }
                        .accessibilityLabel(L("Закрыть"))
                }
            }
            .alert(L("Удалить партию?"), isPresented: Binding(
                get: { pendingDeletion != nil }, set: { if !$0 { pendingDeletion = nil } })) {
                Button(L("Отмена"), role: .cancel) { pendingDeletion = nil }
                Button(L("Удалить"), role: .destructive) {
                    if let id = pendingDeletion { model.deleteArchivedGame(id) }
                    pendingDeletion = nil
                }
            } message: { Text(L("Запись исчезнет из архива. Текущая игра продолжится.")) }
            .alert(L("Очистить весь архив?"), isPresented: $confirmClear) {
                Button(L("Отмена"), role: .cancel) {}
                Button(L("Удалить все партии"), role: .destructive) { model.clearArchive() }
            } message: { Text(L("Все записи архива будут удалены. Текущая игра продолжится.")) }
            .alert(L("Архив партий"), isPresented: Binding(
                get: { model.archiveError != nil }, set: { if !$0 { model.archiveError = nil } })) {
                Button(L("Понятно")) { model.archiveError = nil }
            } message: { Text(model.archiveError ?? "") }
        }
        .preferredColorScheme(.dark)
        .tint(Palette.ink)
        .environment(\.locale, Locale(identifier: model.language.rawValue))
    }
}

private struct ArchiveReplayView: View {
    let entry: ArchivedGame
    @State private var ply = 0
    private var position: Position { entry.game.positions[ply] }
    private var record: MoveRecord? { ply > 0 ? entry.game.records[ply - 1] : nil }
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 6) {
                Text(entry.resultLabel).font(.headline)
                Text(entry.startedAt, format: .dateTime.day().month().year().hour().minute())
                    .font(.subheadline).foregroundStyle(Palette.muted)
            }
            Spacer(minLength: 0)
            board.aspectRatio(1, contentMode: .fit)
                .contentShape(Rectangle())
                .gesture(DragGesture(minimumDistance: 30).onEnded { value in
                    let x = value.translation.width, y = value.translation.height
                    if abs(x) > 50 && abs(x) > abs(y) * 1.5 { step(x < 0 ? -1 : 1) }
                })
                .accessibilityAction(named: L("На ход назад")) { step(-1) }
                .accessibilityAction(named: L("На ход вперёд")) { step(1) }
            VStack(spacing: 8) {
                HStack(spacing: 6) {
                    if let record, let piece = entry.game.positions[ply - 1].board[record.move.from] {
                        Text("\((ply + 1) / 2).")
                        Image(asset(piece)).resizable().scaledToFit().frame(width: 25, height: 30)
                            .background(piece.side == .black ? Palette.ink.opacity(0.88) : .clear,
                                        in: RoundedRectangle(cornerRadius: 5))
                        Text(record.notationBody)
                    } else { Text(L("Начальная позиция")) }
                }.font(.title3.monospaced()).frame(height: 32)
                Text(L("Просмотр: {0} из {1}", String(ply), String(entry.game.records.count)))
                    .font(.subheadline).foregroundStyle(Palette.muted)
            }
            Spacer(minLength: 0)
            VStack(spacing: 14) {
                Slider(value: Binding(get: { Double(ply) }, set: { ply = Int($0) }),
                       in: 0...Double(max(1, entry.game.records.count)), step: 1)
                    .tint(Palette.accent).disabled(entry.game.records.isEmpty)
                    .accessibilityLabel(L("Просмотр партии"))
                    .accessibilityValue("\(ply) / \(entry.game.records.count)")
                HStack {
                    replayButton("backward.end", L("К началу партии"), disabled: ply == 0) { ply = 0 }
                    Spacer()
                    replayButton("chevron.left", L("На ход назад"), disabled: ply == 0) { step(-1) }
                    Spacer()
                    replayButton("chevron.right", L("На ход вперёд"), disabled: ply == entry.game.records.count) { step(1) }
                    Spacer()
                    replayButton("forward.end", L("К концу партии"), disabled: ply == entry.game.records.count) { ply = entry.game.records.count }
                }
            }
        }.padding(24).background(Palette.paper)
            .navigationTitle(L("Просмотр партии")).navigationBarTitleDisplayMode(.inline)
    }
    private func step(_ delta: Int) { ply = min(entry.game.records.count, max(0, ply + delta)) }
    private func replayButton(_ icon: String, _ label: String, disabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) { Image(systemName: icon).font(.title3).frame(width: 44, height: 44) }
            .disabled(disabled).accessibilityLabel(label)
    }
    private func asset(_ piece: Piece) -> String {
        (piece.side == .white ? "w" : "b") + (piece.kind == .pawn ? "p" : piece.kind.san.lowercased())
    }
    private var board: some View {
        VStack(spacing: 0) {
            ForEach(0..<8, id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(0..<8, id: \.self) { column in
                        archiveSquare(row: row, column: column)
                    }
                }
            }
        }.clipShape(RoundedRectangle(cornerRadius: 4))
    }
    private func archiveSquare(row: Int, column: Int) -> some View {
        let rank = entry.human == .white ? 7 - row : row
        let file = entry.human == .white ? column : 7 - column
        let square = rank * 8 + file
        let piece = position.board[square]
        let pieceLabel = piece.map { $0.side.label + ", " + $0.kind.localizedName } ?? L("пусто")
        return ZStack {
            Rectangle().fill((rank + file) % 2 == 0 ? Palette.darkSquare : Palette.lightSquare)
            if let record, record.move.from == square || record.move.to == square { Color.yellow.opacity(0.36) }
            if let piece { Image(asset(piece)).resizable().scaledToFit() }
        }.aspectRatio(1, contentMode: .fit)
            .overlay(alignment: .topLeading) {
                if column == 0 { Text(String(rank + 1)).font(.system(size: 10)).foregroundStyle(Palette.paper).padding(2) }
            }
            .overlay(alignment: .bottomTrailing) {
                if row == 7 { Text(String(Array("abcdefgh")[file])).font(.system(size: 10)).foregroundStyle(Palette.paper).padding(2) }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(squareName(square) + ": " + pieceLabel)
    }
}


// Attach to the window so sheets and navigation destinations share the shortcut.
// Ordinary controls keep receiving touches immediately.
private struct JournalExportGesture: UIViewRepresentable {
    let action: (UIWindow) -> Void
    func makeUIView(context: Context) -> ObserverView {
        let view = ObserverView()
        view.action = action
        return view
    }
    func updateUIView(_ view: ObserverView, context: Context) { view.action = action }
    static func dismantleUIView(_ view: ObserverView, coordinator: ()) { view.detach() }

    final class ObserverView: UIView, UIGestureRecognizerDelegate {
        var action: ((UIWindow) -> Void)?
        private weak var observedWindow: UIWindow?
        private lazy var taps: JournalTapRecognizer = {
            let gesture = JournalTapRecognizer(target: self, action: #selector(exportJournal))
            gesture.cancelsTouchesInView = false
            gesture.delaysTouchesBegan = false
            gesture.delaysTouchesEnded = false
            gesture.delegate = self
            return gesture
        }()
        override func didMoveToWindow() {
            super.didMoveToWindow()
            guard observedWindow !== window else { return }
            detach()
            observedWindow = window
            window?.addGestureRecognizer(taps)
            if window != nil { DiagnosticLog.shared.record("log.gesture_attached") }
        }
        func detach() {
            observedWindow?.removeGestureRecognizer(taps)
            observedWindow = nil
        }
        @objc private func exportJournal() {
            guard let window = observedWindow, taps.state == .ended else { return }
            action?(window)
        }
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                               shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool { true }
    }
}

private final class JournalTapRecognizer: UIGestureRecognizer {
    private var count = 0
    private var lastTap: TimeInterval = 0
    private var began: TimeInterval = 0
    private var origin = CGPoint.zero
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        guard touches.count == 1, let touch = touches.first else { count = 0; state = .failed; return }
        if JournalExcludedArea.contains(touch) {
            count = 0
            lastTap = 0
            state = .failed
            return
        }
        began = touch.timestamp
        origin = touch.location(in: view)
    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        guard let touch = touches.first else { return }
        let point = touch.location(in: view)
        if hypot(point.x - origin.x, point.y - origin.y) > 20 { count = 0; state = .failed }
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        guard let touch = touches.first, touch.timestamp - began < 0.3 else { count = 0; state = .failed; return }
        count = touch.timestamp - lastTap <= 0.7 ? count + 1 : 1
        lastTap = touch.timestamp
        if count == 5 { count = 0; state = .recognized }
        else { state = .failed }
    }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) { count = 0; state = .cancelled }
}

// SwiftUI buttons are not always backed by UIControl. Register their actual
// label bounds so the window-level shortcut can ignore them before counting.
private struct JournalSafeButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(JournalExcludedArea())
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

private struct JournalExcludedArea: UIViewRepresentable {
    private static let regions = NSHashTable<UIView>.weakObjects()
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.isUserInteractionEnabled = false
        Self.regions.add(view)
        return view
    }
    func updateUIView(_ uiView: UIView, context: Context) {}
    static func contains(_ touch: UITouch) -> Bool {
        var ancestor = touch.view
        while let current = ancestor {
            if current is UIControl || current.accessibilityTraits.contains(.button) { return true }
            ancestor = current.superview
        }
        guard let window = touch.window else { return false }
        var top = window.rootViewController
        while let next = top?.presentedViewController { top = next }
        guard let surface = top?.view else { return false }
        let point = touch.location(in: window)
        return regions.allObjects.contains { region in
            guard region.window === window, region.isDescendant(of: surface),
                  !region.bounds.isEmpty else { return false }
            var ancestor: UIView? = region
            while let current = ancestor {
                if current.isHidden || current.alpha < 0.01 { return false }
                ancestor = current.superview
            }
            return region.convert(region.bounds, to: window).contains(point)
        }
    }
}
