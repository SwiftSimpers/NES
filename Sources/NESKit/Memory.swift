import Foundation

public let ProgramOffset: UInt16 = 0x8000

public struct Memory {
    private var data: Data = .init(count: 0xFFFF)

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
            return data[Int(index)]
        }
        set(value) {
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
        // Somehow UInt16 by default reads bytes in little endian order
        // So we don't have to do anything yayy
        // Code from: https://stackoverflow.com/a/47764694/9376340
        return self[index ... index &+ 1].withUnsafeBytes { $0.load(as: UInt16.self) }
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
