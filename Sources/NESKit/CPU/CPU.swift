import Foundation

public struct CPU6502 {
    public enum RegisterKeys: String {
        case A, X, Y, S, P
    }

    internal var registers: [RegisterKeys: UInt8] = [:]
    internal var memory: Memory = .init()
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
            return memory.readAllocU16(index: PC &- 2)
        case .absX:
            PC &+= 2
            return memory.readAllocU16(index: PC &- 2) &+ UInt16(self[.X])
        case .absY:
            PC &+= 2
            return memory.readAllocU16(index: PC &- 2) &+ UInt16(self[.Y])
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
        PC = memory.readAllocU16(index: 0xFFFC)
    }

    /**
     Updates the status register based on the result.
     - parameters:
        - result: Result value of the execution.
     */
    public mutating func updateStatus(result: UInt8, overflow: Bool? = nil, carry: Bool? = nil) {
        // Flags
        // N V * B D I Z C
        if result == 0b0000_0000 {
            self[.P] |= 0b0000_0010
        } else {
            self[.P] &= 0b1111_1101
        }

        if result & 0b1000_0000 != 0 {
            self[.P] |= 0b1000_0000
        } else {
            self[.P] &= 0b0111_1111
        }

        if overflow ?? false {
            self[.P] |= 0b0100_0000
        } else {
            self[.P] &= 0b1011_1111
        }

        if carry ?? false {
            self[.P] |= 0b0000_0001
        } else {
            self[.P] &= 0b1111_1110
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

            case 0xA9:
                // LDA (immidate)
                _ = LDA(mode: .immidiate)

            case 0xA5:
                // LDA (zero page)
                _ = LDA(mode: .zero)

            case 0xB5:
                // LDA (zero page x)
                _ = LDA(mode: .zeroX)

            case 0xAD:
                // LDA (absolute)
                _ = LDA(mode: .abs)

            case 0xBD:
                // LDA (absolute x)
                _ = LDA(mode: .absX)

            case 0xB9:
                // LDA (absolute y)
                _ = LDA(mode: .absY)

            case 0xA1:
                // LDA (indirect x)
                _ = LDA(mode: .indirectX)

            case 0xB1:
                // LDA (indirect y)
                _ = LDA(mode: .indirectY)

            case 0xAA:
                // TAX
                _ = TAX()

            case 0xE8:
                // INX
                _ = INX()

            case 0x85:
                // STA (zero page)
                _ = STA(mode: .zero)
            case 0x95:
                // STA (zero page x)
                _ = STA(mode: .zeroX)
            case 0x8D:
                // STA (absolute)
                _ = STA(mode: .abs)
            case 0x9D:
                // STA (absolute x)
                _ = STA(mode: .absX)
            case 0x99:
                // STA (absolute y)
                _ = STA(mode: .absY)
            case 0x81:
                // STA (indirect x)
                _ = STA(mode: .indirectX)
            case 0x91:
                // STA (indirect y)
                _ = STA(mode: .indirectY)

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
        memory.load(program: program)
        run()
    }
}
