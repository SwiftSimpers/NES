enum InstructionArgument {
    /// Basically #UInt8
    case immediate(Int)
    /// Basically (UInt16)
    case indirect(Int)
    /// Basically (UInt16, X/Y)
    case indirectVec(Int, Register)
    /// Basically UInt16
    case abs(Int)
    /// Basically UInt16, X/Y
    case absVec(Int, Register)
    /// Basically #(UInt8)
    case zero(Int)
    /// Basically #(UInt8, X/Y)
    case zeroVec(Int, Register)
    /// Basically UInt8 but only used for branch instructions
    case relative(Int)
    /// Basically A (register)
    case accumulator
    /// Label (for offsets). We can say this is just `absolute` but
    /// except for the fact that it is replaced by absolute values
    /// when emitting the code.
    case label(String)
}

extension InstructionArgument {
    var size: Int {
        switch self {
        case .abs, .indirect, .indirectVec, .absVec, .label:
            return 2
        case .immediate, .relative, .zero, .zeroVec:
            return 1
        case .accumulator:
            return 0
        }
    }
}

let instructionTakeingArg = [
    "LDA",
    "STA",
    "STX",
    "STY",
    "ADC",
    "SBC",
    "AND",
    "ASL",
    "BIT",
    "CMP",
    "CPX",
    "CPY",
    "DEC",
    "EOR",
    "INC",
    "JMP",
    "LDX",
    "LDY",
    "LSR",
    "ORA",
    "ROL",
    "ROR",
    "BCC",
    "BCS",
    "BEQ",
    "BMI",
    "BNE",
    "BPL",
    "BVC",
    "BVS",
    "JSR",
]

let branchInstructions = [
    "BCC",
    "BCS",
    "BEQ",
    "BMI",
    "BNE",
    "BPL",
    "BVC",
    "BVS",
]

struct Instruction {
    let offset: Int
    let name: String
    let arg: InstructionArgument?
    let span: Span

    var size: Int {
        return 1 + (arg?.size ?? 0)
    }
}

enum Node {
    case label(String, Int)
    case instruction(Instruction)
}

enum AssemblerError: Error {
    case unexpectedToken(Token, String)
    case unexpectedEof(String)
    case unexpectedOperator(String)
    case duplicateLabel(String, Position)
    case expectedOperator(String, Token?)
}

public extension Assembler6502 {
    mutating func resetAST() {
        nodes = []
        labels = [:]
        index = 0
        instructionOffset = 0
    }

    mutating func nextAST() -> Token? {
        var token: Token?
        while index < tokens.count, token == nil {
            index += 1
            switch tokens[index - 1].type {
            case .comment:
                break
            default:
                token = tokens[index - 1]
                span.end = token!.span.end
            }
        }
        return token
    }

    func peekAST() -> Token? {
        if index < tokens.count {
            return tokens[index]
        }
        return nil
    }

