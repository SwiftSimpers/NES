import Foundation

enum StackError: Error {
    case overflow
    case underflow
}

// N V _ B D I Z C
public enum StatusFlag: UInt8 {
    case negative = 0b1000_0000
    case overflow = 0b0100_0000
    case break1 = 0b0010_0000
    case break2 = 0b0001_0000
    case decimal = 0b0000_1000
    case interrupt = 0b0000_0100
    case zero = 0b0000_0010
    case carry = 0b0000_0001
}

public struct CPU6502 {
    public enum Address {
        case memory(UInt16)
        case register(Register)
    }

    public enum InterruptType {
        case nmi
        case irq
        case reset
    }

    public enum Status {
        case ok
        case interrupt(InterruptType)
    }

    public enum ClockSpeed: Int {
        case NTSC = 1_789_773
        case PAL = 1_662_607
    }

    internal var registers: [Register: UInt8] = [:]
    internal var memory: Memory = .init()

    var nodes: [Node] = []
    var sourceLines: [String] = []
    /// Clock speed in hz.
    public var clockSpeed: Int = ClockSpeed.NTSC.rawValue

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
    
    public init() {}

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
            let offset = self[PC]
            PC &+= 1
            // We first convert offset to a **signed** integer, 8-bit.
            // Then we convert it to 32-bit integer and add it to PC (casted as 32-bit integer).
            // This is to support negative offsets, otherwise signed integers
            // would not be needed.
            let signedOffset = Int8(bitPattern: offset)
            return .memory(UInt16(Int(PC) &+ Int(signedOffset)))
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
            .S: 0xFD,
            .P: 0b0010_0100,
        ]
        PC = memory.readAllocU16(index: 0xFFFC)
    }

    /**
      Pushes a value to the stack.
      - parameters:
         - value: Value you want to push.
     */
    public mutating func pushStack(value: UInt16) {
        memory[Int(self[.S])] = UInt8(value &>> 8)
        memory[Int(self[.S]) &- 1] = UInt8(value & 0xFF)
        self[.S] &-= 2
    }

    /**
      Pops a value from the stack.
      - returns: Value popped from the stack.
     */
    public mutating func popStack() throws -> UInt16 {
        self[.S] &+= 2
        if self[.S] == 0xFF {
            throw StackError.underflow
        } else if self[.S] == 0x00 {
            throw StackError.overflow
        }
        let low = UInt16(memory[Int(self[.S]) &- 1])
        let high = UInt16(memory[Int(self[.S])])
        return high &<< 8 | low
    }

    public func getStatus(_ flag: StatusFlag) -> Bool {
        return (registers[.P]! & flag.rawValue) != 0
    }

    /**
     Updates the status register based on the result.
     - parameters: Various status flags. Nil means don't update,
       true / false adds / removes them from P register.
     */
    public mutating func updateStatus(
        negative: Bool? = nil,
        overflow: Bool? = nil,
        decimal: Bool? = nil,
        interrupt: Bool? = nil,
        zero: Bool? = nil,
        carry: Bool? = nil
    ) {
        if let negative = negative {
            if negative {
                self[.P] |= StatusFlag.negative.rawValue
            } else {
                self[.P] &= ~StatusFlag.negative.rawValue
            }
        }

        if let overflow = overflow {
            if overflow {
                self[.P] |= StatusFlag.overflow.rawValue
            } else {
                self[.P] &= ~StatusFlag.overflow.rawValue
            }
        }

        if let decimal = decimal {
            if decimal {
                self[.P] |= StatusFlag.decimal.rawValue
            } else {
                self[.P] &= ~StatusFlag.decimal.rawValue
            }
        }

        if let interrupt = interrupt {
            if interrupt {
                self[.P] |= StatusFlag.interrupt.rawValue
            } else {
                self[.P] &= ~StatusFlag.interrupt.rawValue
            }
        }

        if let zero = zero {
            if zero {
                self[.P] |= StatusFlag.zero.rawValue
            } else {
                self[.P] &= ~StatusFlag.zero.rawValue
            }
        }

        if let carry = carry {
            if carry {
                self[.P] |= StatusFlag.carry.rawValue
            } else {
                self[.P] &= ~StatusFlag.carry.rawValue
            }
        }
    }

    public func cycled(_ num: Int, cb: () throws -> Void) throws {
        let startTime = clock_gettime_nsec_np(CLOCK_MONOTONIC_RAW)
        try cb()
        let endTime = clock_gettime_nsec_np(CLOCK_MONOTONIC_RAW)
        let timeElapsed = Double(endTime - startTime) / 1e+9
        // print("Time: \(String(format: "%f", timeElapsed))")
        let timeToWait = Double(1 / clockSpeed * num) - timeElapsed
        // print("Wait: \(String(format: "%f", timeToWait))")
        if timeToWait > 0 {
            Thread.sleep(forTimeInterval: timeToWait)
        }
    }

    public func cycled(_ num: Int, cb: () -> Void) {
        try! cycled(num) { () throws in
            cb()
        }
    }

    public mutating func step() throws -> Status {
        let opcode = self[PC]
        // print("step \(String(format: "%02x", opcode)) at PC: \(String(format: "%04x", PC))")

        // if nodes.count > 0, sourceLines.count > 0 {
        //     var node: Instruction?
        //     for e in nodes {
        //         if case let .instruction(inst) = e {
        //             if inst.offset == PC - ProgramOffset {
        //                 node = inst
        //                 break
        //             }
        //         }
        //     }
        //     if let node = node {
        //         let line = sourceLines[node.span.start.line - 1]
        //         print(" inst: \(node.name)")
        //         print("  arg: \(String(describing: node.arg))")
        //         print("  src: \(line)")
        //         print("   at: \(node.span)")
        //     }
        // }

        PC &+= 1

        switch opcode {
        case 0x00:
            // BRK
            // So that RTI can return from the BRK.
            cycled(7) {
                pushStack(value: PC + 1)
            }
            return .interrupt(.nmi)

        case 0x69:
            cycled(2) {
                ADC(mode: .immidiate)
            }
        case 0x65:
            cycled(3) {
                ADC(mode: .zero)
            }
        case 0x75:
            cycled(4) {
                ADC(mode: .zeroX)
            }
        case 0x6D:
            cycled(4) {
                ADC(mode: .abs)
            }
        case 0x7D:
            cycled(4) {
                ADC(mode: .absX)
            }
        case 0x79:
            cycled(4) {
                ADC(mode: .absY)
            }
        case 0x61:
            cycled(6) {
                ADC(mode: .indirectX)
            }
        case 0x71:
            cycled(5) {
                ADC(mode: .indirectY)
            }

        case 0x29:
            cycled(2) {
                AND(mode: .immidiate)
            }
        case 0x25:
            cycled(3) {
                AND(mode: .zero)
            }
        case 0x35:
            cycled(4) {
                AND(mode: .zeroX)
            }
        case 0x2D:
            cycled(4) {
                AND(mode: .abs)
            }
        case 0x3D:
            cycled(4) {
                AND(mode: .absX)
            }
        case 0x39:
            cycled(4) {
                AND(mode: .absY)
            }
        case 0x21:
            cycled(6) {
                AND(mode: .indirectX)
            }
        case 0x31:
            cycled(5) {
                AND(mode: .indirectY)
            }

        case 0x0A:
            cycled(2) {
                ASL(mode: .accumulator)
            }
        case 0x06:
            cycled(5) {
                ASL(mode: .zero)
            }
        case 0x16:
            cycled(6) {
                ASL(mode: .zeroX)
            }
        case 0x0E:
            cycled(6) {
                ASL(mode: .abs)
            }
        case 0x1E:
            cycled(7) {
                ASL(mode: .absX)
            }

        case 0x24:
            cycled(3) {
                BIT(mode: .zero)
            }
        case 0x2C:
            cycled(4) {
                BIT(mode: .abs)
            }

        case 0x10:
            cycled(2) {
                BPL()
            }
        case 0x30:
            cycled(2) {
                BMI()
            }
        case 0x50:
            cycled(2) {
                BVC()
            }
        case 0x70:
            cycled(2) {
                BVS()
            }
        case 0x90:
            cycled(2) {
                BCC()
            }
        case 0xB0:
            cycled(2) {
                BCS()
            }
        case 0xD0:
            cycled(2) {
                BNE()
            }
        case 0xF0:
            cycled(2) {
                BEQ()
            }

        case 0xC9:
            cycled(2) {
                CMP(mode: .immidiate)
            }
        case 0xC5:
            cycled(3) {
                CMP(mode: .zero)
            }
        case 0xD5:
            cycled(4) {
                CMP(mode: .zeroX)
            }
        case 0xCD:
            cycled(4) {
                CMP(mode: .abs)
            }
        case 0xDD:
            cycled(4) {
                CMP(mode: .absX)
            }
        case 0xD9:
            cycled(4) {
                CMP(mode: .absY)
            }
        case 0xC1:
            cycled(6) {
                CMP(mode: .indirectX)
            }
        case 0xD1:
            cycled(5) {
                CMP(mode: .indirectY)
            }

        case 0xE0:
            cycled(2) {
                CPX(mode: .immidiate)
            }
        case 0xE4:
            cycled(3) {
                CPX(mode: .zero)
            }
        case 0xEC:
            cycled(4) {
                CPX(mode: .abs)
            }

        case 0xC0:
            cycled(2) {
                CPY(mode: .immidiate)
            }
        case 0xC4:
            cycled(3) {
                CPY(mode: .zero)
            }
        case 0xCC:
            cycled(4) {
                CPY(mode: .abs)
            }

        case 0xC6:
            cycled(5) {
                DEC(mode: .zero)
            }
        case 0xD6:
            cycled(6) {
                DEC(mode: .zeroX)
            }
        case 0xCE:
            cycled(6) {
                DEC(mode: .abs)
            }
        case 0xDE:
            cycled(7) {
                DEC(mode: .absX)
            }

        case 0x49:
            cycled(2) {
                EOR(mode: .immidiate)
            }
        case 0x45:
            cycled(3) {
                EOR(mode: .zero)
            }
        case 0x55:
            cycled(4) {
                EOR(mode: .zeroX)
            }
        case 0x4D:
            cycled(4) {
                EOR(mode: .abs)
            }
        case 0x5D:
            cycled(4) {
                EOR(mode: .absX)
            }
        case 0x59:
            cycled(4) {
                EOR(mode: .absY)
            }
        case 0x41:
            cycled(6) {
                EOR(mode: .indirectX)
            }
        case 0x51:
            cycled(5) {
                EOR(mode: .indirectY)
            }

        case 0x18:
            cycled(2) {
                CLC()
            }
        case 0x38:
            cycled(2) {
                SEC()
            }
        case 0x58:
            cycled(2) {
                CLI()
            }
        case 0x78:
            cycled(2) {
                SEI()
            }

        case 0xB8:
            cycled(2) {
                CLV()
            }

        // Decimal not implemented yet.
        case 0xD8:
            // CLD
            // CLD()
            break
        case 0xF8:
            // SED
            // SED()
            break

        case 0xE6:
            cycled(5) {
                INC(mode: .zero)
            }
        case 0xF6:
            cycled(6) {
                INC(mode: .zeroX)
            }
        case 0xEE:
            cycled(6) {
                INC(mode: .abs)
            }
        case 0xFE:
            cycled(7) {
                INC(mode: .absX)
            }

        case 0x4C:
            cycled(3) {
                JMP(mode: .abs)
            }
        case 0x6C:
            cycled(5) {
                JMP(mode: .indirect)
            }

        case 0x20:
            cycled(6) {
                JSR()
            }

        case 0xA9:
            cycled(2) {
                LDA(mode: .immidiate)
            }
        case 0xA5:
            cycled(3) {
                LDA(mode: .zero)
            }
        case 0xB5:
            cycled(4) {
                LDA(mode: .zeroX)
            }
        case 0xAD:
            cycled(4) {
                LDA(mode: .abs)
            }
        case 0xBD:
            cycled(4) {
                LDA(mode: .absX)
            }
        case 0xB9:
            cycled(4) {
                LDA(mode: .absY)
            }
        case 0xA1:
            cycled(6) {
                LDA(mode: .indirectX)
            }
        case 0xB1:
            cycled(5) {
                LDA(mode: .indirectY)
            }

        case 0xA2:
            cycled(2) {
                LDX(mode: .immidiate)
            }
        case 0xA6:
            cycled(3) {
                LDX(mode: .zero)
            }
        case 0xB6:
            cycled(4) {
                LDX(mode: .zeroY)
            }
        case 0xAE:
            cycled(4) {
                LDX(mode: .abs)
            }
        case 0xBE:
            cycled(4) {
                LDX(mode: .absY)
            }

        case 0xA0:
            cycled(2) {
                LDY(mode: .immidiate)
            }
        case 0xA4:
            cycled(3) {
                LDY(mode: .zero)
            }
        case 0xB4:
            cycled(4) {
                LDY(mode: .zeroX)
            }
        case 0xAC:
            cycled(4) {
                LDY(mode: .abs)
            }
        case 0xBC:
            cycled(4) {
                LDY(mode: .absX)
            }

        case 0x4A:
            cycled(2) {
                LSR(mode: .accumulator)
            }
        case 0x46:
            cycled(5) {
                LSR(mode: .zero)
            }
        case 0x56:
            cycled(6) {
                LSR(mode: .zeroX)
            }
        case 0x4E:
            cycled(6) {
                LSR(mode: .abs)
            }
        case 0x5E:
            cycled(7) {
                LSR(mode: .absX)
            }

        case 0xEA:
            // yes, somehow nop also consumes 2 cycles
            cycled(2) {
                NOP()
            }

        case 0x09:
            cycled(2) {
                ORA(mode: .immidiate)
            }
        case 0x05:
            cycled(3) {
                ORA(mode: .zero)
            }
        case 0x15:
            cycled(4) {
                ORA(mode: .zeroX)
            }
        case 0x0D:
            cycled(4) {
                ORA(mode: .abs)
            }
        case 0x1D:
            cycled(4) {
                ORA(mode: .absX)
            }
        case 0x19:
            cycled(4) {
                ORA(mode: .absY)
            }
        case 0x01:
            cycled(6) {
                ORA(mode: .indirectX)
            }
        case 0x11:
            cycled(5) {
                ORA(mode: .indirectY)
            }

        case 0xAA:
            cycled(2) {
                TAX()
            }
        case 0x8A:
            cycled(2) {
                TXA()
            }
        case 0xCA:
            cycled(2) {
                DEX()
            }
        case 0xE8:
            cycled(2) {
                INX()
            }
        case 0xA8:
            cycled(2) {
                TAY()
            }
        case 0x98:
            cycled(2) {
                TYA()
            }
        case 0x88:
            cycled(2) {
                DEY()
            }
        case 0xC8:
            cycled(2) {
                INY()
            }

        case 0x2A:
            cycled(2) {
                ROL(mode: .accumulator)
            }
        case 0x26:
            cycled(5) {
                ROL(mode: .zero)
            }
        case 0x36:
            cycled(6) {
                ROL(mode: .zeroX)
            }
        case 0x2E:
            cycled(6) {
                ROL(mode: .abs)
            }
        case 0x3E:
            cycled(7) {
                ROL(mode: .absX)
            }

        case 0x6A:
            cycled(2) {
                ROR(mode: .accumulator)
            }
        case 0x66:
            cycled(5) {
                ROR(mode: .zero)
            }
        case 0x76:
            cycled(6) {
                ROR(mode: .zeroX)
            }
        case 0x6E:
            cycled(6) {
                ROR(mode: .abs)
            }
        case 0x7E:
            cycled(7) {
                ROR(mode: .absX)
            }

        case 0x40:
            try cycled(2) {
                try RTI()
            }

        case 0x60:
            try cycled(2) {
                try RTS()
            }

        case 0xE9:
            cycled(2) {
                SBC(mode: .immidiate)
            }
        case 0xE5:
            cycled(3) {
                SBC(mode: .zero)
            }
        case 0xF5:
            cycled(4) {
                SBC(mode: .zeroX)
            }
        case 0xED:
            cycled(4) {
                SBC(mode: .abs)
            }
        case 0xFD:
            cycled(4) {
                SBC(mode: .absX)
            }
        case 0xF9:
            cycled(4) {
                SBC(mode: .absY)
            }
        case 0xE1:
            cycled(6) {
                SBC(mode: .indirectX)
            }
        case 0xF1:
            cycled(5) {
                SBC(mode: .indirectY)
            }

        case 0x85:
            cycled(3) {
                STA(mode: .zero)
            }
        case 0x95:
            cycled(4) {
                STA(mode: .zeroX)
            }
        case 0x8D:
            cycled(4) {
                STA(mode: .abs)
            }
        case 0x9D:
            cycled(5) {
                STA(mode: .absX)
            }
        case 0x99:
            cycled(5) {
                STA(mode: .absY)
            }
        case 0x81:
            cycled(6) {
                STA(mode: .indirectX)
            }
        case 0x91:
            cycled(6) {
                STA(mode: .indirectY)
            }

        case 0x9A:
            cycled(2) {
                TXS()
            }
        case 0xBA:
            cycled(2) {
                TSX()
            }
        case 0x48:
            cycled(2) {
                PHA()
            }
        case 0x68:
            cycled(2) {
                PLA()
            }
        case 0x08:
            cycled(3) {
                PHP()
            }
        case 0x28:
            cycled(4) {
                PLP()
            }

        case 0x86:
            cycled(3) {
                STX(mode: .zero)
            }
        case 0x96:
            cycled(4) {
                STX(mode: .zeroY)
            }
        case 0x8E:
            cycled(4) {
                STX(mode: .abs)
            }

        case 0x84:
            cycled(3) {
                STY(mode: .zero)
            }
        case 0x94:
            cycled(4) {
                STY(mode: .zeroX)
            }
        case 0x8C:
            cycled(4) {
                STY(mode: .abs)
            }

        default:
            break
        }

        return .ok
    }

    /**
     Executes the program allocated on CPU's allocations.
     Check the P register to check the status of CPU.
     */
    public mutating func run() throws {
        reset()
        loop: while true {
            switch try step() {
            case .ok:
                break
            case .interrupt:
                break loop
            }
        }
    }
    
    /**
     Allocates the program into CPU.
     - parameters:
        - program: Program code in 6502 machine language.
     */
    public mutating func load(program: [UInt8]) {
        memory.load(program: program)
    }

    /**
     Allocates the program into CPU and executes the program.
     - parameters:
        - program: Program code in 6502 machine language.
     */
    public mutating func loadAndRun(program: [UInt8]) throws {
        load(program: program)
        try run()
    }
}
