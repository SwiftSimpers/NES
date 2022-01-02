//
//  CPU+Instructions.swift
//  
//
//  Created by Helloyunho on 2022/01/02.
//

import Foundation

extension CPU6502 {
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
}
