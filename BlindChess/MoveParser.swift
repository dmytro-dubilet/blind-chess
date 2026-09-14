import Foundation

enum ParsedMove: Equatable {
    case move(Move)
    case ambiguous
    case invalid
}

enum MoveParser {
    static func normalize(_ text: String) -> String {
        AppLanguage.current.canonicalCommand(text).lowercased().replacingOccurrences(of: "ё", with: "е")
            .replacingOccurrences(of: "—", with: " ").replacingOccurrences(of: "–", with: " ")
    }

    // Match the entire utterance: negative or mixed move commands must never undo a turn.
    static func isUndoCommand(_ text: String, language: AppLanguage = .current) -> Bool {
        let words = text.lowercased().components(separatedBy: .whitespacesAndNewlines.union(.punctuationCharacters))
            .filter { !$0.isEmpty }.joined(separator: " ")
        let commands: Set<String>
        switch language {
        case .ru: commands = ["отмена", "отмени", "отменить", "отмени ход", "отменить ход", "отмена хода", "отмени последний ход", "отменить последний ход", "назад"]
        case .uk: commands = ["скасування", "скасуй", "скасувати", "скасуй хід", "скасувати хід", "скасуй останній хід", "скасувати останній хід", "назад"]
        case .en: commands = ["undo", "undo move", "undo the move", "undo last move", "undo the last move", "take back", "take back the last move", "back"]
        }
        return commands.contains(words)
    }

    // Fuzzy control commands never execute automatically. Match one word only,
    // excluding negation, coordinates and mixed sentences before measuring distance.
    static func isSuspectedUndoCommand(_ text: String, language: AppLanguage = .current) -> Bool {
        let words = text.lowercased().components(separatedBy: .whitespacesAndNewlines.union(.punctuationCharacters))
            .filter { !$0.isEmpty }
        guard words.count == 1, let word = words.first, word.allSatisfy({ $0.isLetter }) else { return false }
        let targets: [String]
        switch language {
        case .ru: targets = ["отмена", "отмени", "отменить"]
        case .uk: targets = ["скасування", "скасуй", "скасувати"]
        case .en: targets = ["undo"]
        }
        return targets.contains { target in
            guard word.first == target.first, word.count >= target.count - 1 else { return false }
            var row = Array(0...target.count)
            for (i, a) in word.enumerated() {
                var next = [i + 1]
                for (j, b) in target.enumerated() {
                    next.append(min(next[j] + 1, row[j + 1] + 1, row[j] + (a == b ? 0 : 1)))
                }
                row = next
            }
            let distance = row.last!
            if distance <= (target.count >= 6 ? 2 : 1) { return true }
            func consonants(_ value: String) -> String {
                value.filter { !"аеёиоуыэюяіїєaeiouy".contains($0) }.reduce("") { result, letter in
                    result.last == letter ? result : result + String(letter)
                }
            }
            return language != .en && distance <= 3 && word.prefix(2) == target.prefix(2)
                && consonants(word) == consonants(target)
        }
    }

    private static func normalizeVocabulary(_ text: String) -> String {
        var input = normalize(text)
        for (pattern, replacement) in [
            ("\\b(?:ферс|ферсь|ферес|фересь)\\b", "ферзь"),
            ("\\b(?:ракировка|рокеровка|ракіровка)\\b", "рокировка")
        ] {
            input = input.replacingOccurrences(of: pattern, with: replacement, options: .regularExpression)
        }
        // «и» can stand for E only immediately before a rank, never as a free-standing conjunction.
        input = input.replacingOccurrences(of: "\\bи(?=\\s*(?:[1-8]|один|два|три|четыре|пять|шесть|семь|восемь)\\b)",
                                           with: "е", options: .regularExpression)
        return input
    }

