import Foundation

enum Side: String, Codable, Sendable {
    case white, black
    var opposite: Side { self == .white ? .black : .white }
    var label: String { self == .white ? L("Белые") : L("Чёрные") }
}

enum PieceKind: String, Codable, CaseIterable, Sendable {
    case pawn, knight, bishop, rook, queen, king
    var russian: String {
        switch self {
        case .pawn: return "пешка"
        case .knight: return "конь"
        case .bishop: return "слон"
        case .rook: return "ладья"
        case .queen: return "ферзь"
        case .king: return "король"
        }
    }
    var localizedName: String { L(russian) }
    var san: String {
        switch self {
        case .pawn: return ""
        case .knight: return "N"
        case .bishop: return "B"
        case .rook: return "R"
        case .queen: return "Q"
        case .king: return "K"
        }
    }
    var value: Int {
        switch self {
        case .pawn: return 100
        case .knight: return 320
        case .bishop: return 335
        case .rook: return 500
        case .queen: return 900
        case .king: return 0
        }
    }
}

struct Piece: Codable, Equatable, Sendable {
    let side: Side
    let kind: PieceKind
    var glyph: String {
        let white: [PieceKind: String] = [.king: "♔", .queen: "♕", .rook: "♖", .bishop: "♗", .knight: "♘", .pawn: "♙"]
        let black: [PieceKind: String] = [.king: "♚", .queen: "♛", .rook: "♜", .bishop: "♝", .knight: "♞", .pawn: "♟"]
        return (side == .white ? white : black)[kind]!
    }
}

struct Move: Codable, Equatable, Hashable, Sendable {
    let from: Int
    let to: Int
    var promotion: PieceKind? = nil
    var uci: String { squareName(from) + squareName(to) + (promotion?.san.lowercased() ?? "") }
}

func squareName(_ square: Int) -> String {
    String(Array("abcdefgh")[square % 8]) + String(square / 8 + 1)
}

func squareIndex(_ name: String) -> Int? {
    let chars = Array(name.lowercased())
    guard chars.count == 2, let file = Array("abcdefgh").firstIndex(of: chars[0]),
          let rank = chars[1].wholeNumberValue, (1...8).contains(rank) else { return nil }
    return (rank - 1) * 8 + file
}

func spokenSquare(_ square: Int) -> String {
    let files: [String]
    let ranks: [String]
    switch AppLanguage.current {
    case .ru:
        files = ["а", "бэ", "цэ", "дэ", "е", "эф", "жэ", "аш"]
        ranks = ["один", "два", "три", "четыре", "пять", "шесть", "семь", "восемь"]
    case .uk:
        files = ["а", "бе", "це", "де", "е", "еф", "же", "аш"]
        ranks = ["один", "два", "три", "чотири", "п’ять", "шість", "сім", "вісім"]
    case .en:
        files = ["ay", "bee", "see", "dee", "ee", "ef", "gee", "aitch"]
        ranks = ["one", "two", "three", "four", "five", "six", "seven", "eight"]
    }
    return files[square % 8] + " " + ranks[square / 8]
}

struct Position: Codable, Equatable, Sendable {
    var board: [Piece?]
    var turn: Side
    // White king/queen side, black king/queen side.
    var castling: Int
    var enPassant: Int?
    var halfmove: Int
    var fullmove: Int

    static var initial: Position {
        var board = [Piece?](repeating: nil, count: 64)
        let back: [PieceKind] = [.rook, .knight, .bishop, .queen, .king, .bishop, .knight, .rook]
        for file in 0..<8 {
            board[file] = Piece(side: .white, kind: back[file])
            board[file + 8] = Piece(side: .white, kind: .pawn)
            board[file + 48] = Piece(side: .black, kind: .pawn)
            board[file + 56] = Piece(side: .black, kind: back[file])
        }
        return Position(board: board, turn: .white, castling: 15, halfmove: 0, fullmove: 1)
    }

