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
            return bus[index]
        }
        set(value) {
            bus[index] = value
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
            return bus[Int(index)]
        }
        set(value) {
            bus[Int(index)] = value
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
            return bus[Int(index)]
        }
        set(value) {
            bus[Int(index)] = value
        }
    }

    subscript(index: Address) -> UInt8 {
        get {
            switch index {
            case let .memory(address):
                return bus[Int(address)]
            case let .register(key):
                return registers[key] ?? 0
            }
        }
        set {
            switch index {
            case let .memory(address):
                bus[Int(address)] = newValue
            case let .register(key):
                registers[key] = newValue
            }
        }
    }
}