    static func parse(_ text: String, in position: Position) -> ParsedMove {
        var input = normalizeVocabulary(text)
        // Only coordinate utterances or a piece followed by a destination qualify.
        // Ordinary sentences containing the preposition «до» are not chess commands.
        let rank = "(?:[1-8]|один|два|три|четыре|пять|шесть|семь|восемь)"
        let source = "[a-hа-я]{1,3}\\s*" + rank
        let piece = "(?:пешка|конь|слон|ладья|ферзь|король)(?:\\s+(?:бьет|берет|на))?"
        let pattern = "^(?:(?:" + source + "|" + piece + ")\\s+)?до\\s*" + rank + "[.!?]*$"
        if input.range(of: pattern, options: .regularExpression) != nil {
            input = input.replacingOccurrences(of: "\\bдо(?=\\s*(?:" + rank + "))", with: "дэ", options: .regularExpression)
        }
        let requested = requestedPromotion(input)
        if requested.present && requested.kind == nil { return .invalid }
        let legal = position.legalMoves()
        let compact = input.replacingOccurrences(of: " ", with: "")
        if let move = legal.first(where: { $0.uci == compact || (squareIndex(compact) == nil && position.san($0).lowercased() == compact) }) { return .move(move) }
        // Never discard an unknown piece name and execute a different piece's move.
        let commandPrefix = input.components(separatedBy: "превращ").first!.components(separatedBy: "=").first!
        let isCastleNotation = ["o-o", "0-0", "o-o-o", "0-0-0"].contains(compact)
        let canonicalPrefix = canonicalTokens(commandPrefix)
        guard isCastleNotation || canonicalPrefix != nil else { return .invalid }
        if let canonicalPrefix {
            // Use every recognized coordinate, including a phonetic source square.
            // Retain the original promotion suffix so underpromotions are not lost.
            input = canonicalPrefix + " " + input.dropFirst(commandPrefix.count)
        }
        if input.contains("рокиров") || ["o-o", "0-0", "o-o-o", "0-0-0"].contains(compact) {
            let long = input.contains("длин") || input.contains("ферзев") || compact == "o-o-o" || compact == "0-0-0"
            let moves = legal.filter { position.board[$0.from]?.kind == .king && $0.to - $0.from == (long ? -2 : 2) }
            return resolve(moves)
        }
        let squares = extractSquares(input)
        guard !squares.isEmpty, squares.count <= 2 else { return .invalid }
        var kind: PieceKind?
        let names: [(String, PieceKind)] = [("пешк",.pawn),("конь",.knight),("конем",.knight),("коня",.knight),("слон",.bishop),("ладь",.rook),("ферз",.queen),("корол",.king)]
        // Piece names following a promotion marker describe the new piece, not the moving pawn.
        let prefix = input.components(separatedBy: "превращ").first!.components(separatedBy: "=").first!
        for (name, value) in names where prefix.contains(name) { kind = value; break }
        let promotionNames: [(String, PieceKind)] = [("ферз",.queen),("ладь",.rook),("слон",.bishop),("кон",.knight)]
        var promotion: PieceKind?
        if let marker = input.range(of: "превращ") {
            let suffix = String(input[marker.lowerBound...])
            promotion = promotionNames.first(where: { suffix.contains($0.0) })?.1
        }
        var candidates = legal.filter { move in
            move.to == squares.last! && (squares.count == 1 || move.from == squares[0])
                && (kind == nil || position.board[move.from]?.kind == kind)
        }
        if requested.present {
            candidates = candidates.filter { $0.promotion == requested.kind }
        }
        if input.contains("бьет") || input.contains("берет") {
            candidates = candidates.filter { position.board[$0.to] != nil || (position.board[$0.from]?.kind == .pawn && $0.to == position.enPassant && $0.from % 8 != $0.to % 8) }
        }
        if candidates.contains(where: { $0.promotion != nil }) {
            candidates = candidates.filter { $0.promotion == (requested.kind ?? promotion ?? .queen) }
        }
        return resolve(candidates)
    }

    /// A fast local second pass over text; never changes an explicit rank or legal move.
    static func parseRecovering(_ text: String, in position: Position) -> (result: ParsedMove, correctedText: String?) {
        let normalized = normalizeVocabulary(text)
        let normalizedChanged = normalized != normalize(text)
        let corrected = recoverText(normalized)
        let first = parse(normalized, in: position)
        if case .move = first { return (first, corrected ?? (normalizedChanged ? normalized : nil)) }
        guard let corrected else { return (first, normalizedChanged ? normalized : nil) }
        // Also retry ambiguous input, preserving the explicitly named piece.
        return (parse("на " + corrected, in: position), corrected)
    }