    func isAttacked(_ square: Int, by side: Side) -> Bool {
        let file = square % 8, rank = square / 8
        for from in 0..<64 {
            guard let piece = board[from], piece.side == side else { continue }
            let dx = file - from % 8, dy = rank - from / 8
            switch piece.kind {
            case .pawn:
                if abs(dx) == 1 && dy == (side == .white ? 1 : -1) { return true }
            case .knight:
                if (abs(dx) == 1 && abs(dy) == 2) || (abs(dx) == 2 && abs(dy) == 1) { return true }
            case .king:
                if max(abs(dx), abs(dy)) == 1 { return true }
            case .bishop, .rook, .queen:
                let diagonal = abs(dx) == abs(dy) && dx != 0
                let straight = (dx == 0) != (dy == 0)
                guard (piece.kind != .rook && diagonal) || (piece.kind != .bishop && straight) else { continue }
                let sx = dx.signum(), sy = dy.signum()
                var x = from % 8 + sx, y = from / 8 + sy
                var clear = true
                while x != file || y != rank {
                    if board[y * 8 + x] != nil { clear = false; break }
                    x += sx; y += sy
                }
                if clear { return true }
            }
        }
        return false
    }

    func inCheck(_ side: Side) -> Bool {
        guard let king = board.firstIndex(of: Piece(side: side, kind: .king)) else { return true }
        return isAttacked(king, by: side.opposite)
    }

    func legalMoves() -> [Move] {
        pseudoMoves().filter { !applying($0).inCheck(turn) }
    }

    private func pseudoMoves() -> [Move] {
        var moves = [Move]()
        func add(_ from: Int, _ to: Int) {
            if board[from]?.kind == .pawn && (to / 8 == 0 || to / 8 == 7) {
                for kind: PieceKind in [.queen, .rook, .bishop, .knight] { moves.append(Move(from: from, to: to, promotion: kind)) }
            } else { moves.append(Move(from: from, to: to)) }
        }
        for from in 0..<64 {
            guard let piece = board[from], piece.side == turn else { continue }
            let x = from % 8, y = from / 8
            if piece.kind == .pawn {
                let d = turn == .white ? 1 : -1
                let nextY = y + d
                guard (0..<8).contains(nextY) else { continue }
                if board[nextY * 8 + x] == nil {
                    add(from, nextY * 8 + x)
                    if y == (turn == .white ? 1 : 6) && board[(y + 2 * d) * 8 + x] == nil { add(from, (y + 2 * d) * 8 + x) }
                }
                for dx in [-1, 1] where (0..<8).contains(x + dx) {
                    let to = nextY * 8 + x + dx
                    let capture = board[to].map { $0.side != turn && $0.kind != .king } ?? false
                    let ep = to == enPassant && board[to] == nil && board[to - d * 8] == Piece(side: turn.opposite, kind: .pawn)
                    if capture || ep { add(from, to) }
                }
                continue
            }
            let directions: [(Int, Int)]
            switch piece.kind {
            case .knight: directions = [(1,2),(2,1),(-1,2),(-2,1),(1,-2),(2,-1),(-1,-2),(-2,-1)]
            case .bishop: directions = [(1,1),(1,-1),(-1,1),(-1,-1)]
            case .rook: directions = [(1,0),(-1,0),(0,1),(0,-1)]
            default: directions = [(1,1),(1,-1),(-1,1),(-1,-1),(1,0),(-1,0),(0,1),(0,-1)]
            }
            for (dx,dy) in directions {
                var nx = x + dx, ny = y + dy
                while (0..<8).contains(nx) && (0..<8).contains(ny) {
                    let to = ny * 8 + nx
                    if let target = board[to] {
                        if target.side != turn && target.kind != .king { add(from, to) }
                        break
                    }
                    add(from, to)
                    if piece.kind == .king || piece.kind == .knight { break }
                    nx += dx; ny += dy
                }
            }
            if piece.kind == .king {
                let base = turn == .white ? 0 : 56
                let kFlag = turn == .white ? 1 : 4, qFlag = kFlag * 2
                if from == base + 4 && !inCheck(turn) {
                    if castling & kFlag != 0 && board[base+7] == Piece(side: turn, kind: .rook)
                        && board[base+5] == nil && board[base+6] == nil
                        && !isAttacked(base+5, by: turn.opposite) && !isAttacked(base+6, by: turn.opposite) {
                        add(from, base+6)
                    }
                    if castling & qFlag != 0 && board[base] == Piece(side: turn, kind: .rook)
                        && board[base+1] == nil && board[base+2] == nil && board[base+3] == nil
                        && !isAttacked(base+3, by: turn.opposite) && !isAttacked(base+2, by: turn.opposite) {
                        add(from, base+2)
                    }
                }
            }
        }
        return moves
    }

