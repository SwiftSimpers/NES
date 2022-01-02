//
//  CPU+subscript.swift
//  
//
//  Created by Helloyunho on 2022/01/02.
//

import Foundation

extension CPU6502 {
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
     Gets allocated value by index.
     - parameters:
        - index: Index of the part you want to get.
     - returns: Allocated value matches with the index.
     */
    subscript(index: UInt16) -> UInt8 {
        get {
            return allocs[Int(index)]
        }
        set(value) {
            allocs[Int(index)] = value
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
        - bounds: Index range of the parts you want to get.
     - returns: Allocated values in the parameter range.
     */
    subscript(bounds: Range<UInt16>) -> ArraySlice<UInt8> {
        get {
            return allocs[Int(bounds.lowerBound) ... Int(bounds.upperBound)]
        }
        set(value) {
            allocs[Int(bounds.lowerBound) ... Int(bounds.upperBound)] = value
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
}