    private static func recoverText(_ text: String) -> String? {
        guard let corrected = canonicalTokens(text), corrected != normalizeVocabulary(text) else { return nil }
        return corrected
    }

    private static func canonicalTokens(_ text: String) -> String? {
        let files = ["а":"a", "эй":"a", "a":"a", "бэ":"b", "бе":"b", "би":"b", "б":"b", "b":"b",
                     "цэ":"c", "це":"c", "ца":"c", "са":"c", "ц":"c", "с":"c", "си":"c", "c":"c",
                     "дэ":"d", "де":"d", "ди":"d", "дай":"d", "до":"d", "д":"d", "d":"d",
                     "е":"e", "э":"e", "e":"e", "эф":"f", "эфь":"f", "ф":"f", "f":"f",
                     "жэ":"g", "же":"g", "джи":"g", "гэ":"g", "г":"g", "ж":"g", "g":"g",
                     "аш":"h", "эйч":"h", "х":"h", "h":"h"]
        let ranks = ["один":"1", "два":"2", "две":"2", "три":"3", "четыре":"4", "пять":"5", "шесть":"6", "семь":"7", "восемь":"8",
                     "1":"1", "2":"2", "3":"3", "4":"4", "5":"5", "6":"6", "7":"7", "8":"8"]
        let words: Set<String> = ["пешка", "конь", "конем", "коня", "слон", "ладья", "ферзь", "король", "бьет", "берет", "на", "из", "от", "с", "в", "превращение", "пешкой", "пешку", "слоном", "слона", "ладьей", "ладью", "ферзем", "ферзя", "королем", "короля", "рокировка", "короткая", "короткую", "длинная", "длинную", "ферзевая", "королевская"]
        let expanded = normalizeVocabulary(text).replacingOccurrences(of: "([1-8])([a-zа-я])", with: "$1 $2", options: .regularExpression)
        let tokens = expanded.components(separatedBy: CharacterSet.alphanumerics.inverted).filter { !$0.isEmpty }
        var output: [String] = []
        var index = 0
        while index < tokens.count {
            let token = tokens[index]
            if let file = files[token], index + 1 < tokens.count, let rank = ranks[tokens[index + 1]] {
                output.append(file + rank); index += 2; continue
            }
            var glued: String?
            for (fileSound, file) in files {
                for (rankSound, rank) in ranks where token == fileSound + rankSound { glued = file + rank }
            }
            if let glued { output.append(glued) }
            else if words.contains(token) { output.append(token) }
            else { return nil }
            index += 1
        }
        // Repeating the same request is not a move from a square to itself.
        if output.count >= 2, output.count % 2 == 0, output.count >= 4 || text.contains(".") {
            let half = output.count / 2
            if Array(output.prefix(half)) == Array(output.suffix(half)) { output = Array(output.prefix(half)) }
        }
        let corrected = output.joined(separator: " ")
        return corrected.isEmpty ? nil : corrected
    }