    func applying(_ move: Move) -> Position {
        var result = self
        guard let piece = board[move.from] else { return self }
        let captured = board[move.to]
        result.board[move.from] = nil
        if piece.kind == .pawn && move.to == enPassant && captured == nil && move.from % 8 != move.to % 8 {
            result.board[move.to + (turn == .white ? -8 : 8)] = nil
        }
        result.board[move.to] = Piece(side: piece.side, kind: move.promotion ?? piece.kind)
        if piece.kind == .king {
            result.castling &= turn == .white ? ~3 : ~12
            if abs(move.to - move.from) == 2 {
                let rookFrom = move.to > move.from ? move.from + 3 : move.from - 4
                let rookTo = move.to > move.from ? move.from + 1 : move.from - 1
                result.board[rookTo] = result.board[rookFrom]
                result.board[rookFrom] = nil
            }
        }
        for (square, flag) in [(0,2),(7,1),(56,8),(63,4)] where move.from == square || move.to == square {
            result.castling &= ~flag
        }
        result.enPassant = piece.kind == .pawn && abs(move.to - move.from) == 16 ? (move.from + move.to) / 2 : nil
        result.halfmove = piece.kind == .pawn || captured != nil ? 0 : halfmove + 1
        result.fullmove = fullmove + (turn == .black ? 1 : 0)
        result.turn = turn.opposite
        return result
    }

    func san(_ move: Move) -> String {
        guard let piece = board[move.from] else { return move.uci }
        var text: String
        if piece.kind == .king && abs(move.to - move.from) == 2 {
            text = move.to > move.from ? "O-O" : "O-O-O"
        } else {
            text = piece.kind.san
            let isCapture = board[move.to] != nil || (piece.kind == .pawn && move.to == enPassant)
            if piece.kind != .pawn {
                let others = legalMoves().filter { $0.to == move.to && $0.from != move.from && board[$0.from]?.kind == piece.kind }
                if !others.isEmpty {
                    if !others.contains(where: { $0.from % 8 == move.from % 8 }) { text += String(Array("abcdefgh")[move.from % 8]) }
                    else if !others.contains(where: { $0.from / 8 == move.from / 8 }) { text += String(move.from / 8 + 1) }
                    else { text += squareName(move.from) }
                }
            } else if isCapture { text += String(Array("abcdefgh")[move.from % 8]) }
            if isCapture { text += "x" }
            text += squareName(move.to)
            if let promotion = move.promotion { text += "=" + promotion.san }
        }
        let next = applying(move)
        if next.inCheck(next.turn) { text += next.legalMoves().isEmpty ? "#" : "+" }
        return text
    }

    func spoken(_ move: Move) -> String {
        guard let piece = board[move.from] else { return move.uci }
        if piece.kind == .king && abs(move.to - move.from) == 2 {
            return move.to > move.from ? L("Короткая рокировка") : L("Длинная рокировка")
        }
        let capture = board[move.to] != nil || (piece.kind == .pawn && move.to == enPassant)
        var text = "\(piece.kind.localizedName.capitalized), \(spokenSquare(move.from)), \(capture ? L("берёт") : L("на")) \(spokenSquare(move.to))"
        if let promotion = move.promotion { text += L(", превращение: ") + promotion.localizedName }
        return text
    }

