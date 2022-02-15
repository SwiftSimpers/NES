@testable import NESKit
import XCTest

struct Expectation {
    var registers: [Register: UInt8] = [:]
    var memory: [UInt16: UInt8] = [:]
    var PC: UInt16? = nil
}

func test(_ initalize: @escaping (inout CPU6502) throws -> Void, _ source: String, _ expect: @escaping (inout CPU6502) throws -> Void) throws {
    var assembler = Assembler6502()
    try assembler.lex(source: source)
    try assembler.parse()
    try assembler.assemble()
    printHexDumpForBytes(bytes: assembler.assembly!)
    var cpu = CPU6502()
    try initalize(&cpu)
    try cpu.loadAndRun(program: Array(assembler.assembly!))
    try expect(&cpu)
}

func test(_ source: String, _ expect: @escaping (inout CPU6502) throws -> Void) throws {
    try test({ _ in }, source, expect)
}

final class CPUTests: XCTestCase {
    func testLDAImmidiateLoadData() throws {
        try test(
            """
            LDA #0x05
            """
        ) { cpu in
            XCTAssertEqual(cpu[.A], 0x05)
            XCTAssertFalse(cpu.getStatus(.zero))
            XCTAssertFalse(cpu.getStatus(.negative))
        }
    }

    func testLDAZeroFlag() throws {
        try test(
            """
            LDA #0x00
            """
        ) { cpu in
            XCTAssertEqual(cpu[.A], 0x00)
            XCTAssertTrue(cpu.getStatus(.zero))
            XCTAssertFalse(cpu.getStatus(.negative))
        }
    }

    func testLDAFromMemory() throws {
        try test(
            { cpu in
                cpu.bus[0x10] = 0x55
            },
            """
            LDA 0x10
            """
        ) { cpu in
            XCTAssertEqual(cpu[.A], 0x55)
            XCTAssertFalse(cpu.getStatus(.zero))
            XCTAssertFalse(cpu.getStatus(.negative))
        }
    }

    func testTAX() throws {
        try test(
            """
            LDA #0x05
            TAX
            """
        ) { cpu in
            XCTAssertEqual(cpu[.X], 0x05)
            XCTAssertFalse(cpu.getStatus(.zero))
            XCTAssertFalse(cpu.getStatus(.negative))
        }
    }

    func testINX() throws {
        try test(
            """
            INX
            """
        ) { cpu in
            XCTAssertEqual(cpu[.X], 0x01)
            XCTAssertFalse(cpu.getStatus(.zero))
            XCTAssertFalse(cpu.getStatus(.negative))
        }
    }

    func testINXOverflow() throws {
        try test(
            """
            LDX #0xFF
            INX
            """
        ) { cpu in
            XCTAssertEqual(cpu[.X], 0x00)
            XCTAssertTrue(cpu.getStatus(.zero))
            XCTAssertFalse(cpu.getStatus(.negative))
        }
    }

    func testSTA() throws {
        try test(
            """
            LDA #0x05
            STA 0x10
            """
        ) { cpu in
            XCTAssertEqual(cpu[.A], 0x05)
            XCTAssertEqual(cpu.bus[0x10], 0x05)
            XCTAssertFalse(cpu.getStatus(.zero))
            XCTAssertFalse(cpu.getStatus(.negative))
        }
    }

    func testADC() throws {
        try test(
            """
            LDA #0xFF
            ADC #0x08
            """
        ) { cpu in
            XCTAssertEqual(cpu[.A], 0x07)
            XCTAssertTrue(cpu.getStatus(.carry))
        }
    }

    func testAND() throws {
        try test(
            """
            LDA #0x05
            AND #0x02
            """
        ) { cpu in
            XCTAssertEqual(cpu[.A], 0x05 & 0x02)
        }
    }

    func testANDFromMemory() throws {
        try test(
            { cpu in
                cpu.bus[0x10] = 0x05
            },
            """
            LDA #0x10
            AND 0x10
            """
        ) { cpu in
            XCTAssertEqual(cpu[.A], 0x05 & 0x10)
        }
    }

    func testASL() throws {
        try test(
            """
            LDA #0b00000010
            ASL A
            """
        ) { cpu in
            XCTAssertEqual(cpu[.A], 0b0000_0100)
            XCTAssertFalse(cpu.getStatus(.carry))
            XCTAssertFalse(cpu.getStatus(.zero))
            XCTAssertFalse(cpu.getStatus(.negative))
        }
    }

