import Foundation

public struct CPU6502 {
    public enum RegisterKeys: String {
        case A, X, Y, S, P
    }

    public enum Address {
        case memory(UInt16)
        case register(RegisterKeys)
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
            _PC = value
        }
    }

    internal mutating func getAddress(mode: AddressingModes) -> Address {
        switch mode {
        case .immidiate:
            PC &+= 1
            return .memory(PC &- 1)
        case .zero:
            PC &+= 1
            return .memory(UInt16(self[PC &- 1]))
        case .zeroX:
            PC &+= 1
            return .memory(UInt16(self[PC &- 1] &+ self[.X]))
        case .zeroY:
            PC &+= 1
            return .memory(UInt16(self[PC &- 1] &+ self[.Y]))
        case .abs:
            PC &+= 2
            return .memory(memory.readAllocU16(index: PC &- 2))
        case .absX:
            PC &+= 2
            return .memory(memory.readAllocU16(index: PC &- 2) &+ UInt16(self[.X]))
        case .absY:
            PC &+= 2
            return .memory(memory.readAllocU16(index: PC &- 2) &+ UInt16(self[.Y]))
        case .indirect:
            PC &+= 2
            return .memory(memory.readAllocU16(index: PC &- 2))
        case .indirectX:
            PC &+= 1
            let base = self[PC &- 1]
            let pointer = base &+ self[.X]
            let bytes = [self[UInt16(pointer)], self[UInt16(pointer &+ 1)]]
            return .memory(bytes.withUnsafeBytes { $0.load(as: UInt16.self) })
        case .indirectY:
            PC &+= 1
            let base = self[PC &- 1]
            let pointer = base
            let bytes = [self[UInt16(pointer)], self[UInt16(pointer &+ 1)]]
            return .memory(bytes.withUnsafeBytes { $0.load(as: UInt16.self) } &+ UInt16(self[.Y]))
        case .accumulator:
            return .register(.A)
        case .relative:
            PC &+= 1
            let offset = self[PC &- 1]
            // We first convert offset to a **signed** integer, 8-bit.
            // Then we convert it to 32-bit integer and add it to PC (casted as 32-bit integer).
            // This is to support negative offsets, otherwise signed integers
            // would not be needed.
            return .memory(UInt16(Int(PC) &+ Int(Int8(offset))))
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
            .S: 0xFF,
            .P: 0,
        ]
        PC = memory.readAllocU16(index: 0xFFFC)
    }

    /**
      Pushes a value to the stack.
      - parameters:
         - value: Value you want to push.
     */
    public mutating func pushStack(value: UInt16) {
        self[.S] -= 1
        memory[Int(self[.S])] = UInt8(value &>> 8)
        memory[Int(self[.S]) &- 1] = UInt8(value & 0xFF)
    }

    /**
      Pops a value from the stack.
      - returns: Value popped from the stack.
     */
    public mutating func popStack() -> UInt16 {
        let low = UInt16(memory[Int(self[.S]) &- 1])
        let high = UInt16(memory[Int(self[.S])])
        self[.S] += 1
        return high &<< 8 | low
    }

    /**
     Updates the status register based on the result.
     - parameters:
        - result: Result value of the execution.
     */
    public mutating func updateStatus(result: UInt8, overflow: Bool? = nil, carry: Bool? = nil, zero: Bool? = nil, negative: Bool? = nil, plus: Bool? = nil, minus: Bool? = nil, equal: Bool? = nil) {
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

        if zero ?? false {
            self[.P] |= 0b0000_0100
        } else {
            self[.P] &= 0b1111_1011
        }

        if negative ?? false {
            self[.P] |= 0b0000_1000
        } else {
            self[.P] &= 0b1111_0111
        }

        if plus ?? false {
            self[.P] |= 0b0001_0000
        } else {
            self[.P] &= 0b1110_1111
        }

        if minus ?? false {
            self[.P] |= 0b0010_0000
        } else {
            self[.P] &= 0b1101_1111
        }

        if equal ?? false {
            self[.P] |= 0b0100_0000
        } else {
            self[.P] &= 0b1011_1111
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

            case 0x69:
                ADC(mode: .immidiate)
            case 0x65:
                ADC(mode: .zero)
            case 0x75:
                ADC(mode: .zeroX)
            case 0x6D:
                ADC(mode: .abs)
            case 0x7D:
                ADC(mode: .absX)
            case 0x79:
                ADC(mode: .absY)
            case 0x61:
                ADC(mode: .indirectX)
            case 0x71:
                ADC(mode: .indirectY)

            case 0x29:
                AND(mode: .immidiate)
            case 0x25:
                AND(mode: .zero)
            case 0x35:
                AND(mode: .zeroX)
            case 0x2D:
                AND(mode: .abs)
            case 0x3D:
                AND(mode: .absX)
            case 0x39:
                AND(mode: .absY)
            case 0x21:
                AND(mode: .indirectX)
            case 0x31:
                AND(mode: .indirectY)

            case 0x0A:
                ASL(mode: .accumulator)
            case 0x06:
                ASL(mode: .zero)
            case 0x16:
                ASL(mode: .zeroX)
            case 0x0E:
                ASL(mode: .abs)
            case 0x1E:
                ASL(mode: .absX)

            case 0x24:
                BIT(mode: .zero)
            case 0x2C:
                BIT(mode: .abs)

            case 0x10:
                BPL()
            case 0x30:
                BMI()
            case 0x50:
                BVC()
            case 0x70:
                BVS()
            case 0x90:
                BCC()
            case 0xB0:
                BCS()
            case 0xD0:
                BNE()
            case 0xF0:
                BEQ()

            case 0xC9:
                CMP(mode: .immidiate)
            case 0xC5:
                CMP(mode: .zero)
            case 0xD5:
                CMP(mode: .zeroX)
            case 0xCD:
                CMP(mode: .abs)
            case 0xDD:
                CMP(mode: .absX)
            case 0xD9:
                CMP(mode: .absY)
            case 0xC1:
                CMP(mode: .indirectX)
            case 0xD1:
                CMP(mode: .indirectY)

            case 0xE0:
                CPX(mode: .immidiate)
            case 0xE4:
                CPX(mode: .zero)
            case 0xEC:
                CPX(mode: .abs)

            case 0xC0:
                CPY(mode: .immidiate)
            case 0xC4:
                CPY(mode: .zero)
            case 0xCC:
                CPY(mode: .abs)

            case 0xC6:
                DEC(mode: .zero)
            case 0xD6:
                DEC(mode: .zeroX)
            case 0xCE:
                DEC(mode: .abs)
            case 0xDE:
                DEC(mode: .absX)

            case 0x49:
                EOR(mode: .immidiate)
            case 0x45:
                EOR(mode: .zero)
            case 0x55:
                EOR(mode: .zeroX)
            case 0x4D:
                EOR(mode: .abs)
            case 0x5D:
                EOR(mode: .absX)
            case 0x59:
                EOR(mode: .absY)
            case 0x41:
                EOR(mode: .indirectX)
            case 0x51:
                EOR(mode: .indirectY)

            case 0x18:
                CLC()
            case 0x38:
                SEC()
            case 0x58:
                CLI()
            case 0x78:
                SEI()
            case 0xB8:
                CLV()
            // Decimal not implemented yet.
            // case 0xD8:
            //     // CLD
            //     CLD()
            // case 0xF8:
            //     // SED
            //     SED()

            case 0xE6:
                INC(mode: .zero)
            case 0xF6:
                INC(mode: .zeroX)
            case 0xEE:
                INC(mode: .abs)
            case 0xFE:
                INC(mode: .absX)

            case 0x4C:
                JMP(mode: .abs)
            case 0x6C:
                JMP(mode: .indirect)

            case 0x20:
                JSR()

            case 0xA9:
                LDA(mode: .immidiate)
            case 0xA5:
                LDA(mode: .zero)
            case 0xB5:
                LDA(mode: .zeroX)
            case 0xAD:
                LDA(mode: .abs)
            case 0xBD:
                LDA(mode: .absX)
            case 0xB9:
                LDA(mode: .absY)
            case 0xA1:
                LDA(mode: .indirectX)
            case 0xB1:
                LDA(mode: .indirectY)

            case 0xA2:
                LDX(mode: .immidiate)
            case 0xA6:
                LDX(mode: .zero)
            case 0xB6:
                LDX(mode: .zeroY)
            case 0xAE:
                LDX(mode: .abs)
            case 0xBE:
                LDX(mode: .absY)

            case 0xA0:
                LDY(mode: .immidiate)
            case 0xA4:
                LDY(mode: .zero)
            case 0xB4:
                LDY(mode: .zeroX)
            case 0xAC:
                LDY(mode: .abs)
            case 0xBC:
                LDY(mode: .absX)

            case 0x4A:
                LSR(mode: .accumulator)
            case 0x46:
                LSR(mode: .zero)
            case 0x56:
                LSR(mode: .zeroX)
            case 0x4E:
                LSR(mode: .abs)
            case 0x5E:
                LSR(mode: .absX)

            case 0xEA:
                NOP()

            case 0x09:
                ORA(mode: .immidiate)
            case 0x05:
                ORA(mode: .zero)
            case 0x15:
                ORA(mode: .zeroX)
            case 0x0D:
                ORA(mode: .abs)
            case 0x1D:
                ORA(mode: .absX)
            case 0x19:
                ORA(mode: .absY)
            case 0x01:
                ORA(mode: .indirectX)
            case 0x11:
                ORA(mode: .indirectY)

            case 0xAA:
                TAX()
            case 0x8A:
                TXA()
            case 0xCA:
                DEX()
            case 0xE8:
                INX()
            case 0xA8:
                TAY()
            case 0x98:
                TYA()
            case 0x88:
                DEY()
            case 0xC8:
                INY()

            case 0x2A:
                ROL(mode: .accumulator)
            case 0x26:
                ROL(mode: .zero)
            case 0x36:
                ROL(mode: .zeroX)
            case 0x2E:
                ROL(mode: .abs)
            case 0x3E:
                ROL(mode: .absX)

            case 0x6A:
                ROR(mode: .accumulator)
            case 0x66:
                ROR(mode: .zero)
            case 0x76:
                ROR(mode: .zeroX)
            case 0x6E:
                ROR(mode: .abs)
            case 0x7E:
                ROR(mode: .absX)

            case 0x40:
                RTI()

            case 0x60:
                RTS()

            case 0xE9:
                SBC(mode: .immidiate)
            case 0xE5:
                SBC(mode: .zero)
            case 0xF5:
                SBC(mode: .zeroX)
            case 0xED:
                SBC(mode: .abs)
            case 0xFD:
                SBC(mode: .absX)
            case 0xF9:
                SBC(mode: .absY)
            case 0xE1:
                SBC(mode: .indirectX)
            case 0xF1:
                SBC(mode: .indirectY)

            case 0x85:
                STA(mode: .zero)
            case 0x95:
                STA(mode: .zeroX)
            case 0x8D:
                STA(mode: .abs)
            case 0x9D:
                STA(mode: .absX)
            case 0x99:
                STA(mode: .absY)
            case 0x81:
                STA(mode: .indirectX)
            case 0x91:
                STA(mode: .indirectY)

            case 0x9A:
                TXS()
            case 0xBA:
                TSX()
            case 0x48:
                PHA()
            case 0x68:
                PLA()
            case 0x08:
                PHP()
            case 0x28:
                PLP()

            case 0x86:
                STX(mode: .zero)
            case 0x96:
                STX(mode: .zeroY)
            case 0x8E:
                STX(mode: .abs)

            case 0x84:
                STY(mode: .zero)
            case 0x94:
                STY(mode: .zeroX)
            case 0x8C:
                STY(mode: .abs)

            default:
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
