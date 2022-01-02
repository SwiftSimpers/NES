//
//  CPU+Instructions.swift
//
//
//  Created by Helloyunho on 2022/01/02.
//

import Foundation

public extension CPU6502 {
    /**
     Replaces register A to the provided address.
     - parameters:
        - mode: Addressing mode to set where and how it should grab address.
     - returns: The replacement value.
     */
    mutating func LDA(mode: AddressingModes) -> UInt8 {
        let pointer = getAddress(mode: mode)
        let value = self[pointer]
        self[.A] = value
        updateStatus(result: value)
        return self[.A]
    }

    /**
     Replaces register X to register A value.
     - returns: The replacement(register A) value.
     */
    mutating func TAX() -> UInt8 {
        self[.X] = self[.A]
        updateStatus(result: self[.X])
        return self[.X]
    }

    /**
     Increaces register X value by 1.
     - returns: The increased register X value.
     */
    mutating func INX() -> UInt8 {
        self[.X] &+= 1
        updateStatus(result: self[.X])
        return self[.X]
    }

    /**
     Copy register A value to the provided address.
     - parameters:
        - mode: Addressing mode to set where and how it should grab address.
     - returns: The copied value.
     */
    mutating func STA(mode: AddressingModes) -> UInt8 {
        let pointer = getAddress(mode: mode)
        self[pointer] = self[.A]
        return self[.A]
    }
}
