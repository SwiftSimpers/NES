struct CPU6502 {
    enum RegisterKeys: String {
        case A, X, Y, S, P
    }

    var registers: [RegisterKeys: UInt8] = [:]
    var PC: UInt16 = 0

    subscript(register: RegisterKeys) -> UInt8 {
        get {
            return registers[register] ?? 0
            // helloyunho
            // i gtg
            // wait what
            // hmm wut
            // git push it
            // okay
            // where
            // swiftsimpers
        }
        set(value) {
            registers[register] = value
        }
    }

    public mutating func reset() {
        registers = [
            .A: 0,
            .X: 0,
            .Y: 0,
            .S: 0,
            .P: 0,
        ]
        PC = 0
    }

    public mutating func interpret(program: [UInt8]) {
        reset()
        while true {
            let opcode = program[Int(PC)]
            PC += 1

            switch opcode {
            case 0x00:
                // BRK
                break
            case 0xA9:
                // LDA #$nn (immediate)
                let param = program[Int(PC)]
                PC += 1
                self[.A] = param
                // does swift have match statements?
                // nope
                // switch case looks ugly
                // hmm i mean this is the most beautiful statement for this in swift
                // hmmm
                // also forgor to change spacing

                if param == 0x00 {
                    self[.P] |= 0x20
                } else {
                    self[.P] &= 0xDF
                }

                if param < 0x80 {
                    self[.P] |= 0x80
                } else {
                    self[.P] &= 0x7F
                }

            default:
                // TODO: implement opcodes
                break
            }
        }
    }
}

