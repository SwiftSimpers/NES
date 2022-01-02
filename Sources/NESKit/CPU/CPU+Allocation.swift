//
//  CPU+Allocation.swift
//  
//
//  Created by Helloyunho on 2022/01/02.
//

import Foundation

extension CPU6502 {
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
}
