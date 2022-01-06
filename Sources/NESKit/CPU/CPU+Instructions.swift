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
     */
    mutating func LDA(mode: AddressingModes) {
        let pointer = getAddress(mode: mode)
        let value = self[pointer]
        self[.A] = value
        updateStatus(negative: value & 0x80 != 0, zero: value == 0)
    }

    /**
     Replaces register X to register A value.
     */
    mutating func TAX() {
        self[.X] = self[.A]
        updateStatus(negative: self[.A] & 0x80 != 0, zero: self[.A] == 0)
    }

    /**
     Replaces register A to register X value.
     */
    mutating func TXA() {
        self[.A] = self[.X]
        updateStatus(negative: self[.A] & 0x80 != 0, zero: self[.A] == 0)
    }

    /**
     Decreces register X value by 1.
     */
    mutating func DEX() {
        self[.X] &-= 1
        updateStatus(negative: self[.X] & 0x80 != 0, zero: self[.X] == 0)
    }

    /**
     Increaces register X value by 1.
     */
    mutating func INX() {
        self[.X] &+= 1
        updateStatus(negative: self[.X] & 0x80 != 0, zero: self[.X] == 0)
    }

    /**
     Replaces register Y to register A value.
     */
    mutating func TAY() {
        self[.Y] = self[.A]
        updateStatus(negative: self[.A] & 0x80 != 0, zero: self[.A] == 0)
    }

    /**
     Replaces register A to register Y value.
     */
    mutating func TYA() {
        self[.A] = self[.Y]
        updateStatus(negative: self[.A] & 0x80 != 0, zero: self[.A] == 0)
    }

    /**
     Decreces register Y value by 1.
     */
    mutating func DEY() {
        self[.Y] &-= 1
        updateStatus(negative: self[.Y] & 0x80 != 0, zero: self[.Y] == 0)
    }

    /**
     Increaces register Y value by 1.
     */
    mutating func INY() {
        self[.Y] &+= 1
        updateStatus(negative: self[.Y] & 0x80 != 0, zero: self[.Y] == 0)
    }

    /**
     Copy register A value to the provided address.
     - parameters:
        - mode: Addressing mode to set where and how it should grab address.
     */
    mutating func STA(mode: AddressingModes) {
        let pointer = getAddress(mode: mode)
        self[pointer] = self[.A]
    }

    /**
     Copy register X value to the provided address.
     - parameters:
        - mode: Addressing mode to set where and how it should grab address.
     */
    mutating func STX(mode: AddressingModes) {
        let pointer = getAddress(mode: mode)
        self[pointer] = self[.X]
    }

    /**
     Copy register Y value to the provided address.
     - parameters:
        - mode: Addressing mode to set where and how it should grab address.
     */
    mutating func STY(mode: AddressingModes) {
        let pointer = getAddress(mode: mode)
        self[pointer] = self[.Y]
    }

    /**
     Adds the provided address value to register A value.
     - parameters:
         - mode: Addressing mode to set where and how it should grab address.
     */
    mutating func ADC(mode: AddressingModes) {
        let pointer = getAddress(mode: mode)
        let value = self[pointer]
        let original = self[.A]
        self[.A] &+= value
        updateStatus(overflow: original > self[.A], carry: original > self[.A])
    }

    /**
     Subtracts the provided address value to register A value.
     - parameters:
         - mode: Addressing mode to set where and how it should grab address.
     */
    mutating func SBC(mode: AddressingModes) {
        let pointer = getAddress(mode: mode)
        let value = self[pointer]
        let original = self[.A]
        self[.A] &-= value
        updateStatus(overflow: original > self[.A], carry: original < self[.A])
    }

    /**
     Run AND bitwise with register A and the provided address, then store the result to register A.
     - parameters:
        - mode: Addressing mode to set where and how it should grab address.
     */
    mutating func AND(mode: AddressingModes) {
        let pointer = getAddress(mode: mode)
        let value = self[pointer]
        self[.A] &= value
        updateStatus(negative: self[.A] & 0x80 != 0, zero: self[.A] == 0)
    }

    /**
     Run ASL operation on the provided address.
      - parameters:
        - mode: Addressing mode to set where and how it should grab address.
     */
    mutating func ASL(mode: AddressingModes) {
        let pointer = getAddress(mode: mode)
        let value = self[pointer]
        let result = value << 1
        self[.A] = result
        updateStatus(negative: result & 0x80 != 0, zero: result == 0, carry: value & 0x80 != 0)
    }

    /**
     Run BIT operation on the provided address.
     - parameters:
        - mode: Addressing mode to set where and how it should grab address.
     */
    mutating func BIT(mode: AddressingModes) {
        let pointer = getAddress(mode: mode)
        let value = self[pointer]
        let result = self[.A] & value
        updateStatus(negative: value & 0x80 != 0, overflow: value & 0x40 != 0, zero: result == 0, carry: value & 0x01 != 0)
    }

    /**
     Changes PC to the given relative address if plus flag is set.
     */
    mutating func BPL() {
        let pointer = getAddress(mode: .relative)
        if !getStatus(.negative), case let .memory(address) = pointer {
            PC = address
        }
    }

    /**
     Changes PC to the given relative address if minus flag is set.
     */
    mutating func BMI() {
        let pointer = getAddress(mode: .relative)
        if getStatus(.negative), case let .memory(address) = pointer {
            PC = address
        }
    }

    /**
     Changes PC to the given relative address if oVerflow flag is not set.
     */
    mutating func BVC() {
        let pointer = getAddress(mode: .relative)
        if !getStatus(.overflow), case let .memory(address) = pointer {
            PC = address
        }
    }

    /**
     Changes PC to the given relative address if oVerflow flag is set.
     */
    mutating func BVS() {
        let pointer = getAddress(mode: .relative)
        if getStatus(.overflow), case let .memory(address) = pointer {
            PC = address
        }
    }

    /**
     Changes PC to the given relative address if carry flag is not set.
     */
    mutating func BCC() {
        let pointer = getAddress(mode: .relative)
        if !getStatus(.carry), case let .memory(address) = pointer {
            PC = address
        }
    }

    /**
     Changes PC to the given relative address if carry flag is set.
     */
    mutating func BCS() {
        let pointer = getAddress(mode: .relative)
        if getStatus(.carry), case let .memory(address) = pointer {
            PC = address
        }
    }

    /**
     Changes PC to the given relative address if equal flag is not set.
     */
    mutating func BNE() {
        let pointer = getAddress(mode: .relative)
        if !getStatus(.zero), case let .memory(address) = pointer {
            PC = address
        }
    }

    /**
     Changes PC to the given relative address if equal flag is set.
     */
    mutating func BEQ() {
        let pointer = getAddress(mode: .relative)
        if getStatus(.zero), case let .memory(address) = pointer {
            PC = address
        }
    }

    /**
     Compares the provided address with register A.
      - parameters:
        - mode: Addressing mode to set where and how it should grab address.
     */
    mutating func CMP(mode: AddressingModes) {
        let pointer = getAddress(mode: mode)
        let value = self[pointer]
        let result = self[.A] &- value
        updateStatus(negative: result & 0x80 != 0, zero: result == 0, carry: result >= 0)
    }

    /**
     Compares the provided address with register X.
      - parameters:
        - mode: Addressing mode to set where and how it should grab address.
     */
    mutating func CPX(mode: AddressingModes) {
        let pointer = getAddress(mode: mode)
        let value = self[pointer]
        let result = self[.X] &- value
        updateStatus(negative: result & 0x80 != 0, zero: result == 0, carry: result >= 0)
    }

    /**
     Compares the provided address with register Y.
      - parameters:
        - mode: Addressing mode to set where and how it should grab address.
     */
    mutating func CPY(mode: AddressingModes) {
        let pointer = getAddress(mode: mode)
        let value = self[pointer]
        let result = self[.Y] &- value
        updateStatus(negative: result & 0x80 != 0, zero: result == 0, carry: result >= 0)
    }

    /**
     Decreases the provided memory value by 1.
      - parameters:
        - mode: Addressing mode to set where and how it should grab address.
     */
    mutating func DEC(mode: AddressingModes) {
        let pointer = getAddress(mode: mode)
        let value = self[pointer]
        let result = value &- 1
        self[pointer] = result
        updateStatus(negative: result & 0x80 != 0, zero: result == 0)
    }

    /**
     Run XOR bitwise with register A and the provided address, then store the result to register A.
      - parameters:
        - mode: Addressing mode to set where and how it should grab address.
     */
    mutating func EOR(mode: AddressingModes) {
        let pointer = getAddress(mode: mode)
        let value = self[pointer]
        self[.A] ^= value
        updateStatus(negative: self[.A] & 0x80 != 0, zero: self[.A] == 0)
    }

    /**
      Clears the carry flag.
     */
    mutating func CLC() {
        self[.P] &= 0b1111_1110
    }

    /**
      Sets the carry flag.
     */
    mutating func SEC() {
        self[.P] |= 0b0000_0001
    }

    /**
      Clears the interrupt flag.
     */
    mutating func CLI() {
        self[.P] &= 0b1111_1110
    }

    /**
      Sets the interrupt flag.
     */
    mutating func SEI() {
        self[.P] |= 0b0000_0001
    }

    /**
      Clears the overflow flag.
     */
    mutating func CLV() {
        self[.P] &= 0b1011_1111
    }

    /**
     Increaces the provided memory value by 1.
      - parameters:
        - mode: Addressing mode to set where and how it should grab address.
     */
    mutating func INC(mode: AddressingModes) {
        let pointer = getAddress(mode: mode)
        let value = self[pointer]
        let result = value &+ 1
        self[pointer] = result
        updateStatus(negative: result & 0x80 != 0, zero: result == 0)
    }

    /**
     Jumps to the provided address.
      - parameters:
        - mode: Addressing mode to set where and how it should grab address.
     */
    mutating func JMP(mode: AddressingModes) {
        let pointer = getAddress(mode: mode)
        if case let .memory(address) = pointer {
            PC = address
        }
    }

    /**
     Jumps to the provided (absolute) address and pushes address - 1 to stack.
     */
    mutating func JSR() {
        let pointer = getAddress(mode: .abs)
        if case let .memory(address) = pointer {
            pushStack(value: PC - 1)
            PC = address
        }
    }

    /**
     Returns from interrupt.
     Pops the address from stack and jumps to address.
     */
    mutating func RTI() throws {
        let address = try popStack()
        PC = address
    }

    /**
     Returns from subroutine (last call in stack).
     Pops the address from stack and jumps to address + 1.
     */
    mutating func RTS() throws {
        let address = try popStack()
        PC = address + 1
    }

    /**
     Replaces register X to the provided address.
     - parameters:
        - mode: Addressing mode to set where and how it should grab address.
     */
    mutating func LDX(mode: AddressingModes) {
        let pointer = getAddress(mode: mode)
        let value = self[pointer]
        self[.X] = value
        updateStatus(negative: value & 0x80 != 0, zero: value == 0)
    }

    /**
     Replaces register Y to the provided address.
     - parameters:
        - mode: Addressing mode to set where and how it should grab address.
     */
    mutating func LDY(mode: AddressingModes) {
        let pointer = getAddress(mode: mode)
        let value = self[pointer]
        self[.Y] = value
        updateStatus(negative: value & 0x80 != 0, zero: value == 0)
    }

    /**
     Shifts the value on the provided address right and replaces the register A value to it.
      - parameters:
        - mode: Addressing mode to set where and how it should grab address.
     */
    mutating func LSR(mode: AddressingModes) {
        let pointer = getAddress(mode: mode)
        let value = self[pointer]
        let result = value >> 1
        self[.A] = result
        updateStatus(carry: value & 0b1000_0000 != 0)
    }

    /**
      No operation.
     */
    mutating func NOP() {
        // what, it literally does nothing lol
    }

    // OOOOORAORAORAORAORAORAORAAAAA
    /**
     Run OR bitwise with register A and the provided address, then store the result to register A.
      - parameters:
        - mode: Addressing mode to set where and how it should grab address.
     */
    mutating func ORA(mode: AddressingModes) {
        let pointer = getAddress(mode: mode)
        let value = self[pointer]
        self[.A] |= value
        updateStatus(negative: self[.A] & 0x80 != 0, zero: self[.A] == 0)
    }

    /**
     Performs bitwise shift left operation.
      - parameters:
        - mode: Addressing mode to set where and how it should grab address.
     */
    mutating func ROL(mode: AddressingModes) {
        let pointer = getAddress(mode: mode)
        let value = self[pointer]
        let result = (value << 1) | (self[.P] & 0b0000_0001)
        self[.A] = result
        updateStatus(carry: value & 0b1000_0000 != 0)
    }

    /**
     Performs bitwise shift right operation.
      - parameters:
        - mode: Addressing mode to set where and how it should grab address.
     */
    mutating func ROR(mode: AddressingModes) {
        let pointer = getAddress(mode: mode)
        let value = self[pointer]
        let result = (value >> 1) | (self[.P] & 0b1000_0000)
        self[.A] = result
        updateStatus(carry: value & 0b0000_0001 != 0)
    }

    /**
     Replaces register S(Stack pointer) to regiser X.
     */
    mutating func TXS() {
        self[.S] = self[.X]
    }

    /**
     Replaces register X to regiser S(Stack pointer).
     */
    mutating func TSX() {
        self[.X] = self[.S]
    }

    /**
     Pushes register A value to stack.
     */
    mutating func PHA() {
        self[.S] -= 1
        memory[Int(self[.S])] = self[.A]
    }

    /**
     Pops the stack value to register A.
     */
    mutating func PLA() {
        self[.S] += 1
        self[.A] = memory[Int(self[.S])]
    }

    /**
     Pushes register P (status regiser) value to stack.
     */
    mutating func PHP() {
        self[.S] -= 1
        memory[Int(self[.S])] = self[.P]
    }

    /**
     Pops the stack value to register P(Status regiser).
     */
    mutating func PLP() {
        self[.S] += 1
        self[.P] = memory[Int(self[.P])]
    }
}