    /// The final spoken square is always the destination. Fuzzy recovery never selects by legality.
    static func phoneticDestination(_ text: String) -> String? {
        let input = normalizeVocabulary(text)
        let expanded = input.replacingOccurrences(of: "([a-zа-я])([1-8])", with: "$1 $2", options: .regularExpression)
            .replacingOccurrences(of: "([1-8])([a-zа-я])", with: "$1 $2", options: .regularExpression)
        let tokens = expanded.components(separatedBy: CharacterSet.alphanumerics.inverted).filter { !$0.isEmpty }
        guard !tokens.isEmpty, !tokens.contains(where: { ["не", "нет", "или", "либо", "not", "or", "ні", "або"].contains($0) }),
              !input.contains("="), !input.contains("превращ") else { return nil }
        let files = ["а", "бэ", "цэ", "дэ", "е", "эф", "жэ", "аш"]
        let ranks = ["один", "два", "три", "четыре", "пять", "шесть", "семь", "восемь"]
        var scored: [String: Double] = [:]
        for length in 1...min(2, tokens.count) {
            let tail = Array(tokens.suffix(length))
            guard tail.joined().rangeOfCharacter(from: .letters) != nil else { continue }
            let prefix = tokens.dropLast(length).joined(separator: " ")
            // The rest must already be a complete, recognized prefix, not discarded prose.
            guard let canonical = prefix.isEmpty ? "" : phoneticPrefix(prefix),
                  extractSquares(canonical).count <= 1 else { continue }
            let allowed: Set<String> = ["пешка", "пешкой", "пешку", "конь", "конем", "коня", "слон", "слоном", "слона",
                "ладья", "ладьей", "ладью", "ферзь", "ферзем", "ферзя", "король", "королем", "короля", "на", "из", "от", "с", "в", "бьет", "берет"]
            guard canonical.split(separator: " ").allSatisfy({ allowed.contains(String($0)) || squareIndex(String($0)) != nil }) else { continue }
            let knownTail = canonicalTokens(tail.joined(separator: " ")).map(extractSquares) ?? []
            // A clearly named destination must never be replaced to make the move legal.
            if let destination = knownTail.first {
                if knownTail.count == 1, !prefix.isEmpty, canonicalTokens(prefix) == nil {
                    scored[canonical + " " + squareName(destination)] = 1
                }
                continue
            }
            let knownRank = tail.last.flatMap { token in ranks.firstIndex(of: token) ?? Int(token).flatMap { (1...8).contains($0) ? $0 - 1 : nil } }
            let knownFile: Int? = tail.count == 2 ? files.firstIndex(of: tail[0]) ?? Array("abcdefgh").firstIndex(of: Character(tail[0].count == 1 ? tail[0] : "?")) : nil
            var sounds = tail
            if let knownFile, sounds.count == 2 { sounds[0] = files[knownFile] }
            if let knownRank { sounds[sounds.count - 1] = ranks[knownRank] }
            let sound = phoneticKey(sounds.joined())
            guard sound.count >= 3 else { continue }
            for file in 0..<8 where knownFile == nil || knownFile == file {
                for rank in 0..<8 where knownRank == nil || knownRank == rank {
                    let target = phoneticKey(files[file] + ranks[rank])
                    let score = 1 - Double(editDistance(sound, target)) / Double(max(sound.count, target.count))
                    guard score >= 0.78 else { continue }
                    let command = (canonical + " " + squareName(rank * 8 + file)).trimmingCharacters(in: .whitespaces)
                    scored[command] = max(scored[command] ?? 0, score)
                }
            }
        }
        let ranked = scored.sorted { $0.value == $1.value ? $0.key < $1.key : $0.value > $1.value }
        guard let best = ranked.first, ranked.count == 1 || best.value - ranked[1].value >= 0.04 else { return nil }
        return best.key
    }

    private static func phoneticPrefix(_ text: String) -> String? {
        if let exact = canonicalTokens(text) { return exact }
        var words = text.split(separator: " ").map(String.init)
        guard let first = words.first, first.count >= 3 else { return nil }
        let sound = phoneticKey(first)
        let choices = ["пешка", "конь", "слон", "ладья", "ферзь", "король"].map { name -> (String, Double) in
            let target = phoneticKey(name)
            return (name, 1 - Double(editDistance(sound, target)) / Double(max(sound.count, target.count)))
        }.sorted { $0.1 > $1.1 }
        guard choices[0].1 >= 0.8, choices[0].1 - choices[1].1 >= 0.15 else { return nil }
        words[0] = choices[0].0
        return canonicalTokens(words.joined(separator: " "))
    }

    private static func phoneticKey(_ text: String) -> [Character] {
        let groups = ["ь":"", "ъ":"", "е":"и", "э":"и", "ы":"и", "я":"и", "о":"а", "ю":"у",
                      "б":"п", "д":"т", "г":"к", "з":"с", "ж":"ш", "в":"ф"]
        return Array(text.lowercased().map { groups[String($0)] ?? String($0) }.joined())
    }

    private static func editDistance(_ a: [Character], _ b: [Character]) -> Int {
        var previous = Array(0...b.count)
        for (i, letter) in a.enumerated() {
            var current = [i + 1]
            for (j, other) in b.enumerated() {
                current.append(min(previous[j + 1] + 1, current[j] + 1, previous[j] + (letter == other ? 0 : 1)))
            }
            previous = current
        }
        return previous[b.count]
    }