    var insufficientMaterial: Bool {
        let pieces = board.enumerated().compactMap { index, piece -> (Int, Piece)? in
            guard let piece, piece.kind != .king else { return nil }
            return (index, piece)
        }
        if pieces.isEmpty { return true }
        if pieces.count == 1 { return [.bishop, .knight].contains(pieces[0].1.kind) }
        if pieces.allSatisfy({ $0.1.kind == .bishop }) {
            return Set(pieces.map { ($0.0 / 8 + $0.0 % 8) % 2 }).count == 1
        }
        return false
    }

    var repetitionKey: String {
        let pieces = board.map { piece -> String in
            guard let piece else { return "." }
            let letter = piece.kind == .pawn ? "p" : piece.kind.san.lowercased()
            return piece.side == .white ? letter.uppercased() : letter
        }.joined()
        let relevantEP = enPassant.flatMap { ep in legalMoves().contains(where: { $0.to == ep && board[$0.from]?.kind == .pawn && $0.from % 8 != ep % 8 }) ? ep : nil }
        return pieces + turn.rawValue + String(castling) + ":" + (relevantEP.map(String.init) ?? "-")
    }
}

struct MoveRecord: Codable, Identifiable, Sendable {
    var id: Int
    let move: Move
    let san: String
    let spoken: String
    let side: Side
}

extension MoveRecord {
    var isCastling: Bool { san.hasPrefix("O-O") || san.hasPrefix("0-0") }
    var fullCoordinates: String {
        squareName(move.from) + (san.contains("x") ? "×" : "–") + squareName(move.to)
    }
    /// Piece figurine is rendered separately by the interface.
    var notationBody: String {
        if isCastling { return san.replacingOccurrences(of: "O", with: "0") }
        let promotion = move.promotion.map { "=" + $0.san } ?? ""
        let check = san.hasSuffix("#") ? "#" : (san.hasSuffix("+") ? "+" : "")
        return fullCoordinates + promotion + check
    }
}

struct ChessGame: Codable, Sendable {
    private(set) var positions: [Position] = [.initial]
    private(set) var records: [MoveRecord] = []
    var position: Position { positions.last! }

    var winner: Side? {
        position.inCheck(position.turn) && position.legalMoves().isEmpty ? position.turn.opposite : nil
    }

    var outcome: String? {
        if position.legalMoves().isEmpty {
            return position.inCheck(position.turn) ? L("Мат. {0} победили.", String(describing: position.turn.opposite.label)) : L("Ничья: пат.")
        }
        if position.insufficientMaterial { return L("Ничья: недостаточно материала.") }
        if position.halfmove >= 100 { return L("Ничья по правилу 50 ходов.") }
        let key = position.repetitionKey
        if positions.filter({ $0.repetitionKey == key }).count >= 3 { return L("Ничья: троекратное повторение.") }
        return nil
    }

    @discardableResult mutating func play(_ move: Move) -> Bool {
        guard outcome == nil, position.legalMoves().contains(move) else { return false }
        let p = position
        records.append(MoveRecord(id: records.count, move: move, san: p.san(move), spoken: p.spoken(move), side: p.turn))
        positions.append(p.applying(move))
        return true
    }

    func prefix(through ply: Int) -> ChessGame {
        var copy = self
        let count = min(records.count, max(0, ply))
        copy.records = Array(records.prefix(count))
        copy.positions = Array(positions.prefix(count + 1))
        return copy
    }

    // Validate on a copy before discarding any future moves.
    @discardableResult mutating func play(_ move: Move, at ply: Int) -> Bool {
        guard (0...records.count).contains(ply) else { return false }
        var branch = prefix(through: ply)
        guard branch.play(move) else { return false }
        self = branch
        return true
    }

    mutating func undoTurn(human: Side) {
        guard !records.isEmpty else { return }
        repeat { records.removeLast(); positions.removeLast() }
        while !records.isEmpty && position.turn != human
    }
}

