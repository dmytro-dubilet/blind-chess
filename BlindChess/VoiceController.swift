import AVFoundation
import SwiftUI
import WhisperKit
import CoreML

@MainActor
final class VoiceController: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    @Published private(set) var listening = false
    @Published private(set) var speaking = false
    @Published private(set) var decoding = false
    @Published private(set) var preparing = false
    @Published private(set) var preparationSlow = false
    @Published private(set) var ready = false
    @Published private var preparationLabelKey = ""
    var preparationLabel: String { L(preparationLabelKey) }
    @Published private(set) var preparationProgress: Double = 0
    @Published private var preparationStage: Int? = nil
    var preparationStageLabel: String {
        guard let stage = preparationStage else { return L("Проверяем модель…") }
        let keys = ["Подготовка звука", "Загрузка распознавания", "Подготовка обработки голоса", "Подготовка словаря"]
        return L("Этап {0} из 4 · {1}", String(stage + 1), L(keys[stage]))
    }
    @Published private(set) var downloadProgress: Double?
    @Published private(set) var transcript = ""
    @Published private(set) var inputLevel: Double = 0
    @Published private(set) var error: String?
    var onPhrase: ((String) -> Void)?
    var onUncertainPhrase: ((String) -> Void)?
    var onWeakPhrase: ((String) -> Bool)?
    var onSpeechFinished: (() -> Void)?
    var onFailure: (() -> Void)?
    var onRecognitionFailure: ((String) -> Void)?

    private static let modelName = "openai_whisper-small_216MB"
    private static let modelPathKey = "blindchess.whisper.small216.path.v1"
    private var whisper: WhisperKit?
    private var recorder: AVAudioRecorder?
    private var recordingURL: URL?
    private var warmRecorder: AVAudioRecorder?
    private var warmURL: URL?
    private var audibleSeconds: Double = 0
    private var audioSessionReady = false
    private let synthesizer = AVSpeechSynthesizer()
    private var currentUtterance: ObjectIdentifier?
    private var meterTask: Task<Void, Never>?
    private var decodeTask: Task<Void, Never>?
    private var decodeBarrier: Task<Void, Never>?
    private var generation = UUID()
    private var preparationID = UUID()
    private var preparationTask: Task<Bool, Never>?
    private var preparationTaskID = UUID()
    private var speechStarted = ProcessInfo.processInfo.systemUptime
    private var speechID = UUID().uuidString

    private func trace(_ event: String, _ fields: [String: String] = [:]) {
        var values = fields
        values["capture_id"] = generation.uuidString
        if event.hasPrefix("model.") { values["prepare_id"] = preparationID.uuidString }
        DiagnosticLog.shared.record(event, values)
    }

    override init() {
        super.init()
        synthesizer.delegate = self
        // Remove only abandoned transient recordings from this app's dedicated folder.
        if let files = try? FileManager.default.contentsOfDirectory(at: audioDirectory, includingPropertiesForKeys: nil) {
            for file in files where file.pathExtension == "wav" { try? FileManager.default.removeItem(at: file) }
        }
    }

    private var audioDirectory: URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("BlindChessVoice", isDirectory: true)
    }

    func authorize() async -> Bool {
        error = nil
        let microphone: Bool
        switch AVAudioApplication.shared.recordPermission {
        case .granted: microphone = true
        case .denied: microphone = false
        default:
            trace("microphone.permission_requested")
            microphone = await withCheckedContinuation { continuation in
                AVAudioApplication.requestRecordPermission { continuation.resume(returning: $0) }
            }
        }
        guard !Task.isCancelled else { return false }
        trace("microphone.permission", ["allowed": String(microphone)])
        guard microphone else {
            error = L("Разрешите доступ к микрофону в Настройках iPhone → Приложения → Blind Chess.")
            return false
        }
        return await prepareModel()
    }

    func preloadCachedModel() {
        guard whisper == nil,
              UserDefaults.standard.string(forKey: Self.modelPathKey) != nil else { return }
        trace("model.preload_requested")
        Task { [weak self] in _ = await self?.prepareModel() }
    }

    private func prepareModel() async -> Bool {
        if whisper != nil { trace("model.reused"); return true }
        if let preparationTask {
            trace("model.prepare_joined")
            let joinedID = preparationTaskID
            let result = await preparationTask.value
            if preparationTask.isCancelled {
                if preparationTaskID == joinedID { self.preparationTask = nil }
                guard !Task.isCancelled else { return false }
                return await prepareModel()
            }
            return result
        }
        let taskID = UUID()
        preparationTaskID = taskID
        let task = Task { [weak self] in await self?.loadModel() ?? false }
        preparationTask = task
        let result = await task.value
        if preparationTaskID == taskID { preparationTask = nil }
        return result
    }

    private func loadModel() async -> Bool {
        if whisper != nil { trace("model.reused"); return true }
        let started = ProcessInfo.processInfo.systemUptime
        let token = UUID()
        preparationID = token
        trace("model.prepare_start", ["model": Self.modelName])
        preparing = true
        preparationProgress = 0
        preparationStage = nil
        preparationSlow = false
        let watchdog = Task { [weak self] in
            try? await Task.sleep(for: .seconds(30))
            guard !Task.isCancelled, let self, self.preparationID == token else { return }
            self.preparationSlow = true
            self.trace("model.prepare_slow", ["elapsed_ms": diagnosticMS(since: started)])
        }
        preparationLabelKey = "Готовим распознавание голоса…"
        downloadProgress = nil
        defer {
            watchdog.cancel()
            if preparationID == token { preparing = false; preparationSlow = false; downloadProgress = nil }
        }
        do {
            var root = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask,
                                                   appropriateFor: nil, create: true)
                .appendingPathComponent("WhisperModels", isDirectory: true)
            try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
            var resourceValues = URLResourceValues()
            resourceValues.isExcludedFromBackup = true
            try root.setResourceValues(resourceValues)

            let cached = UserDefaults.standard.string(forKey: Self.modelPathKey).map { root.appendingPathComponent($0) }
            let folder: URL
            if let cached, ["AudioEncoder.mlmodelc", "MelSpectrogram.mlmodelc", "TextDecoder.mlmodelc"].allSatisfy({
                FileManager.default.fileExists(atPath: cached.appendingPathComponent($0).path)
            }) {
                trace("model.cache_found")
                folder = cached
            } else {
                trace("model.download_start")
                preparationLabelKey = "Загрузка голосовой модели"
                downloadProgress = 0
                folder = try await WhisperKit.download(variant: Self.modelName, downloadBase: root) { [weak self] progress in
                    let fraction = progress.fractionCompleted
                    Task { @MainActor [weak self] in
                        guard let self, self.preparationID == token, self.preparing else { return }
                        self.downloadProgress = fraction
                    }
                }
            }
            trace("model.files_ready", ["duration_ms": diagnosticMS(since: started)])
            try Task.checkCancellation()
            guard preparationID == token else { return false }
            downloadProgress = nil
            preparationLabelKey = "Готовим распознавание голоса…"
            // Explicit local folders bypass model discovery/network calls on subsequent launches.
            let config = WhisperKitConfig(modelFolder: folder.path, tokenizerFolder: root,
                                          verbose: false, prewarm: false, load: false, download: false)
            let pipeline = try await WhisperKit(config)
            try Task.checkCancellation()
            preparationStage = 0
            // Each model property is protected by WhisperKit's @Protected lock.
            // Observe actual completed loads without replacing the library's loading logic.
            let stageMonitor = Task { @MainActor [weak self] in
                var previousStage = -1
                while !Task.isCancelled {
                    guard let self, self.preparationID == token else { return }
                    let featureReady = (pipeline.featureExtractor as? WhisperMLModel)?.model != nil
                    let decoderReady = (pipeline.textDecoder as? WhisperMLModel)?.model != nil
                    let encoderReady = (pipeline.audioEncoder as? WhisperMLModel)?.model != nil
                    let stage = encoderReady ? 3 : (decoderReady ? 2 : (featureReady ? 1 : 0))
                    if stage != previousStage {
                        self.preparationProgress = Double(stage) / 4
                        self.preparationStage = stage
                        self.trace("model.prepare_stage", ["stage": String(stage + 1), "completed_fraction": String(self.preparationProgress), "elapsed_ms": diagnosticMS(since: started)])
                        previousStage = stage
                    }
                    try? await Task.sleep(for: .milliseconds(80))
                }
            }
            defer { stageMonitor.cancel() }
            try await pipeline.loadModels()
            stageMonitor.cancel()
            try Task.checkCancellation()
            guard preparationID == token else { return false }
            trace("model.ready", ["duration_ms": diagnosticMS(since: started), "tokenizer_ms": String(pipeline.currentTimings.tokenizerLoadTime * 1000),
                "encoder_ms": String(pipeline.currentTimings.encoderLoadTime * 1000),
                "decoder_ms": String(pipeline.currentTimings.decoderLoadTime * 1000),
                "model_loading_ms": String(pipeline.currentTimings.modelLoading * 1000),
                "encoder_specialization_ms": String(pipeline.currentTimings.encoderSpecializationTime * 1000),
                "decoder_specialization_ms": String(pipeline.currentTimings.decoderSpecializationTime * 1000)])
            preparationProgress = 1
            whisper = pipeline
            ready = true
            let relative = String(folder.path.dropFirst(root.path.count + 1))
            UserDefaults.standard.set(relative, forKey: Self.modelPathKey)
            return true
        } catch {
            trace("model.prepare_failed", ["cancelled": String(Task.isCancelled), "error": error.localizedDescription, "duration_ms": diagnosticMS(since: started)])
            guard !Task.isCancelled, preparationID == token else { return false }
            self.error = L("Не удалось подготовить Whisper. Для первой загрузки нужно около 220 МБ, свободное место и интернет. Попробуйте снова.\n{0}", String(describing: error.localizedDescription))
            return false
        }
    }

    func listen() {
        stopListening()
        error = nil; transcript = ""; audibleSeconds = 0
        guard whisper != nil else {
            fail(L("Whisper ещё не готов. Нажмите микрофон, чтобы загрузить модель."))
            return
        }
        do {
            try configureAudio()
            try prepareRecorder()
            guard let recorder = warmRecorder, let url = warmURL else { return }
            warmRecorder = nil; warmURL = nil
            self.recorder = recorder; recordingURL = url
            let started = ProcessInfo.processInfo.systemUptime
            guard recorder.record() else {
                fail(L("Не удалось включить микрофон. Проверьте аудиоустройство."))
                return
            }
            trace("audio.record_started", ["duration_ms": diagnosticMS(since: started)])
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            listening = true
            let session = AVAudioSession.sharedInstance()
            trace("capture.start", ["sample_rate": String(session.sampleRate),
                "input": session.currentRoute.inputs.map { $0.portType.rawValue }.joined(separator: ","),
                "output": session.currentRoute.outputs.map { $0.portType.rawValue }.joined(separator: ",")])
            let token = generation
            meterTask = Task { [weak self] in
                var lastMeterSecond = -1
                var speechDetected = false
                var previousMeterTime: TimeInterval = 0
                while !Task.isCancelled {
                    try? await Task.sleep(for: .milliseconds(100))
                    guard !Task.isCancelled, let self, self.generation == token, let recorder = self.recorder else { return }
                    guard recorder.isRecording else { self.fail(L("Запись прервалась. Включите микрофон ещё раз.")); return }
                    recorder.updateMeters()
                    let power = recorder.averagePower(forChannel: 0)
                    let time = recorder.currentTime
                    if time > 0.3 && power > -45 {
                        self.audibleSeconds += min(0.15, max(0, time - previousMeterTime))
                    }
                    previousMeterTime = time
                    self.inputLevel = min(1, max(0, Double(power + 55) / 35))
                    if recorder.currentTime > 0.3 && power > -45 && !speechDetected {
                        speechDetected = true
                        self.trace("capture.sound_detected", ["audio_seconds": String(recorder.currentTime)])
                    }
                    let second = Int(recorder.currentTime)
                    if second != lastMeterSecond {
                        lastMeterSecond = second
                        self.trace("capture.level", ["audio_seconds": String(recorder.currentTime), "average_db": String(power)])
                    }
                    // In push-to-talk mode only releasing the button submits audio.
                    if recorder.currentTime >= 60 {
                        self.fail(L("Запись слишком длинная. Отпустите кнопку и назовите ход ещё раз."))
                        return
                    }
                }
            }
        } catch { fail(L("Не удалось включить микрофон: {0}", String(describing: error.localizedDescription))) }
    }

    func finishHeldRecording() {
        guard listening else { return }
        guard let recorder, recorder.currentTime >= 0.35 else {
            trace("capture.too_short")
            stopListening()
            return
        }
        finishRecording()
    }

    private func finishRecording() {
        guard let url = recordingURL, let whisper else { return }
        let audioSeconds = recorder?.currentTime ?? 0
        let soundSeconds = audibleSeconds
        trace("capture.finish", ["audio_seconds": String(audioSeconds), "audible_seconds": String(soundSeconds)])
        meterTask?.cancel(); meterTask = nil
        recorder?.stop(); recorder = nil
        recordingURL = nil
        listening = false; inputLevel = 0; decoding = true
        let token = generation
        // Most short moves need no text prompt. Prefilling a long vocabulary was
        // more expensive than decoding the move itself, especially on CPU.
        let language = AppLanguage.current
        let options = DecodingOptions(task: .transcribe, language: language.rawValue, temperature: 0,
                                      temperatureFallbackCount: 0, sampleLength: 96,
                                      usePrefillPrompt: true, detectLanguage: false,
                                      skipSpecialTokens: true, withoutTimestamps: true,
                                      suppressBlank: true,
                                      concurrentWorkerCount: 1)
        let decodeStarted = ProcessInfo.processInfo.systemUptime
        trace("decode.queued")
        let previousDecode = decodeBarrier
        let task = Task { [weak self] in
            defer { try? FileManager.default.removeItem(at: url) }
            do {
                await previousDecode?.value
                try Task.checkCancellation()
                let passStarted = ProcessInfo.processInfo.systemUptime
                DiagnosticLog.shared.record("decode.start", ["language": language.rawValue, "capture_id": token.uuidString, "queue_ms": diagnosticMS(since: decodeStarted)])
                let results = try await whisper.transcribe(audioPath: url.path, decodeOptions: options)
                try Task.checkCancellation()
                guard let self, self.generation == token else { return }
                let rawText = results.map(\.text).joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
                var text = VoiceTurnGate.speechText(rawText)
                self.trace("decode.first_result", ["text": rawText, "duration_ms": diagnosticMS(since: passStarted)])
                self.logConfidence(results, pass: "first")
                if SpeechRetryPolicy.shouldRetry(text: text, audibleSeconds: soundSeconds, audioSeconds: audioSeconds) {
                    let retryStarted = ProcessInfo.processInfo.systemUptime
                    self.trace("decode.retry_start", ["reason": "empty_with_sound", "audible_seconds": String(soundSeconds)])
                    var retryOptions = options
                    retryOptions.temperature = 0.2
                    // Exactly one alternate decode, without a prompt that could invent a move.
                    let retryResults = try await whisper.transcribe(audioPath: url.path, decodeOptions: retryOptions)
                    try Task.checkCancellation()
                    guard self.generation == token else { return }
                    let rawRetry = retryResults.map(\.text).joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
                    let retryText = VoiceTurnGate.speechText(rawRetry)
                    let segments = retryResults.flatMap(\.segments)
                    let confidence = segments.map(\.avgLogprob).min()
                    let ratio = segments.map(\.compressionRatio).max()
                    let accepted = SpeechRetryPolicy.accepts(text: retryText, averageLogProbability: confidence, compressionRatio: ratio)
                    self.logConfidence(retryResults, pass: "retry")
                    self.trace("decode.retry_result", ["text": rawRetry, "accepted": String(accepted), "duration_ms": diagnosticMS(since: retryStarted)])
                    if accepted { text = retryText }
                    else if SpeechRetryPolicy.canOfferForConfirmation(text: retryText, averageLogProbability: confidence, compressionRatio: ratio) {
                        self.trace("decode.uncertain_result", ["text": retryText, "reason": "low_confidence"])
                        self.trace("decode.finish", ["text": retryText, "uncertain": "true", "duration_ms": diagnosticMS(since: decodeStarted)])
                        self.decoding = false; self.decodeTask = nil
                        self.transcript = retryText
                        self.prepareCaptureSession()
                        self.onUncertainPhrase?(retryText)
                        return
                    }
                    else if SpeechRetryPolicy.canCheckChessContext(text: retryText, averageLogProbability: confidence, compressionRatio: ratio) {
                        self.trace("decode.weak_context_check", ["text": retryText])
                        if self.onWeakPhrase?(retryText) == true {
                            self.trace("decode.finish", ["text": retryText, "uncertain": "true", "context_only": "true", "duration_ms": diagnosticMS(since: decodeStarted)])
                            self.decoding = false; self.decodeTask = nil
                            self.transcript = retryText
                            self.prepareCaptureSession()
                            return
                        }
                    }
                }
                self.trace("decode.finish", ["text": text, "duration_ms": diagnosticMS(since: decodeStarted)])
                self.decoding = false; self.decodeTask = nil
                self.prepareCaptureSession()
                guard !text.isEmpty else {
                    self.trace("decode.no_speech")
                    self.onRecognitionFailure?(L("Не удалось расслышать ход. Зажмите микрофон и попробуйте ещё раз."))
                    return
                }
                self.transcript = text
                self.onPhrase?(text)
            } catch {
                DiagnosticLog.shared.record(Task.isCancelled ? "decode.cancelled" : "decode.failed", ["capture_id": token.uuidString, "cancelled": String(Task.isCancelled), "error": error.localizedDescription, "duration_ms": diagnosticMS(since: decodeStarted)])
                guard !Task.isCancelled, let self, self.generation == token else { return }
                self.stopListening()
                self.onRecognitionFailure?(L("Не удалось распознать ход. Попробуйте произнести его ещё раз."))
            }
        }
        decodeTask = task
        decodeBarrier = task
    }

    private func logConfidence(_ results: [TranscriptionResult], pass: String) {
        let segments = results.flatMap(\.segments)
        trace("decode.confidence", ["pass": pass, "segments": String(segments.count),
            "min_avg_log_probability": segments.map(\.avgLogprob).min().map(String.init(describing:)) ?? "unavailable",
            "max_compression_ratio": segments.map(\.compressionRatio).max().map(String.init(describing:)) ?? "unavailable",
            // WhisperKit 1.1 currently returns a placeholder zero for noSpeechProb.
            "no_speech_probability_supported": "false"])
    }

    private func fail(_ message: String) {
        trace("voice.error", ["message": message])
        stopListening(); error = message; onFailure?()
    }

    func stopListening() {
        if listening || decoding { trace("capture.cancel", ["listening": String(listening), "decoding": String(decoding)]) }
        generation = UUID()
        meterTask?.cancel(); meterTask = nil
        decodeTask?.cancel(); decodeTask = nil
        recorder?.stop(); recorder = nil
        if let url = recordingURL { try? FileManager.default.removeItem(at: url) }
        recordingURL = nil; listening = false; inputLevel = 0; decoding = false
    }

    func prepareCaptureSession() {
        guard AVAudioApplication.shared.recordPermission == .granted else { return }
        let started = ProcessInfo.processInfo.systemUptime
        do {
            try configureAudio()
            let session = AVAudioSession.sharedInstance()
            if !listening && !speaking {
                if let bluetooth = session.availableInputs?.first(where: { $0.portType == .bluetoothHFP }),
                   session.preferredInput?.uid != bluetooth.uid {
                    try session.setPreferredInput(bluetooth)
                    trace("audio.bluetooth_preselected")
                }
                try prepareRecorder()
            }
            trace("audio.prepared", ["duration_ms": diagnosticMS(since: started)])
        } catch {
            trace("audio.preparation_failed", ["error": error.localizedDescription])
        }
    }

    // Allocates the file and audio resources without recording any sound.
    private func prepareRecorder() throws {
        guard warmRecorder == nil else { return }
        let started = ProcessInfo.processInfo.systemUptime
        try FileManager.default.createDirectory(at: audioDirectory, withIntermediateDirectories: true)
        let url = audioDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("wav")
        do {
            let prepared = try AVAudioRecorder(url: url, settings: [
                AVFormatIDKey: kAudioFormatLinearPCM, AVSampleRateKey: 16000,
                AVNumberOfChannelsKey: 1, AVLinearPCMBitDepthKey: 16,
                AVLinearPCMIsFloatKey: false, AVLinearPCMIsBigEndianKey: false])
            prepared.isMeteringEnabled = true
            guard prepared.prepareToRecord() else { throw CocoaError(.fileWriteUnknown) }
            warmRecorder = prepared; warmURL = url
            trace("audio.recorder_prepared", ["duration_ms": diagnosticMS(since: started)])
        } catch {
            try? FileManager.default.removeItem(at: url)
            throw error
        }
    }

    private func discardWarmRecorder() {
        warmRecorder?.stop(); warmRecorder = nil
        if let warmURL { try? FileManager.default.removeItem(at: warmURL) }
        warmURL = nil
    }

    func retryPreparation() {
        trace("model.retry_requested")
        preparationTask?.cancel()
        Task { [weak self] in _ = await self?.prepareModel() }
    }

    func audioRouteChanged() {
        discardWarmRecorder()
        guard audioSessionReady, !listening, !speaking else { return }
        prepareCaptureSession()
    }

    private func configureAudio() throws {
        guard !audioSessionReady else { return }
        let session = AVAudioSession.sharedInstance()
        let options: AVAudioSession.CategoryOptions = [.defaultToSpeaker, .allowBluetoothHFP]
        if session.category != .playAndRecord || session.mode != .default || session.categoryOptions != options {
            try session.setCategory(.playAndRecord, mode: .default, options: options)
        }
        try session.setActive(true)
        try session.setAllowHapticsAndSystemSoundsDuringRecording(true)
        audioSessionReady = true
    }

    func clearError() { error = nil }

    func speak(_ text: String) {
        stopListening()
        if speaking { trace("speech.cancel", ["speech_id": speechID, "duration_ms": diagnosticMS(since: speechStarted)]) }
        currentUtterance = nil
        synthesizer.stopSpeaking(at: .immediate)
        do { try configureAudio() }
        catch { fail(L("Не удалось включить звук: {0}", String(describing: error.localizedDescription))); return }
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: AppLanguage.current.speechLocale)
        utterance.rate = 0.44
        currentUtterance = ObjectIdentifier(utterance)
        speechID = UUID().uuidString
        speechStarted = ProcessInfo.processInfo.systemUptime
        trace("speech.start", ["speech_id": speechID, "text": text, "language": AppLanguage.current.rawValue])
        speaking = true
        synthesizer.speak(utterance)
    }

    func stopAll(deactivateAudio: Bool = false) {
        stopListening()
        if speaking { trace("speech.cancel", ["speech_id": speechID, "duration_ms": diagnosticMS(since: speechStarted)]) }
        currentUtterance = nil
        synthesizer.stopSpeaking(at: .immediate)
        speaking = false
        if deactivateAudio {
            preparationTask?.cancel()
            discardWarmRecorder()
            audioSessionReady = false
            try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        let identity = ObjectIdentifier(utterance)
        Task { @MainActor [weak self] in
            // Let the speaker output settle before opening the microphone again.
            try? await Task.sleep(for: .milliseconds(250))
            guard let self, self.currentUtterance == identity else { return }
            self.trace("speech.finish", ["speech_id": self.speechID, "duration_ms": diagnosticMS(since: self.speechStarted)])
            self.currentUtterance = nil
            self.speaking = false
            self.prepareCaptureSession()
            self.onSpeechFinished?()
        }
    }
}
