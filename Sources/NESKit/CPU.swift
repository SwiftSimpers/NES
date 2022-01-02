struct CPU6502 {
    enum RegisterKeys: String {
        case A, X, Y, S, P
    }

    private var registers: [RegisterKeys: UInt8] = [:]
    private var _PC: UInt16 = 0
    private var allocs: [UInt8] = Array(repeating: 0, count:0xffff)
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
     Gets register value by register key.
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
     Gets allocated value by index.
     - parameters:
        - index: Index of the part you want to get.
     - returns: Allocated value matches with the index.
     */
    subscript(index: Int) -> UInt8 {
        get {
            return allocs[index]
        }
        set(value) {
            allocs[index] = value
        }
    }
    
    /**
     Gets all allocated values in the provided range.
     - parameters:
        - bounds: Index range of the parts you want to get.
     - returns: Allocated values in the parameter range.
     */
    subscript(bounds: Range<Int>) -> ArraySlice<UInt8> {
        get {
            return allocs[bounds]
        }
        set(value) {
            allocs[bounds] = value
        }
    }
    
    /**
     Gets all allocated values in the provided range.
     - parameters:
        - r: Index range of the parts you want to get.
     - returns: Allocated values in the parameter range.
     */
    subscript<R>(r: R) -> ArraySlice<UInt8> where R : RangeExpression, Int == R.Bound {
        get {
            return allocs[r]
        }
        set(value) {
            allocs[r] = value
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
     Allocates the program into CPU.
     - parameters:
        - program: Program code in 6502 machine language.
     */
    public mutating func load(program: [UInt8]) {
        allocs.replaceSubrange(0x8000 ..< (0x8000 + program.count), with: program)
        writeAllocU16(index: 0xFFFC, value: 0x8000)
    }
    
    /**
     Reads 2 bytes(16 bits) from the provided index.
     - parameters:
        - index: Index value you want to start from.
     */
    public func readAllocU16(index: Int) -> UInt16 {
        // Somehow UInt16 by default reads bytes in little endian order
        // So we don't have to do anything yayy
        // Code from: https://stackoverflow.com/a/47764694/9376340
        return self[index ... index + 1].withUnsafeBytes { $0.load(as: UInt16.self) }
    }
    
    /**
     Writes 2 bytes(16 bits) from the provided index.
     - parameters:
        - index: Index value you want to start from.
        - value: 16 bits value you want to write.
     */
    public mutating func writeAllocU16(index: Int, value: UInt16) {
        // It wasa easy to convert array to uint16
        // But hard to convert uint16 back into array oof
        // Code from: https://gist.github.com/kimjj81/aadf55fc591220afdc8450452c2ea21d
        var _endian = value.littleEndian
        let bytePtr = withUnsafePointer(to: &_endian) {
            $0.withMemoryRebound(to: UInt8.self, capacity: MemoryLayout<UInt16>.size) {
                UnsafeBufferPointer(start: $0, count: MemoryLayout<UInt16>.size)
            }
        }
        allocs.replaceSubrange(index ... (index + 1), with: [UInt8](bytePtr))
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