struct Difficulty: Codable, Identifiable, Sendable, Equatable, CaseIterable {
    let targetElo: Int
    init(rating: Int) { targetElo = min(2900, max(400, Int((Double(rating) / 100).rounded()) * 100)) }
    private init(exact: Int) { targetElo = exact }
    static let beginner = Difficulty(rating: 400)
    // Decode existing saved games without changing their playing strength.
    static let easy = Difficulty(exact: 1320)
    static let medium = Difficulty(rating: 1600)
    static let hard = Difficulty(rating: 1900)
    static let candidate = Difficulty(rating: 2200)
    static let master = Difficulty(rating: 2400)
    static let maximum = Difficulty(exact: 0)
    static var allCases: [Difficulty] { stride(from: 400, through: 2900, by: 100).map { Difficulty(rating: $0) } + [.maximum] }
    var rawValue: String { self == .maximum ? "maximum" : String(targetElo) }
    var id: String { rawValue }
    var label: String { self == .maximum ? L("Максимальная сила") : String(targetElo) }
    var playingLevel: String {
        switch targetElo {
        case 400...600: return L("Первые шаги")
        case 700...900: return L("Начинающий")
        case 1000...1200: return L("Любитель")
        case 1201...1500: return L("Уверенный любитель")
        case 1501...1800: return L("Сильный любитель")
        case 1801...2100: return L("Продвинутый игрок")
        case 2101...2300: return L("Кандидат в мастера")
        case 2301...2400: return L("Мастер")
        case 2401...2600: return L("Гроссмейстер")
        case 2601...2800: return L("Элитный гроссмейстер")
        case 2801...2900: return L("Магнус Карлсен")
        default: return L("Очень сильный соперник")
        }
    }
    var engineElo: Int { targetElo == 0 ? 0 : max(1320, targetElo) }
    var skill: Int { targetElo > 0 && targetElo < 1320 ? 0 : 20 }
    var thinkMilliseconds: Int { targetElo == 0 ? 3000 : (targetElo < 1400 ? 300 : (targetElo < 2000 ? 700 : 1500)) }
    var detail: String { self == .maximum ? L("Без ограничения силы · до 3 с на ход") : L("Рейтинг указан приблизительно") }
    var mistakeProbability: Double { targetElo > 0 && targetElo < 1320 ? 0.9 * Double(1320 - targetElo) / 920 : 0 }
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        let legacy: [String: Difficulty] = ["easy": .easy, "medium": .medium, "hard": .hard, "candidate": .candidate, "master": .master, "maximum": .maximum]
        if let old = legacy[value] { self = old }
        else if let rating = Int(value), (400...3000).contains(rating) { self = Difficulty(exact: rating) }
        else { throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unknown strength") }
    }
    func encode(to encoder: Encoder) throws { var container = encoder.singleValueContainer(); try container.encode(rawValue) }
}

// An uncalibrated beginner scale: mix Skill 0 with short-sighted, noisy material choices.
// Stronger settings both reduce mistakes and increase awareness of immediate threats.
enum BeginnerOpponent {
    static func choose<R: RandomNumberGenerator>(in position: Position, preferred: Move,
                                                 level: Difficulty, using rng: inout R) -> Move {
        guard Double.random(in: 0..<1, using: &rng) < level.mistakeProbability else { return preferred }
        let legal = position.legalMoves()
        guard legal.count > 1 else { return legal.first ?? preferred }
        let awareness = Double(level.targetElo - 400) / 920
        let temperature = 650 - 450 * awareness
        func material(_ p: Position) -> Double {
            p.board.compactMap { $0 }.reduce(0) { $0 + Double($1.kind.value) * ($1.side == position.turn ? 1 : -1) }
        }
        let scored = legal.map { move -> (Move, Double) in
            let next = position.applying(move)
            let immediate = material(next)
            let replies = next.legalMoves()
            let worst = replies.map { material(next.applying($0)) }.min() ?? immediate
            let score = immediate + awareness * (worst - immediate)
            return (move, score)
        }
        let best = scored.map { $0.1 }.max() ?? 0
        let weighted = scored.map { ($0.0, exp(($0.1 - best) / temperature)) }
        var roll = Double.random(in: 0..<weighted.reduce(0) { $0 + $1.1 }, using: &rng)
        for (move, weight) in weighted { roll -= weight; if roll <= 0 { return move } }
        return weighted.last!.0
    }
}

