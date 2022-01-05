let instructions: [String] = [
    "TAX",
    "TXA",
    "DEX",
    "INX",
    "TAY",
    "TYA",
    "DEY",
    "INY",
    "TSX",
    "TXS",
    "PHA",
    "PLA",
    "PHP",
    "PLP",
    "JMP",
    "JSR",
    "RTS",
    "RTI",
    "BRK",
    "BPL",
    "BMI",
    "BVC",
    "BVS",
    "BCC",
    "BCS",
    "BNE",
    "BEQ",
    "CLC",
    "SEC",
    "CLI",
    "SEI",
    "CLV",
    "EOR",
    "AND",
    "ORA",
    "ADC",
    "SBC",
    "BIT",
    "CMP",
    "CPX",
    "CPY",
    "DEC",
    "INC",
    "ASL",
    "LSR",
    "ROL",
    "ROR",
    "STA",
    "STX",
    "STY",
    "LDA",
    "LDX",
    "LDY",
]

struct Position {
    var line: Int
    var column: Int
}

struct Span {
    var start: Position
    var end: Position
}

enum TokenType: Equatable {
    case instruction(String)
    case identifier(String)
    case comment(String)
    case number(Int)
    case `operator`(String)
}

struct Token {
    var type: TokenType
    var span: Span
}

enum LexerError: Error {
    case unexpectedEof
    case unexpectedCharacter(Position, Character)
}

extension String {
    subscript(index: Int) -> Character {
        get {
            return self[self.index(startIndex, offsetBy: index)]
        }
        set(value) {
            replaceSubrange(self.index(startIndex, offsetBy: index) ..< self.index(startIndex, offsetBy: index + 1), with: String(value))
        }
    }
}

extension Assembler6502 {
    mutating func resetLexer() {
        index = 0
        position = Position(line: 1, column: 1)
        source = ""
        tokens = []
    }

    mutating func nextLexer() -> Character? {
        guard index < source.count else {
            return nil
        }
        let char = source[index]
        index += 1
        position.column += 1
        if char == "\n" {
            position.line += 1
            position.column = 1
        }
        span.end = position
        return char
    }

    func peekLexer(offset: Int = 0) -> Character? {
        guard (index + offset) < source.count else {
            return nil
        }
        return source[index + offset]
    }

    mutating func parseComment() throws {
        guard let nextChar = peekLexer() else {
            throw LexerError.unexpectedEof
        }

        switch nextChar {
        case "/":
            try parseComment(multiline: false)
        case "*":
            try parseComment(multiline: true)
        default:
            throw LexerError.unexpectedCharacter(position, nextChar)
        }
    }

    mutating func parseComment(multiline: Bool) throws {
        var comment = "/"
        while let char = nextLexer() {
            if char == "\n" {
                if multiline {
                    comment += "\n"
                } else {
                    tokens.append(Token(type: .comment(comment), span: span))
                    return
                }
            } else if char == "*", peekLexer() == "/" {
                comment += "*"
                comment += String(nextLexer()!)
                tokens.append(Token(type: .comment(comment), span: span))
                return
            } else {
                comment += String(char)
            }
        }
        if !comment.isEmpty {
            tokens.append(Token(type: .comment(comment), span: span))
        }
    }

    mutating func parseIdentifier(char: Character) throws {
        var identifier = String(char)
        while let nextChar = peekLexer(), nextChar.isLetter || nextChar.isNumber || nextChar == "_" {
            identifier += String(nextChar)
            _ = nextLexer()
        }
        if instructions.contains(identifier.uppercased()) {
            tokens.append(Token(type: .instruction(identifier.uppercased()), span: span))
        } else {
            tokens.append(Token(type: .identifier(identifier), span: span))
        }
    }

    mutating func parseNumber(char: Character) throws {
        var number = String(char)
        var radix = 10
        loop: while let nextChar = peekLexer() {
            switch nextChar {
            case "0" ... "9":
                number += String(nextChar)
                _ = nextLexer()

            case "x", "o", "b":
                if number.count != 1 || number != "0" {
                    throw LexerError.unexpectedCharacter(position, nextChar)
                } else {
                    number = ""
                    radix = nextChar == "x" ? 16 : nextChar == "o" ? 8 : 2
                    _ = nextLexer()
                }

            default:
                break loop
            }
        }
        tokens.append(Token(type: .number(Int(number, radix: radix)!), span: span))
    }

    mutating func parseOperator(char: Character) throws {
        tokens.append(Token(type: .operator(String(char)), span: span))
    }

    mutating func parseNext() throws {
        span.start = position
        guard let char = nextLexer() else {
            return
        }

        switch char {
        case "/":
            try parseComment()

        case "A" ... "Z", "a" ... "z", "_":
            try parseIdentifier(char: char)

        case "0" ... "9":
            try parseNumber(char: char)

        case "\r", "\n", " ", "\t":
            break

        case "(", ")", "#", ",", ":":
            try parseOperator(char: char)

        default:
            throw LexerError.unexpectedCharacter(position, char)
        }

        try parseNext()
    }

    mutating func lex(source: String) throws {
        resetLexer()
        self.source = source
        try parseNext()
    }
}