    mutating func parseInstructionArgument(isBranch: Bool = false) throws -> InstructionArgument {
        guard let token = nextAST() else {
            throw AssemblerError.unexpectedEof("Expected instruction argument")
        }

        switch token.type {
        case .identifier("A"), .identifier("a"):
            return .accumulator
        case let .identifier(label):
            return .label(label)
        case let .operator(op):
            switch op {
            // We will try to match either `#UInt8`, `#(UInt8)` or `#(UInt8, X/Y)`
            case "#":
                guard let token = nextAST() else {
                    throw AssemblerError.unexpectedEof("Expected immediate value")
                }

                switch token.type {
                // If next token is number, then it's `#UInt8` (immediate)
                case let .number(value):
                    return .immediate(value)

                // If next token is `(`, then it's `#(UInt8)` or `#(UInt8, X/Y)`
                case .operator("("):
                    guard let token = nextAST() else {
                        throw AssemblerError.unexpectedEof("Expected immediate value")
                    }

                    guard case let .number(value) = token.type else {
                        throw AssemblerError.unexpectedToken(token, "Expected number")
                    }

                    guard let token = nextAST() else {
                        throw AssemblerError.unexpectedEof("Expected ')', or ','")
                    }

                    switch token.type {
                    // If next token is `)`, then it's just `#(UInt8)`
                    case .operator(")"):
                        return .zero(value)

                    // Otherwise, it can only be `,` indicating that there's a register next
                    // which will result in `#(UInt8, X/Y)`
                    case .operator(","):
                        guard let token = nextAST() else {
                            throw AssemblerError.unexpectedEof("Expected register")
                        }

                        guard case let .identifier(regName) = token.type else {
                            throw AssemblerError.unexpectedToken(token, "Expected register")
                        }

                        var reg: Register
                        switch regName {
                        case "X", "x":
                            reg = .X
                        case "Y", "y":
                            reg = .Y
                        default:
                            throw AssemblerError.unexpectedOperator("Expected X or Y vector register")
                        }

                        guard let token = nextAST() else {
                            throw AssemblerError.unexpectedEof("Expected ')'")
                        }

                        guard case .operator(")") = token.type else {
                            throw AssemblerError.unexpectedToken(token, "Expected ')' operator")
                        }

                        return .zeroVec(value, reg)

                    default:
                        throw AssemblerError.unexpectedToken(token, "Expected ',' or ')' operator")
                    }

                default:
                    throw AssemblerError.unexpectedToken(token, "Expected number or '(' operator")
                }

            // We will try to match either `(UInt16)` or `(UInt16, X/Y)`
            case "(":
                guard let token = nextAST() else {
                    throw AssemblerError.unexpectedEof("Expected immediate value")
                }

                guard case let .number(value) = token.type else {
                    throw AssemblerError.unexpectedToken(token, "Expected number")
                }

                guard let token = nextAST() else {
                    throw AssemblerError.unexpectedEof("Expected ')', or ','")
                }

                switch token.type {
                // If next token is `)`, then it's just `(UInt16)`
                case .operator(")"):
                    return .indirect(value)

                // Otherwise, it can only be `,` indicating that there's a register next
                // which will result in `(UInt16, X/Y)`
                case .operator(","):
                    guard let token = nextAST() else {
                        throw AssemblerError.unexpectedEof("Expected register")
                    }

                    guard case let .identifier(regName) = token.type else {
                        throw AssemblerError.unexpectedToken(token, "Expected register")
                    }

                    var reg: Register
                    switch regName {
                    case "X", "x":
                        reg = .X
                    case "Y", "y":
                        reg = .Y
                    default:
                        throw AssemblerError.unexpectedOperator("Expected X or Y vector register")
                    }

                    guard let token = nextAST() else {
                        throw AssemblerError.unexpectedEof("Expected ')'")
                    }

                    guard case .operator(")") = token.type else {
                        throw AssemblerError.unexpectedToken(token, "Expected ')' operator")
                    }

                    return .indirectVec(value, reg)

                default:
                    throw AssemblerError.unexpectedToken(token, "Expected ',' or ')' operator")
                }
            default:
                throw AssemblerError.unexpectedOperator(op)
            }

        // We will try to match either `UInt16`, `UInt16, X/Y`, or `UInt8`
        case let .number(value):
            if let nextToken = peekAST() {
                // If next token is ',' then it's `UInt16, X/Y`
                if nextToken.type == .operator(",") {
                    _ = nextAST()
                    guard let token = nextAST() else {
                        throw AssemblerError.unexpectedEof("Expected zero page register")
                    }
                    guard case let .identifier(register) = token.type else {
                        throw AssemblerError.unexpectedToken(token, "Expected zero page register")
                    }
                    guard ["X", "Y"].contains(register) else {
                        throw AssemblerError.unexpectedOperator("\(register)")
                    }
                    return .absVec(value, Register(rawValue: register)!)
                }
            }
            // If the instruction is branch related, then it's `UInt8`,
            // otherwise it's `UInt16`
            return isBranch ? .relative(value) : .abs(value)
        default:
            throw AssemblerError.unexpectedToken(token, "Expected operator or number")
        }
    }

    mutating func parseInstruction(name: String) throws {
        var arg: InstructionArgument?
        if instructionTakeingArg.contains(name) {
            arg = try parseInstructionArgument(isBranch: branchInstructions.contains(name))
        }
        let instruction = Instruction(offset: instructionOffset, name: name, arg: arg, span: span)
        instructionOffset += instruction.size
        let node = Node.instruction(instruction)
        nodes.append(node)
    }

    mutating func parseLabel(name: String) throws {
        let next = nextAST()
        guard case .operator(":") = next?.type else {
            throw AssemblerError.expectedOperator("Expected ':' (at position: \(position))", next)
        }
        if labels.contains(where: { $0.key == name }) {
            throw AssemblerError.duplicateLabel(name, position)
        }
        labels[name] = instructionOffset
        let node = Node.label(name, instructionOffset)
        nodes.append(node)
    }

    mutating func parseASTNext() throws {
        guard let token = nextAST() else {
            return
        }
        span.start = token.span.start

        switch token.type {
        case let .instruction(name):
            try parseInstruction(name: name)

        case let .identifier(name):
            try parseLabel(name: name)

        case .comment:
            // Ignore comments for now
            break

        default:
            throw AssemblerError.unexpectedToken(token, "Expected label or instruction")
        }

        try parseASTNext()
    }

    mutating func parse() throws {
        resetAST()
        try parseASTNext()
    }
}