struct MoveProblem: Equatable {
    let code: String
    let message: String
}

extension Position {
    func moveProblem(from: Int, to: Int) -> MoveProblem? {
        func issue(_ code: String, _ message: String) -> MoveProblem { MoveProblem(code: code, message: message) }
        guard (0..<64).contains(from), (0..<64).contains(to) else {
            return issue("outside_board", L("На доске есть только поля от а один до аш восемь."))
        }
        guard let piece = board[from] else { return issue("empty_source", L("На поле {0} нет фигуры.", String(describing: spokenSquare(from)))) }
        guard piece.side == turn else { return issue("opponent_piece", L("На поле {0} фигура соперника. Сейчас ходят {1}.", String(describing: spokenSquare(from)), String(describing: turn.label.lowercased()))) }
        guard from != to else { return issue("same_square", L("Начальное и конечное поле совпадают. Назовите другую клетку назначения.")) }
        let dx = to % 8 - from % 8, dy = to / 8 - from / 8
        if piece.kind == .king && abs(dx) == 2 && dy == 0 { return castlingProblem(long: dx < 0) }
        if board[to]?.side == turn { return issue("own_destination", L("На поле {0} уже стоит ваша фигура.", String(describing: spokenSquare(to)))) }
        if board[to]?.kind == .king { return issue("capture_king", L("Короля не берут. Нужно поставить мат.")) }
        let ax = abs(dx), ay = abs(dy)
        switch piece.kind {
        case .pawn:
            let direction = turn == .white ? 1 : -1
            if dy * direction <= 0 { return issue("pawn_direction", L("Пешка не ходит назад или вбок.")) }
            if dx == 0 {
                if dy == direction * 2 && from / 8 != (turn == .white ? 1 : 6) {
                    return issue("pawn_double", L("Пешка может пройти две клетки только с начального ряда."))
                }
                guard dy == direction || dy == direction * 2 else { return issue("pawn_distance", L("Пешка ходит на одну клетку вперёд, а с начального ряда может на две.")) }
                if board[to] != nil { return issue("pawn_forward_capture", L("Пешка не берёт вперёд. Она берёт по диагонали.")) }
            } else {
                guard ax == 1 && dy == direction else { return issue("pawn_geometry", L("Пешка берёт только на одну клетку по диагонали вперёд.")) }
                if board[to] == nil {
                    let victim = to - direction * 8
                    if enPassant != to || board[victim] != Piece(side: turn.opposite, kind: .pawn) {
                        return issue("pawn_empty_capture", L("На поле {0} нечего брать. Взятие на проходе сейчас недоступно.", String(describing: spokenSquare(to))))
                    }
                }
            }
        case .knight:
            if !((ax == 1 && ay == 2) || (ax == 2 && ay == 1)) { return issue("knight_geometry", L("Конь ходит буквой Г: две клетки в одном направлении и одна в другом.")) }
        case .bishop:
            if ax != ay { return issue("bishop_geometry", L("Слон ходит только по диагонали.")) }
        case .rook:
            if dx != 0 && dy != 0 { return issue("rook_geometry", L("Ладья ходит только по вертикали или горизонтали.")) }
        case .queen:
            if ax != ay && dx != 0 && dy != 0 { return issue("queen_geometry", L("Ферзь ходит по прямой или диагонали.")) }
        case .king:
            if max(ax, ay) != 1 { return issue("king_geometry", L("Король ходит на одну клетку.")) }
        }
        if piece.kind != .knight && max(ax, ay) > 1 {
            for step in 1..<max(ax, ay) {
                let square = (from / 8 + dy.signum() * step) * 8 + from % 8 + dx.signum() * step
                if board[square] != nil { return issue("blocked_path", L("Путь перекрыт фигурой на поле {0}.", String(describing: spokenSquare(square)))) }
            }
        }
        if legalMoves().contains(where: { $0.from == from && $0.to == to }) { return nil }
        if piece.kind == .king { return issue("king_attacked", L("На поле {0} король окажется под ударом.", String(describing: spokenSquare(to)))) }
        if inCheck(turn) { return issue("check_unresolved", L("Вашему королю шах. Этот ход не защищает от шаха.")) }
        return issue("king_exposed", L("После этого хода ваш король окажется под шахом."))
    }

