import Foundation

/// End a short spoken turn after sustained sound followed by a pause.
/// This energy gate does not claim to identify human speech in arbitrary noise;
/// Transcript annotation filtering and the chess parser provide subsequent checks.
struct VoiceTurnGate {
    enum Decision: Equatable { case listening, finish, noSpeech }
    private var previousTime: TimeInterval = 0
    private var activeDuration: TimeInterval = 0
    private var lastActive: TimeInterval = 0
    private var heardSpeech = false

    static func speechText(_ text: String) -> String {
        text.replacingOccurrences(of: "\\[[^\\]]*\\]", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    mutating func update(power: Float, time: TimeInterval) -> Decision {
        let delta = min(0.25, max(0, time - previousTime))
        previousTime = time
        // Ignore microphone activation transients; audio itself is still retained.
        if time <= 0.3 { return .listening }
        if power > -45 {
            activeDuration += delta
            lastActive = time
            if activeDuration >= 0.18 { heardSpeech = true }
        } else if !heardSpeech {
            activeDuration = 0
        }
        if heardSpeech && time - lastActive >= 0.9 { return .finish }
        if time >= 12 { return heardSpeech ? .finish : .noSpeech }
        if !heardSpeech && time >= 10 { return .noSpeech }
        return .listening
    }
}

/// Energy is a retry signal, not proof that the recording contains speech.
enum SpeechRetryPolicy {
    static func shouldRetry(text: String, audibleSeconds: Double, audioSeconds: Double) -> Bool {
        text.isEmpty && audibleSeconds >= 0.25 && audioSeconds >= 0.5 && audioSeconds <= 12
    }
    static func canOfferForConfirmation(text: String, averageLogProbability: Float?, compressionRatio: Float?) -> Bool {
        guard !text.isEmpty, text.count <= 80,
              let probability = averageLogProbability, probability.isFinite, probability >= -4.2,
              let ratio = compressionRatio, ratio.isFinite, ratio <= 2.4 else { return false }
        return true
    }
    static func canCheckChessContext(text: String, averageLogProbability: Float?, compressionRatio: Float?) -> Bool {
        guard !text.isEmpty, text.count <= 80, let probability = averageLogProbability,
              probability.isFinite, probability >= -8,
              let ratio = compressionRatio, ratio.isFinite, ratio <= 2.4 else { return false }
        return true
    }
    static func accepts(text: String, averageLogProbability: Float?, compressionRatio: Float?) -> Bool {
        guard !text.isEmpty, let probability = averageLogProbability, let ratio = compressionRatio else { return false }
        return probability.isFinite && ratio.isFinite && probability >= -1 && ratio <= 2.4
    }
}