    struct ContextMatch {
        let moves: [Move]
        let score: Double
        let changedDestination: Bool
    }

    /// All fuzzy results are proposals, never executable moves. The board ranks plausible
    /// readings, but cannot override a named source, rank, piece or capture requirement.
    static func contextualMatch(_ text: String, in position: Position) -> ContextMatch? {
        let input = normalizeVocabulary(text)
        let expanded = input.replacingOccurrences(of: "([a-zа-я])([1-8])", with: "$1 $2", options: .regularExpression)
            .replacingOccurrences(of: "([1-8])([a-zа-я])", with: "$1 $2", options: .regularExpression)
        let tokens = expanded.components(separatedBy: CharacterSet.alphanumerics.inverted).filter { !$0.isEmpty }
        let forbidden: Set<String> = ["не", "нет", "или", "либо", "not", "or", "ні", "або", "отмена", "назад", "стоп", "пауза"]
        guard !tokens.isEmpty, tokens.count <= 8, !tokens.contains(where: forbidden.contains),
              !input.contains("="), !input.contains("превращ"), !input.contains("рокиров") else { return nil }
        let files = ["а", "бэ", "цэ", "дэ", "е", "эф", "жэ", "аш"]
        let ranks = ["один", "два", "три", "четыре", "пять", "шесть", "семь", "восемь"]
        let legal = position.legalMoves().filter { $0.promotion == nil || $0.promotion == .queen }
        var scores: [Move: (Double, Bool)] = [:]
        for length in 1...min(3, tokens.count) {
            let tail = Array(tokens.suffix(length))
            let prefix = Array(tokens.dropLast(length))
            guard let parts = recoveryPrefix(prefix) else { continue }
            let tailCanonical = canonicalTokens(tail.joined(separator: " "))
            let knownTail = tailCanonical.map(extractSquares) ?? []
            guard knownTail.count <= 1 else { continue }
            if let field = knownTail.first, tailCanonical != squareName(field) { continue }
            let known = knownTail.first
            let knownRank = known.map { $0 / 8 } ?? tail.last.flatMap { ranks.firstIndex(of: $0) ?? Int($0).flatMap { (1...8).contains($0) ? $0-1 : nil } }
            var spoken = tail
            for i in spoken.indices {
                if let digit = Int(spoken[i]), (1...8).contains(digit) { spoken[i] = ranks[digit-1] }
                else if spoken[i].count == 1, let file = Array("abcdefgh").firstIndex(of: Character(spoken[i])) { spoken[i] = files[file] }
            }
            let sound = recoverySound(spoken.joined())
            guard sound.count >= 3 else { continue }
            for move in legal {
                guard parts.source == nil || parts.source == move.from,
                      parts.kind == nil || parts.kind == position.board[move.from]?.kind,
                      !parts.capture || position.board[move.to] != nil || (position.board[move.from]?.kind == .pawn && position.enPassant == move.to),
                      knownRank == nil || knownRank == move.to / 8 else { continue }
                let changed = known != nil && known != move.to
                // Alternative letters only with a named piece, no named source, and no
                // legal interpretation of the explicit destination. Always confirmed.
                if changed {
                    guard AppLanguage.current != .en, parts.kind != nil, parts.source == nil,
                          !legal.contains(where: { $0.to == known && position.board[$0.from]?.kind == parts.kind }) else { continue }
                }
                let target = recoverySound(files[move.to % 8] + ranks[move.to / 8])
                let destinationScore = known == move.to ? 1 : similarity(sound, target)
                guard destinationScore >= 0.70 else { continue }
                let score = destinationScore * 0.75 + parts.score * 0.25 - (changed ? 0.04 : 0)
                guard score >= 0.73 else { continue }
                if score > (scores[move]?.0 ?? 0) { scores[move] = (score, changed) }
            }
        }
        let ranked = scores.sorted { $0.value.0 == $1.value.0 ? $0.key.uci < $1.key.uci : $0.value.0 > $1.value.0 }
        guard let best = ranked.first else { return nil }
        let close = ranked.filter { best.value.0 - $0.value.0 < 0.065 }
        // Multiple readings of the destination need a new utterance, not a guessed move.
        guard Set(close.map { $0.key.to }).count == 1 else { return nil }
        return ContextMatch(moves: close.map(\.key), score: best.value.0, changedDestination: best.value.1)
    }

