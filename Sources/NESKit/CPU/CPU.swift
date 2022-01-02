struct CPU6502 {
    enum RegisterKeys: String {
        case A, X, Y, S, P
    }

    internal var registers: [RegisterKeys: UInt8] = [:]
    internal var allocs: [UInt8] = Array(repeating: 0, count: 0xffff)
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

    internal mutating func getAddress(mode: AddressingModes) -> UInt16 {
        switch mode {
        case .immidiate:
            PC &+= 1
            return PC &- 1
        case .zero:
            PC &+= 1
            return UInt16(self[PC &- 1])
        case .zeroX:
            PC &+= 1
            return UInt16(self[PC &- 1] &+ self[.X])
        case .zeroY:
            PC &+= 1
            return UInt16(self[PC &- 1] &+ self[.Y])
        case .abs:
            PC &+= 2
            return readAllocU16(index: PC &- 2)
        case .absX:
            PC &+= 2
            return readAllocU16(index: PC &- 2) &+ UInt16(self[.X])
        case .absY:
            PC &+= 2
            return readAllocU16(index: PC &- 2) &+ UInt16(self[.Y])
        case .indirectX:
            PC &+= 1
            let base = self[PC &- 1]
            let pointer = base &+ self[.X]
            let bytes = [self[UInt16(pointer)], self[UInt16(pointer &+ 1)]]
            return bytes.withUnsafeBytes { $0.load(as: UInt16.self) }
        case .indirectY:
            PC &+= 1
            let base = self[PC &- 1]
            let pointer = base
            let bytes = [self[UInt16(pointer)], self[UInt16(pointer &+ 1)]]
            return bytes.withUnsafeBytes { $0.load(as: UInt16.self) } &+ UInt16(self[.Y])
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
        PC = readAllocU16(index: 0xfffc)
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
            let opcode = self[PC]
            PC &+= 1

            switch opcode {
            case 0x00:
                // BRK
                return

            case 0xa9:
                // LDA (immidate)
                let result = LDA(mode: .immidiate)
                updateStatus(result: result)
            case 0xa5:
                // LDA (zero page)
                let result = LDA(mode: .zero)
                updateStatus(result: result)
            case 0xb5:
                // LDA (zero page x)
                let result = LDA(mode: .zeroX)
                updateStatus(result: result)
            case 0xad:
                // LDA (absolute)
                let result = LDA(mode: .abs)
                updateStatus(result: result)
            case 0xbd:
                // LDA (absolute x)
                let result = LDA(mode: .absX)
                updateStatus(result: result)
            case 0xb9:
                // LDA (absolute y)
                let result = LDA(mode: .absY)
                updateStatus(result: result)
            case 0xa1:
                // LDA (indirect x)
                let result = LDA(mode: .indirectX)
                updateStatus(result: result)
            case 0xb1:
                // LDA (indirect y)
                let result = LDA(mode: .indirectY)
                updateStatus(result: result)

            case 0xaa:
                // TAX
                let result = TAX()
                updateStatus(result: result)

            case 0xe8:
                // INX
                let result = INX()
                updateStatus(result: result)

            case 0x85:
                // STA (zero page)
                let result = STA(mode: .zero)
                updateStatus(result: result)
            case 0x95:
                let result = STA(mode: .zeroX)
                updateStatus(result: result)
            case 0x8d:
                let result = STA(mode: .abs)
                updateStatus(result: result)
            case 0x9d:
                let result = STA(mode: .absX)
                updateStatus(result: result)
            case 0x99:
                let result = STA(mode: .absY)
                updateStatus(result: result)
            case 0x81:
                let result = STA(mode: .indirectX)
                updateStatus(result: result)
            case 0x91:
                let result = STA(mode: .indirectY)
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
        load(program: program)
        run()
    }
}
