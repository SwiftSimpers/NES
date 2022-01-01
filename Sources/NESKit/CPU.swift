struct CPU6502 {
    enum RegisterKeys: String {
        case A, X, Y, S, P
    }

    var registers: [RegisterKeys: UInt8] = [:]
    var PC: UInt16 = 0

    /**
     Gets register by register key.
     - parameters:
        - register: Register key you want to get the value.
     - returns: Register value matches with the key.
     */
    subscript(register: RegisterKeys) -> UInt8 {
        get {
            return registers[register] ?? 0
        }
        set(value) {
            registers[register] = value
        }
    }

    /**
     Resets all the registers.
     */
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

    /**
     Interprets the program passed by the argument.
     Check the P register to check the status of CPU.
     - parameters:
        - program: Program code in 6502 machine language.
     */
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
                return
            case 0xa9:
                // LDA #$nn (immediate)
                let param = program[Int(PC)]
                PC += 1
                self[.A] = param

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

