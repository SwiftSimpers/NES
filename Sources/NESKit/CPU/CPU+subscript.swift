//
//  CPU+subscript.swift
//
//
//  Created by Helloyunho on 2022/01/02.
//

import Foundation

public extension CPU6502 {
    /**
     Gets register value by register key.
     - parameters:
        - register: Register key you want to get the value.
     - returns: Register value matches with the key.
     */
    subscript(register: Register) -> UInt8 {
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
            return memory[index]
        }
        set(value) {
            memory[index] = value
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
            return memory[Int(index)]
        }
        set(value) {
            memory[Int(index)] = value
        }
    }

    /**
     Gets stack value by index.
     - parameters:
        - index: Index of the part you want to get.
     - returns: Stack value matches with the index.
     */
    subscript(index: UInt8) -> UInt8 {
        get {
            return memory[Int(index)]
        }
        set(value) {
            memory[Int(index)] = value
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
            return memory[rangeExpression]
        }
        set(value) {
            memory[rangeExpression] = value
        }
    }

    subscript(index: Address) -> UInt8 {
        get {
            switch index {
            case let .memory(address):
                return memory[address]
            case let .register(key):
                return registers[key] ?? 0
            }
        }
        set {
            switch index {
            case let .memory(address):
                memory[address] = newValue
            case let .register(key):
                registers[key] = newValue
            }
        }
    }
}
