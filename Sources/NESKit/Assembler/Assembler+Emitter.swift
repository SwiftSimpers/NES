import Foundation

enum EmitterError: Error {
    case invalidInstruction(Instruction)
    case unexpectedArgument(Instruction)
    case expectedArgument(String)
    case labelNotFound(String)
}

extension Assembler6502 {
    mutating func resetEmitter() {
        // The last added instruction also pushes its size onto offset,
        // causing it to become the size of the assembled code.
        assembly = Data(count: instructionOffset)
        // Then we'll re-use the instructionOffset variable to keep track of
        // the current offset in the assembled code.
        instructionOffset = 0
    }

    mutating func write(_ byte: UInt8) {
        assembly![instructionOffset] = byte
        instructionOffset += 1
    }

    mutating func write(_ word: UInt16) {
        write(UInt8(word & 0xFF))
        write(UInt8(word >> 8))
    }

    static func << (prefix: inout Assembler6502, postfix: Int) {
        prefix.write(UInt8(postfix))
    }

    static func << (prefix: inout Assembler6502, postfix: UInt8) {
        prefix.write(postfix)
    }

    static func << (prefix: inout Assembler6502, postfix: UInt16) {
        prefix.write(postfix)
    }

    static func << (prefix: inout Assembler6502, postfix: InstructionArgument) throws {
        try prefix.writeAddress(postfix)
    }

    mutating func writeAddress(_ argument: InstructionArgument) throws {
        switch argument {
        case let .immediate(value), let .zero(value), let .zeroVec(value, _), let .relative(value):
            self << UInt8(value)
        case let .indirect(value), let .indirectVec(value, _), let .abs(value), let .absVec(value, _):
            self << UInt16(value)
        case let .label(name):
            guard let value = labels[name] else {
                throw EmitterError.labelNotFound(name)
            }
            self << (ProgramOffset + UInt16(value))
        case .accumulator:
            break
        }
    }