    func testBIT() throws {
        try test(
            """
            LDA #0b00000101
            LDX #0b00000100
            STX 0x10
            BIT 0x10
            """
        ) { cpu in
            XCTAssertFalse(cpu.getStatus(.overflow))
            XCTAssertFalse(cpu.getStatus(.zero))
            XCTAssertFalse(cpu.getStatus(.negative))
        }
    }

    func testBITZero() throws {
        try test(
            """
            LDA #0b11111111
            LDX #0b01000000
            STX 0x10
            BIT 0x10
            """
        ) { cpu in
            XCTAssertTrue(cpu.getStatus(.overflow))
            XCTAssertFalse(cpu.getStatus(.zero))
            XCTAssertFalse(cpu.getStatus(.negative))
        }
    }

    func testBPL() throws {
        try test(
            """
            main:
                LDA #0x69
                CMP #0x69
                BPL plus
            minus:
                LDA #0xFF
                BRK
            plus:
                LDA #0x60
                BRK
            """
        ) { cpu in
            XCTAssertEqual(cpu[.A], 0x60)
        }
    }

    func testBPLNotPlus() throws {
        try test(
            """
            main:
                LDA #0x68
                CMP #0x69
                BPL plus
            minus:
                LDA #0xFF
                BRK
            plus:
                LDA #0x60
                BRK
            """
        ) { cpu in
            XCTAssertEqual(cpu[.A], 0xFF)
        }
    }

    func testBMI() throws {
        try test(
            """
            main:
                LDA #0x68
                CMP #0x69
                BMI minus
            plus:
                LDA #0xFF
                BRK
            minus:
                LDA #0x60
                BRK
            """
        ) { cpu in
            XCTAssertEqual(cpu[.A], 0x60)
        }
    }

    func testBMINotMinus() throws {
        try test(
            """
            main:
                LDA #0x69
                CMP #0x69
                BMI minus
            plus:
                LDA #0xFF
                BRK
            minus:
                LDA #0x60
                BRK
            """
        ) { cpu in
            XCTAssertEqual(cpu[.A], 0xFF)
        }
    }

    func testBVC() throws {
        try test(
            """
            main:
                BVC inflow
            overflow:
                LDA #0xFF
                BRK
            inflow:
                LDA #0x60
                BRK
            """
        ) { cpu in
            XCTAssertEqual(cpu[.A], 0x60)
        }
    }

    func testBVCOverflow() throws {
        try test(
            """
            main:
                LDA #0xFF
                ADC #0x01
                BVC inflow
            overflow:
                LDA #0x60
                BRK
            inflow:
                LDA #0xFF
                BRK
            """
        ) { cpu in
            XCTAssertEqual(cpu[.A], 0x60)
        }
    }

    func testBVS() throws {
        try test(
            """
            main:
                LDA #0xFF
                ADC #0x01
                BVS overflow
            inflow:
                LDA #0x60
                BRK
            overflow:
                LDA #0xFF
                BRK
            """
        ) { cpu in
            XCTAssertEqual(cpu[.A], 0xFF)
        }
    }

    func testBCC() throws {
        try test(
            """
            main:
                BCC carry_clear
            carry_set:
                LDA #0x60
                BRK
            carry_clear:
                LDA #0xFF
                BRK
            """
        ) { cpu in
            XCTAssertEqual(cpu[.A], 0xFF)
        }
    }

    func testBCS() throws {
        try test(
            """
            main:
                SEC
                BCS carry_set
            carry_clear:
                LDA #0xFF
                BRK
            carry_set:
                LDA #0x60
                BRK
            """
        ) { cpu in
            XCTAssertEqual(cpu[.A], 0x60)
        }
    }

    func testBNE() throws {
        try test(
            """
            main:
                LDA #0b00000001
                AND #0b00000001
                BNE not_equal
            equal:
                LDA #0x60
                BRK
            not_equal:
                LDA #0xFF
                BRK
            """
        ) { cpu in
            XCTAssertEqual(cpu[.A], 0xFF)
        }
    }

    func testBEQ() throws {
        try test(
            """
            main:
                LDA #0b00000001
                AND #0b00000010
                BEQ equal
            not_equal:
                LDA #0xFF
                BRK
            equal:
                LDA #0x60
                BRK
            """
        ) { cpu in
            XCTAssertEqual(cpu[.A], 0x60)
        }
    }

    func testJSR() throws {
        try test(
            """
            main:
                JSR init // 0x0600
                JSR test // 0x0603
                BRK
            init:
                LDA #0xFF // 0x0606
                RTS // 0x0609
            test:
                LDX #0x61 // 0x060C
                RTS // 0x060F
            """
        ) { cpu in
            XCTAssertEqual(cpu[.A], 0xFF)
            XCTAssertEqual(cpu[.X], 0x61)
        }
    }
}