    func castlingProblem(long: Bool) -> MoveProblem? {
        func issue(_ code: String, _ message: String) -> MoveProblem { MoveProblem(code: code, message: message) }
        let base = turn == .white ? 0 : 56
        let flag = (turn == .white ? 1 : 4) * (long ? 2 : 1)
        guard castling & flag != 0, board[base + 4] == Piece(side: turn, kind: .king),
              board[base + (long ? 0 : 7)] == Piece(side: turn, kind: .rook) else {
            return issue("castle_rights", L("Рокировка на эту сторону недоступна: король или ладья уже ходили, либо ладьи нет на месте."))
        }
        if inCheck(turn) { return issue("castle_in_check", L("Нельзя рокироваться, пока король под шахом.")) }
        for offset in (long ? [3, 2, 1] : [5, 6]) where board[base + offset] != nil {
            return issue("castle_blocked", L("Рокировке мешает фигура на поле {0}.", String(describing: spokenSquare(base + offset))))
        }
        for offset in (long ? [3, 2] : [5, 6]) where isAttacked(base + offset, by: turn.opposite) {
            return issue("castle_attacked", L("Нельзя рокироваться через поле под ударом: {0}.", String(describing: spokenSquare(base + offset))))
        }
        return nil
    }
}

struct ArchivedGame: Codable, Identifiable, Sendable {
    let id: UUID
    let startedAt: Date
    let updatedAt: Date
    let game: ChessGame
    let human: Side
    let difficulty: Difficulty
    var resultLabel: String {
        if let winner = game.winner { return winner == human ? L("Победа") : L("Поражение") }
        return game.outcome == nil ? L("Не завершена") : L("Ничья")
    }
}

// Writes atomically; failed writes leave both the previous file and in-memory state intact.
// Excluded IDs prevent a deleted ongoing game from silently reappearing on its next move.
final class GameArchiveStore {
    private struct State: Codable {
        var entries: [ArchivedGame] = []
        var excluded: Set<UUID> = []
    }
    private var state: State
    private let url: URL
    var entries: [ArchivedGame] { state.entries.sorted { $0.startedAt > $1.startedAt } }
    init(url: URL) throws {
        self.url = url
        if FileManager.default.fileExists(atPath: url.path) {
            state = try JSONDecoder().decode(State.self, from: Data(contentsOf: url))
            guard state.entries.allSatisfy({ entry in
                let game = entry.game
                return game.positions.count == game.records.count + 1
                    && game.positions.allSatisfy { $0.board.count == 64 }
                    && game.records.enumerated().allSatisfy { index, record in
                        record.id == index && (0..<64).contains(record.move.from) && (0..<64).contains(record.move.to)
                    }
            }) else { throw CocoaError(.fileReadCorruptFile) }
        } else { state = State() }
    }
    func upsert(_ entry: ArchivedGame) throws {
        guard !state.excluded.contains(entry.id) else { return }
        var next = state
        next.entries.removeAll { $0.id == entry.id }
        if !entry.game.records.isEmpty { next.entries.append(entry) }
        try commit(next)
    }
    func delete(_ id: UUID) throws {
        var next = state
        next.entries.removeAll { $0.id == id }
        next.excluded.insert(id)
        try commit(next)
    }
    func clear(currentID: UUID) throws {
        var next = state
        next.excluded.formUnion(next.entries.map(\.id))
        next.excluded.insert(currentID)
        next.entries = []
        try commit(next)
    }
    private func commit(_ next: State) throws {
        let data = try JSONEncoder().encode(next)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: url, options: .atomic)
        state = next
    }
}
