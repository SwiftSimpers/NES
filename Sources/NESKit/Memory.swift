import Foundation

public let ProgramOffset: UInt16 = 0x600

public struct MemoryRegion {
    public var range: Range<UInt16>
    public var read: (Memory, UInt16) -> UInt8
    public var write: (Memory, UInt16, UInt8) -> Void

    public init() {
        range = 0x0000 ..< 0xFFFF
        read = { _, _ in 0 }
        write = { _, _, _ in }
    }
}

public struct Memory {
    public var data: Data = .init(count: 0xFFFF)
    public var regions: [MemoryRegion] = []

    /**
     Gets allocated value by index.
     - parameters:
        - index: Index of the part you want to get.
     - returns: Allocated value matches with the index.
     */
    subscript(index: Int) -> UInt8 {
        get {
            return data[index]
        }
        set(value) {
            data[index] = value
        }
    }

    /**
     Gets allocated value by index.
     - parameters:
        - index: Index of the part you want to get.
     - returns: Allocated value matches with the index.
     */
    subscript(index: UInt16) -> UInt8 {
        get {
            for region in regions {
                if region.range.contains(index) {
                    return region.read(self, index)
                }
            }
            return data[Int(index)]
        }
        set(value) {
            for region in regions {
                if region.range.contains(index) {
                    region.write(self, index, value)
                    return
                }
            }
            data[Int(index)] = value
        }
    }

    /**
     Gets all allocated values in the provided range.
     - parameters:
        - bounds: Index range of the parts you want to get.
     - returns: Allocated values in the parameter range.
     */
    subscript<R>(rangeExpression: R) -> Data where R: RangeExpression, R.Bound: FixedWidthInteger {
        get {
            return data[rangeExpression]
        }
        set(value) {
            data[rangeExpression] = value
        }
    }

    public init() {}

    /**
     Allocates the program into CPU.
     - parameters:
        - program: Program code in 6502 machine language.
     */
    public mutating func load(program: [UInt8]) {
        data.replaceSubrange(Int(ProgramOffset) ..< (Int(ProgramOffset) + program.count), with: program)
        writeAllocU16(index: 0xFFFC, value: ProgramOffset)
    }

    /**
     Reads 2 bytes(16 bits) from the provided index.
     - parameters:
        - index: Index value you want to start from.
     */
    public func readAllocU16(index: UInt16) -> UInt16 {
        return UInt16(data[Int(index)]) | UInt16(data[Int(index) + 1]) << 8
    }

    /**
     Writes 2 bytes(16 bits) from the provided index.
     - parameters:
        - index: Index value you want to start from.
        - value: 16 bits value you want to write.
     */
    public mutating func writeAllocU16(index: UInt16, value: UInt16) {
        // Code from: https://stackoverflow.com/a/38024025/9376340
        let index = Int(index)
        let littleEndian = value.littleEndian
        let bytes = withUnsafeBytes(of: littleEndian) { Data($0) }
        data.replaceSubrange(index ... (index &+ 1), with: bytes)
    }
}