    mutating func emit(inst: Instruction) throws {
        switch inst.name {
        case "ADC":
            guard let arg = inst.arg else {
                throw EmitterError.expectedArgument(inst.name)
            }
            switch arg {
            case .immediate:
                self << 0x69
            case .zero:
                self << 0x65
            case .zeroVec(_, .X):
                self << 0x75
            case .indirectVec(_, .X):
                self << 0x61
            case .indirectVec(_, .Y):
                self << 0x71
            case .abs:
                self << 0x6D
            case .absVec(_, .X):
                self << 0x7D
            case .absVec(_, .Y):
                self << 0x79
            default:
                throw EmitterError.unexpectedArgument(inst)
            }
            try self << arg

        case "AND":
            guard let arg = inst.arg else {
                throw EmitterError.expectedArgument(inst.name)
            }
            switch arg {
            case .immediate:
                self << 0x29
            case .zero:
                self << 0x25
            case .zeroVec(_, .X):
                self << 0x35
            case .indirectVec(_, .X):
                self << 0x21
            case .indirectVec(_, .Y):
                self << 0x31
            case .abs:
                self << 0x2D
            case .absVec(_, .X):
                self << 0x3D
            case .absVec(_, .Y):
                self << 0x39
            default:
                throw EmitterError.unexpectedArgument(inst)
            }
            try self << arg

        case "ASL":
            guard let arg = inst.arg else {
                throw EmitterError.expectedArgument(inst.name)
            }
            switch arg {
            case .accumulator:
                self << 0x0A
            case .zero:
                self << 0x06
            case .zeroVec(_, .X):
                self << 0x16
            case .abs:
                self << 0x0E
            case .absVec(_, .X):
                self << 0x1E
            default:
                throw EmitterError.unexpectedArgument(inst)
            }
            try self << arg

        case "BIT":
            guard let arg = inst.arg else {
                throw EmitterError.expectedArgument(inst.name)
            }
            switch arg {
            case .zero:
                self << 0x24
            case .abs:
                self << 0x2C
            default:
                throw EmitterError.unexpectedArgument(inst)
            }
            try self << arg

        case "BPL":
            guard let arg = inst.arg else {
                throw EmitterError.expectedArgument(inst.name)
            }
            switch arg {
            case .relative:
                self << 0x10
                try self << arg
            case let .label(name):
                guard let value = labels[name] else {
                    throw EmitterError.labelNotFound(name)
                }
                self << 0x10
                self << (value - instructionOffset - 2)
            default:
                throw EmitterError.unexpectedArgument(inst)
            }

        case "BMI":
            guard let arg = inst.arg else {
                throw EmitterError.expectedArgument(inst.name)
            }
            switch arg {
            case .relative:
                self << 0x30
                try self << arg
            case let .label(name):
                guard let value = labels[name] else {
                    throw EmitterError.labelNotFound(name)
                }
                self << 0x30
                self << (value - instructionOffset - 2)
            default:
                throw EmitterError.unexpectedArgument(inst)
            }

        case "BVC":
            guard let arg = inst.arg else {
                throw EmitterError.expectedArgument(inst.name)
            }
            switch arg {
            case .relative:
                self << 0x50
                try self << arg
            case let .label(name):
                guard let value = labels[name] else {
                    throw EmitterError.labelNotFound(name)
                }
                self << 0x50
                self << (value - instructionOffset - 2)
            default:
                throw EmitterError.unexpectedArgument(inst)
            }

        case "BVS":
            guard let arg = inst.arg else {
                throw EmitterError.expectedArgument(inst.name)
            }
            switch arg {
            case .relative:
                self << 0x70
                try self << arg
            case let .label(name):
                guard let value = labels[name] else {
                    throw EmitterError.labelNotFound(name)
                }
                self << 0x70
                self << (value - instructionOffset - 2)
            default:
                throw EmitterError.unexpectedArgument(inst)
            }

        case "BCC":
            guard let arg = inst.arg else {
                throw EmitterError.expectedArgument(inst.name)
            }
            switch arg {
            case .relative:
                self << 0x90
                try self << arg
            case let .label(name):
                guard let value = labels[name] else {
                    throw EmitterError.labelNotFound(name)
                }
                self << 0x90
                self << (value - instructionOffset - 2)
            default:
                throw EmitterError.unexpectedArgument(inst)
            }

        case "BCS":
            guard let arg = inst.arg else {
                throw EmitterError.expectedArgument(inst.name)
            }
            switch arg {
            case .relative:
                self << 0xB0
                try self << arg
            case let .label(name):
                guard let value = labels[name] else {
                    throw EmitterError.labelNotFound(name)
                }
                self << 0xB0
                self << (value - instructionOffset - 2)
            default:
                throw EmitterError.unexpectedArgument(inst)
            }

        case "BNE":
            guard let arg = inst.arg else {
                throw EmitterError.expectedArgument(inst.name)
            }
            switch arg {
            case .relative:
                self << 0xD0
                try self << arg
            case let .label(name):
                guard let value = labels[name] else {
                    throw EmitterError.labelNotFound(name)
                }
                self << 0xD0
                self << (value - instructionOffset - 2)
            default:
                throw EmitterError.unexpectedArgument(inst)
            }

        case "BEQ":
            guard let arg = inst.arg else {
                throw EmitterError.expectedArgument(inst.name)
            }
            switch arg {
            case .relative:
                self << 0xF0
                try self << arg
            case let .label(name):
                guard let value = labels[name] else {
                    throw EmitterError.labelNotFound(name)
                }
                self << 0xF0
                self << (value - instructionOffset - 2)
            default:
                throw EmitterError.unexpectedArgument(inst)
            }

        case "BRK":
            self << 0x00

        case "CMP":
            guard let arg = inst.arg else {
                throw EmitterError.expectedArgument(inst.name)
            }
            switch arg {
            case .immediate:
                self << 0xC9
            case .zero:
                self << 0xC5
            case .zeroVec(_, .X):
                self << 0xD5
            case .indirectVec(_, .X):
                self << 0xC1
            case .indirectVec(_, .Y):
                self << 0xD1
            case .abs:
                self << 0xCD
            case .absVec(_, .X):
                self << 0xDD
            case .absVec(_, .Y):
                self << 0xD9
            default:
                throw EmitterError.unexpectedArgument(inst)
            }
            try self << arg

        case "CPX":
            guard let arg = inst.arg else {
                throw EmitterError.expectedArgument(inst.name)
            }
            switch arg {
            case .immediate:
                self << 0xE0
            case .zero:
                self << 0xE4
            case .abs:
                self << 0xEC
            default:
                throw EmitterError.unexpectedArgument(inst)
            }
            try self << arg

        case "CPY":
            guard let arg = inst.arg else {
                throw EmitterError.expectedArgument(inst.name)
            }
            switch arg {
            case .immediate:
                self << 0xC0
            case .zero:
                self << 0xC4
            case .abs:
                self << 0xCC
            default:
                throw EmitterError.unexpectedArgument(inst)
            }
            try self << arg

        case "DEC":
            guard let arg = inst.arg else {
                throw EmitterError.expectedArgument(inst.name)
            }
            switch arg {
            case .zero:
                self << 0xC6
            case .zeroVec(_, .X):
                self << 0xD6
            case .abs:
                self << 0xCE
            case .absVec(_, .X):
                self << 0xDE
            default:
                throw EmitterError.unexpectedArgument(inst)
            }
            try self << arg

        case "EOR":
            guard let arg = inst.arg else {
                throw EmitterError.expectedArgument(inst.name)
            }
            switch arg {
            case .immediate:
                self << 0x49
            case .zero:
                self << 0x45
            case .zeroVec(_, .X):
                self << 0x55
            case .indirectVec(_, .X):
                self << 0x41
            case .indirectVec(_, .Y):
                self << 0x51
            case .abs:
                self << 0x4D
            case .absVec(_, .X):
                self << 0x5D
            case .absVec(_, .Y):
                self << 0x59
            default:
                throw EmitterError.unexpectedArgument(inst)
            }
            try self << arg

        case "CLC":
            self << 0x18
        case "SEC":
            self << 0x38
        case "CLI":
            self << 0x58
        case "SEI":
            self << 0x78
        case "CLV":
            self << 0xB8

        case "INC":
            guard let arg = inst.arg else {
                throw EmitterError.expectedArgument(inst.name)
            }
            switch arg {
            case .zero:
                self << 0xE6
            case .zeroVec(_, .X):
                self << 0xF6
            case .abs:
                self << 0xEE
            case .absVec(_, .X):
                self << 0xFE
            default:
                throw EmitterError.unexpectedArgument(inst)
            }
            try self << arg

        case "JMP":
            guard let arg = inst.arg else {
                throw EmitterError.expectedArgument(inst.name)
            }
            switch arg {
            case .abs, .label:
                self << 0x4C
            case .indirect:
                self << 0x6C
            default:
                throw EmitterError.unexpectedArgument(inst)
            }
            try self << arg
        case "JSR":
            guard let arg = inst.arg else {
                throw EmitterError.expectedArgument(inst.name)
            }
            switch arg {
            case .abs, .label:
                self << 0x20
            default:
                throw EmitterError.unexpectedArgument(inst)
            }
            try self << arg

        case "LDA":
            guard let arg = inst.arg else {
                throw EmitterError.expectedArgument(inst.name)
            }
            switch arg {
            case .immediate:
                self << 0xA9
            case .zero:
                self << 0xA5
            case .zeroVec(_, .X):
                self << 0xB5
            case .indirectVec(_, .X):
                self << 0xA1
            case .indirectVec(_, .Y):
                self << 0xB1
            case .abs:
                self << 0xAD
            case .absVec(_, .X):
                self << 0xBD
            case .absVec(_, .Y):
                self << 0xB9
            default:
                throw EmitterError.unexpectedArgument(inst)
            }
            try self << arg
        case "LDX":
            guard let arg = inst.arg else {
                throw EmitterError.expectedArgument(inst.name)
            }
            switch arg {
            case .immediate:
                self << 0xA2
            case .zero:
                self << 0xA6
            case .zeroVec(_, .Y):
                self << 0xB6
            case .abs:
                self << 0xAE
            case .absVec(_, .Y):
                self << 0xBE
            default:
                throw EmitterError.unexpectedArgument(inst)
            }
            try self << arg
        case "LDY":
            guard let arg = inst.arg else {
                throw EmitterError.expectedArgument(inst.name)
            }
            switch arg {
            case .immediate:
                self << 0xA0
            case .zero:
                self << 0xA4
            case .zeroVec(_, .X):
                self << 0xB4
            case .abs:
                self << 0xAC
            case .absVec(_, .X):
                self << 0xBC
            default:
                throw EmitterError.unexpectedArgument(inst)
            }
            try self << arg

        case "LSR":
            guard let arg = inst.arg else {
                throw EmitterError.expectedArgument(inst.name)
            }
            switch arg {
            case .accumulator:
                self << 0x4A
            case .zero:
                self << 0x46
            case .zeroVec(_, .X):
                self << 0x56
            case .abs:
                self << 0x4E
            case .absVec(_, .X):
                self << 0x5E
            default:
                throw EmitterError.unexpectedArgument(inst)
            }
            try self << arg

        case "NOP":
            self << 0xEA

        case "ORA":
            guard let arg = inst.arg else {
                throw EmitterError.expectedArgument(inst.name)
            }
            switch arg {
            case .immediate:
                self << 0x09
            case .zero:
                self << 0x05
            case .zeroVec(_, .X):
                self << 0x15
            case .indirectVec(_, .X):
                self << 0x01
            case .indirectVec(_, .Y):
                self << 0x11
            case .abs:
                self << 0x0D
            case .absVec(_, .X):
                self << 0x1D
            case .absVec(_, .Y):
                self << 0x19
            default:
                throw EmitterError.unexpectedArgument(inst)
            }
            try self << arg

        case "TAX":
            self << 0xAA
        case "TAY":
            self << 0xA8
        case "TXA":
            self << 0x8A
        case "TYA":
            self << 0x98
        case "INX":
            self << 0xE8
        case "INY":
            self << 0xC8
        case "DEX":
            self << 0xCA
        case "DEY":
            self << 0x88

        case "ROL":
            guard let arg = inst.arg else {
                throw EmitterError.expectedArgument(inst.name)
            }
            switch arg {
            case .accumulator:
                self << 0x2A
            case .zero:
                self << 0x26
            case .zeroVec(_, .X):
                self << 0x36
            case .abs:
                self << 0x2E
            case .absVec(_, .X):
                self << 0x3E
            default:
                throw EmitterError.unexpectedArgument(inst)
            }
            try self << arg
        case "ROR":
            guard let arg = inst.arg else {
                throw EmitterError.expectedArgument(inst.name)
            }
            switch arg {
            case .accumulator:
                self << 0x6A
            case .zero:
                self << 0x66
            case .zeroVec(_, .X):
                self << 0x76
            case .abs:
                self << 0x6E
            case .absVec(_, .X):
                self << 0x7E
            default:
                throw EmitterError.unexpectedArgument(inst)
            }
            try self << arg

        case "RTI":
            self << 0x40
        case "RTS":
            self << 0x60

        case "SBC":
            guard let arg = inst.arg else {
                throw EmitterError.expectedArgument(inst.name)
            }
            switch arg {
            case .immediate:
                self << 0xE9
            case .zero:
                self << 0xE5
            case .zeroVec(_, .X):
                self << 0xF5
            case .indirectVec(_, .X):
                self << 0xE1
            case .indirectVec(_, .Y):
                self << 0xF1
            case .abs:
                self << 0xED
            case .absVec(_, .X):
                self << 0xFD
            case .absVec(_, .Y):
                self << 0xF9
            default:
                throw EmitterError.unexpectedArgument(inst)
            }
            try self << arg

        case "STA":
            guard let arg = inst.arg else {
                throw EmitterError.expectedArgument(inst.name)
            }
            switch arg {
            case .zero:
                self << 0x85
            case .zeroVec(_, .X):
                self << 0x95
            case .indirectVec(_, .X):
                self << 0x81
            case .indirectVec(_, .Y):
                self << 0x91
            case .abs:
                self << 0x8D
            case .absVec(_, .X):
                self << 0x9D
            case .absVec(_, .Y):
                self << 0x99
            default:
                throw EmitterError.unexpectedArgument(inst)
            }
            try self << arg

        case "TXS":
            self << 0x9A
        case "TSX":
            self << 0xBA
        case "PHA":
            self << 0x48
        case "PLA":
            self << 0x68
        case "PHP":
            self << 0x08
        case "PLP":
            self << 0x28

        case "STX":
            guard let arg = inst.arg else {
                throw EmitterError.expectedArgument(inst.name)
            }
            switch arg {
            case .zero:
                self << 0x86
            case .zeroVec(_, .Y):
                self << 0x96
            case .abs:
                self << 0x8E
            default:
                throw EmitterError.unexpectedArgument(inst)
            }
            try self << arg
        case "STY":
            guard let arg = inst.arg else {
                throw EmitterError.expectedArgument(inst.name)
            }
            switch arg {
            case .zero:
                self << 0x84
            case .zeroVec(_, .X):
                self << 0x94
            case .abs:
                self << 0x8C
            default:
                throw EmitterError.unexpectedArgument(inst)
            }
            try self << arg

        default:
            throw EmitterError.invalidInstruction(inst)
        }
    }

    public mutating func assemble() throws {
        resetEmitter()
        for node in nodes {
            switch node {
            case .label:
                break
            case let .instruction(instruction):
                try emit(inst: instruction)
            }
        }
    }
}
