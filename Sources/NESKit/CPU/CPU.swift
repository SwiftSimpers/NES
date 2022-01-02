struct CPU6502 {
    enum RegisterKeys: String {
        case A, X, Y, S, P
    }

    internal var registers: [RegisterKeys: UInt8] = [:]
    internal var allocs: [UInt8] = Array(repeating: 0, count:0xffff)
    private var _PC: UInt16 = 0
    // Separated since PC needs 16 bits.
    /// Program counter register.
    public var PC: UInt16 {
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
        PC = readAllocU16(index: 0xFFFC)
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
     Executes the program allocated on CPU's allocations.
     Check the P register to check the status of CPU.
     */
    public mutating func run() {
        reset()
        while true {
            let opcode = self[Int(PC)]
            PC &+= 1

            switch opcode {
            case 0x00:
                // BRK
                return
            case 0xa9:
                // LDA #$nn (immediate)
                let param = self[Int(PC)]
                PC &+= 1
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
    
    /**
     Allocates the program into CPU and executes the program.
     - parameters:
        - program: Program code in 6502 machine language.
     */
    public mutating func loadAndRun(program: [UInt8]) {
        self.load(program: program)
        self.run()
    }
}