    /// Very weak ASR may only propose a uniquely matching piece + exact destination.
    /// Roman ranks are normalized only at the end of a coordinate, never in prose.
    static func weakSpeechCandidate(_ text: String, in position: Position) -> Move? {
        guard text.count <= 80 else { return nil }
        var input = normalizeVocabulary(text).trimmingCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters))
        let pattern = #"([a-h])[-\s]*([iv]+)$"#
        if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
           let match = regex.firstMatch(in: input, range: NSRange(input.startIndex..., in: input)),
           let fileRange = Range(match.range(at: 1), in: input),
           let rankRange = Range(match.range(at: 2), in: input),
           let whole = Range(match.range, in: input),
           let rank = ["i":1,"ii":2,"iii":3,"iv":4,"v":5,"vi":6,"vii":7,"viii":8][input[rankRange].lowercased()] {
            input.replaceSubrange(whole, with: String(input[fileRange]) + String(rank))
        }
        let expanded = input.replacingOccurrences(of: "([a-zа-я])([1-8])", with: "$1 $2", options: .regularExpression)
        let tokens = expanded.components(separatedBy: CharacterSet.alphanumerics.inverted).filter { !$0.isEmpty }
        // Require an explicit destination and identifiable piece/source in the prefix.
        guard tokens.count >= 3, let rank = tokens.last, Int(rank).map({ (1...8).contains($0) }) == true,
              let tail = canonicalTokens(tokens.suffix(2).joined(separator: " ")),
              extractSquares(tail).count == 1,
              let parts = recoveryPrefix(Array(tokens.dropLast(2))),
              parts.kind != nil || parts.source != nil,
              let match = contextualMatch(input, in: position),
              match.moves.count == 1, !match.changedDestination, match.score >= 0.90 else { return nil }
        return match.moves.first
    }

    private static func similarity(_ a: [Character], _ b: [Character]) -> Double {
        1 - Double(editDistance(a,b)) / Double(max(1,max(a.count,b.count)))
    }

    private static func recoverySound(_ raw: String) -> [Character] {
        var text = raw.lowercased()
        // Transliteration accommodates mixed-script ASR output without per-phrase aliases.
        for (a,b) in [("sch","щ"),("sh","ш"),("ch","ч"),("zh","ж"),("ya","я"),("yu","ю")] {
            text = text.replacingOccurrences(of:a,with:b)
        }
        let latin = ["a":"а","b":"б","c":"ц","d":"д","e":"е","f":"ф","g":"г","h":"х","i":"и","j":"ж","k":"к","l":"л","m":"м","n":"н","o":"о","p":"п","r":"р","s":"с","t":"т","u":"у","v":"в","w":"в","y":"и","z":"з","і":"и","ї":"и","є":"е","ц":"с"]
        text = text.map { latin[String($0)] ?? String($0) }.joined()
        return phoneticKey(text).filter { $0.isLetter }
    }

    private struct RecoveryPrefix {
        var kind: PieceKind?
        var source: Int?
        var capture = false
        var score = 1.0
    }
    private static func recoveryPrefix(_ tokens: [String]) -> RecoveryPrefix? {
        var result = RecoveryPrefix()
        var words = tokens
        if let first = words.first {
            let forms: [(PieceKind,[String])] = [(.pawn,["пешка","пешкой","пешку"]),(.knight,["конь","конем","коня"]),(.bishop,["слон","слоном","слона"]),(.rook,["ладья","ладьей","ладью"]),(.queen,["ферзь","ферзем","ферзя"]),(.king,["король","королем","короля"])]
            let ranked = forms.map { kind,names in (kind,names.map { similarity(recoverySound(first),recoverySound($0)) }.max()!) }.sorted { $0.1 > $1.1 }
            if first.count >= 3, ranked[0].1 >= 0.60, ranked[0].1 - ranked[1].1 >= 0.12 {
                result.kind = ranked[0].0; result.score = ranked[0].1; words.removeFirst()
            }
        }
        var i = 0
        while i < words.count {
            let word = words[i]
            if ["на","из","от","с","в"].contains(word) { i += 1; continue }
            if result.source == nil {
                var found = false
                for n in [2,1] where i+n <= words.count {
                    if let canonical = canonicalTokens(words[i..<i+n].joined(separator:" ")) {
                        let fields = extractSquares(canonical)
                        if fields.count == 1, canonical == squareName(fields[0]) {
                            result.source = fields[0]; i += n; found = true; break
                        }
                    }
                }
                if found { continue }
            }
            let verbScore = ["бьет","берет"].map { similarity(recoverySound(word),recoverySound($0)) }.max()!
            guard result.kind != nil, !result.capture, word.count <= 7, verbScore >= 0.40 else { return nil }
            result.capture = true; result.score = min(result.score, max(0.6,verbScore)); i += 1
        }
        return result
    }

    static func clarification(_ text: String, candidates: [Move], in position: Position) -> [Move]? {
        let normalized = normalizeVocabulary(text)
        guard let canonical = canonicalTokens(normalized) else { return nil }
        let squares = extractSquares(canonical)
        if squares.count == 1, canonical == squareName(squares[0]) {
            return candidates.filter { $0.from == squares[0] }
        }
        guard squares.isEmpty, let prefix = recoveryPrefix(canonical.split(separator:" ").map(String.init)),
              let kind = prefix.kind, prefix.source == nil, !prefix.capture else { return nil }
        return candidates.filter { position.board[$0.from]?.kind == kind }
    }

    private static func requestedPromotion(_ input: String) -> (present: Bool, kind: PieceKind?) {
        guard let marker = input.range(of: "превращ") ?? input.range(of: "=") else { return (false, nil) }
        let suffix = String(input[marker.upperBound...])
        let choices: [(String, PieceKind)] = [("ферз", .queen), ("ладь", .rook), ("слон", .bishop), ("кон", .knight)]
        if let kind = choices.first(where: { suffix.contains($0.0) })?.1 { return (true, kind) }
        let symbol = suffix.trimmingCharacters(in: .whitespacesAndNewlines)
        return (true, ["q": PieceKind.queen, "r": .rook, "b": .bishop, "n": .knight][symbol])
    }

    static func explanation(_ text: String, in position: Position, ambiguous: Bool = false) -> MoveProblem {
        let input = recoverText(text) ?? normalizeVocabulary(text)
        if ambiguous { return MoveProblem(code: "ambiguous", message: L("На это поле могут пойти несколько фигур. Назовите начальное поле.")) }
        if input.contains("рокиров") || ["o-o", "0-0", "o-o-o", "0-0-0"].contains(input) {
            let long = input.contains("длин") || input.contains("ферзев") || ["o-o-o", "0-0-0"].contains(input)
            return position.castlingProblem(long: long) ?? MoveProblem(code: "unrecognized", message: L("Уточните: короткая или длинная рокировка?"))
        }
        let requested = requestedPromotion(input)
        if requested.present && requested.kind == nil {
            return MoveProblem(code: "promotion_choice", message: L("Пешку можно превратить только в ферзя, ладью, слона или коня."))
        }
        let squares = extractSquares(input)
        if requested.present, let destination = squares.last, destination / 8 != (position.turn == .white ? 7 : 0) {
            return MoveProblem(code: "promotion_rank", message: L("Превращение возможно только на последнем ряду."))
        }
        if let to = squares.last, position.board[to] == nil, position.enPassant != to,
           input.contains("бьет") || input.contains("берет") {
            return MoveProblem(code: "empty_capture", message: L("На поле {0} нет фигуры для взятия.", String(describing: spokenSquare(to))))
        }
        guard !squares.isEmpty, squares.count <= 2 else {
            return MoveProblem(code: "coordinates", message: L("Не разобрал поля. Назовите начальное и конечное, например: е два, е четыре."))
        }
        if squares.count == 1, let destination = squares.first, position.board[destination]?.side == position.turn {
            return MoveProblem(code: "own_destination", message: L("На поле {0} уже стоит ваша фигура.", spokenSquare(destination)))
        }
        let names: [(String, PieceKind)] = [("пешк", .pawn), ("конь", .knight), ("конем", .knight), ("коня", .knight), ("слон", .bishop), ("ладь", .rook), ("ферз", .queen), ("корол", .king)]
        let prefix = input.components(separatedBy: "превращ").first!
        let kind = names.first(where: { prefix.contains($0.0) })?.1
        if squares.count == 2 {
            if let kind, let piece = position.board[squares[0]], piece.side == position.turn, piece.kind != kind {
                return MoveProblem(code: "piece_mismatch", message: L("На поле {0} стоит {1}, а не названная фигура.", String(describing: spokenSquare(squares[0])), String(describing: piece.kind.localizedName)))
            }
            return position.moveProblem(from: squares[0], to: squares[1]) ?? MoveProblem(code: "promotion", message: L("Уточните превращение: ферзь, ладья, слон или конь."))
        }
        let sources = (0..<64).filter { position.board[$0]?.side == position.turn && (kind == nil || position.board[$0]?.kind == kind) }
        if sources.isEmpty { return MoveProblem(code: "missing_piece", message: L("У вас нет такой фигуры на доске.")) }
        let problems = sources.compactMap { position.moveProblem(from: $0, to: squares[0]) }
        if sources.count == 1, let issue = problems.first { return issue }
        // Select a source only when the movement geometry identifies it uniquely.
        // This lets a blocked bishop explain the obstruction rather than ask for its source.
        let geometryCodes: Set<String> = ["pawn_direction", "pawn_double", "pawn_distance", "pawn_geometry",
                                          "knight_geometry", "bishop_geometry", "rook_geometry", "queen_geometry", "king_geometry", "same_square"]
        let plausible = problems.filter { !geometryCodes.contains($0.code) }
        if plausible.count == 1, let issue = plausible.first { return issue }
        if let first = problems.first, problems.count == sources.count, problems.allSatisfy({ $0.code == first.code }) { return first }
        return MoveProblem(code: "source_needed", message: L("Не нахожу допустимого хода на поле {0}. Назовите начальное поле.", String(describing: spokenSquare(squares[0]))))
    }

    private static func resolve(_ moves: [Move]) -> ParsedMove {
        moves.count == 1 ? .move(moves[0]) : (moves.isEmpty ? .invalid : .ambiguous)
    }

    static func extractSquares(_ input: String) -> [Int] {
        let files: [String:String] = [
            "а":"a", "эй":"a", "a":"a", "б":"b", "бэ":"b", "бе":"b", "би":"b", "b":"b",
            "ц":"c", "цэ":"c", "це":"c", "с":"c", "си":"c", "c":"c",
            "д":"d", "дэ":"d", "де":"d", "ди":"d", "d":"d", "е":"e", "э":"e", "e":"e",
            "ф":"f", "эф":"f", "эфь":"f", "f":"f", "г":"g", "ж":"g", "жэ":"g", "же":"g", "джи":"g", "гэ":"g", "g":"g",
            "х":"h", "аш":"h", "эйч":"h", "h":"h"
        ]
        let ranks: [String:String] = ["один":"1", "раз":"1", "два":"2", "две":"2", "три":"3", "четыре":"4", "пять":"5", "шесть":"6", "семь":"7", "восемь":"8"]
        // Split letter/number boundaries, retaining adjacent coordinates such as e2e4.
        var expanded = input.replacingOccurrences(of: "([a-zа-я])([1-8])", with: "$1 $2", options: .regularExpression)
        expanded = expanded.replacingOccurrences(of: "([1-8])([a-zа-я])", with: "$1 $2", options: .regularExpression)
        let tokens = expanded.components(separatedBy: CharacterSet.alphanumerics.inverted).filter { !$0.isEmpty }
        guard tokens.count >= 2 else { return [] }
        var result = [Int]()
        for index in 0..<(tokens.count - 1) {
            guard let file = files[tokens[index]] else { continue }
            let rank = ranks[tokens[index+1]] ?? tokens[index+1]
            if let square = squareIndex(file + rank) { result.append(square) }
        }
        return result
    }
}
