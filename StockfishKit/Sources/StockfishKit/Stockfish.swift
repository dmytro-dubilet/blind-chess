import Foundation
import CStockfish

public enum StockfishError: Error { case unavailable }
private final class SearchRequest: @unchecked Sendable {
    let pointer = bc_request_create()!
    deinit { bc_request_destroy(pointer) }
    func cancel() { bc_request_cancel(pointer) }
}

public enum Stockfish {
    public static let version = "17.1"
    private static let queue = DispatchQueue(label: "blindchess.stockfish", qos: .userInitiated)
    public static let initialFEN = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
    /// Call with a validated game history. Keeps repetition history and never spawns a process.
    public static func bestMove(moves: [String], elo: Int, skill: Int = 20, milliseconds: Int,
                                fen: String = initialFEN) async throws -> String {
        let request = SearchRequest()
        return try await withTaskCancellationHandler(operation: {
            try Task.checkCancellation()
            return try await withCheckedThrowingContinuation { continuation in
                queue.async {
                    guard let directory = Bundle.module.url(forResource: "Networks", withExtension: nil) else {
                        continuation.resume(throwing: StockfishError.unavailable); return
                    }
                    var output = [CChar](repeating: 0, count: 16)
                    let status = bc_search(request.pointer, directory.path, fen, moves.joined(separator: " "),
                                           Int32(elo), Int32(skill), Int32(milliseconds), &output, Int32(output.count))
                    switch status {
                    case 0: continuation.resume(returning: String(cString: output))
                    case 1: continuation.resume(throwing: CancellationError())
                    default: continuation.resume(throwing: StockfishError.unavailable)
                    }
                }
            }
        }, onCancel: { request.cancel() })
    }
}
