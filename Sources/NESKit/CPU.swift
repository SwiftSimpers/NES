struct CPU6502 {
    enum RegisterKeys: String {
        case A, X, Y, S, P
    }

    var registers: [RegisterKeys: UInt8] = [:]
    private var _PC: UInt16 = 0
    var PC: UInt16 {
        get {
            return _PC
        }
        set(value) {
            if value > UInt16.max {
                _PC = value - UInt16.max
            } else {
                _PC = value
            }
        }
    }

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
            if value > UInt8.max {
                registers[register] = value - UInt8.max
            } else {
                registers[register] = value
            }
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
     Replaces register A to the parameter value.
     - parameters:
        - value: The 8 bit replacement value.
     - returns: The replacement value.
     */
    public mutating func LDA(value: UInt8) -> UInt8 {
        self[.A] = value
        return self[.A]
    }
    
    /**
     Replaces register X to register A value.
     - returns: The replacement(register A) value.
     */
    public mutating func TAX() -> UInt8 {
        self[.X] = self[.A]
        return self[.X]
    }
    
    /**
     Increaces register X value by 1.
     - returns: The increased register X value.
     */
    public mutating func INX() -> UInt8 {
        self[.X] &+= 1
        return self[.X]
    }
    
    /**
     Updates the status register based on the result.
     - parameters:
        - result: Result value of the execution.
     */
    public mutating func updateStatus(result: UInt8) {
        if result == 0x00 {
            self[.P] |= 0b0000_0010
        } else {
            self[.P] &= 0b1111_1101
        }

        if result & 0x80 != 0 {
            self[.P] |= 0b1000_0000
        } else {
            self[.P] &= 0b0111_1111
        }
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
            PC &+= 1

            switch opcode {
            case 0x00:
                // BRK
                return
            case 0xa9:
                // LDA #$nn (immediate)
                let param = program[Int(PC)]
                PC += 1
                let result = LDA(value: param)
                updateStatus(result: result)
            case 0xaa:
                let result = TAX()
                updateStatus(result: result)
            case 0xe8:
                let result = INX()
                updateStatus(result: result)
            default:
                // TODO: implement opcodes
                break
            }
        }
    }
}
