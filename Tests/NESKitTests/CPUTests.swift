@testable import NESKit
import XCTest

final class CPUTests: XCTestCase {
    func testLDAImmidiateLoadData() {
        var cpu = CPU6502()
        cpu.loadAndRun(program: [0xA9, 0x05, 0x00])
        XCTAssertEqual(cpu[.A], 0x05)
        XCTAssertTrue(cpu[.P] & 0x2 == 0)
        XCTAssertTrue(cpu[.P] & 0x80 == 0)
    }

    func testLDAZeroFlag() {
        var cpu = CPU6502()
        cpu.loadAndRun(program: [0xA9, 0x00, 0x00])
        XCTAssertTrue(cpu[.P] & 0x2 == 2)
    }

    func testLDAFromMemory() {
        var cpu = CPU6502()
        cpu[0x10] = 0x55
        cpu.loadAndRun(program: [0xA5, 0x10, 0x00])
        XCTAssertEqual(cpu[.A], 0x55)
    }

    func testTAX() {
        var cpu = CPU6502()
        cpu.loadAndRun(program: [0xA9, 0x05, 0xAA, 0x00])
        XCTAssertEqual(cpu[.X], cpu[.A])
    }

    func testINX() {
        var cpu = CPU6502()
        cpu.loadAndRun(program: [0xE8, 0x00])
        XCTAssertEqual(cpu[.X], 1)
    }

    func testINXOverflow() {
        var cpu = CPU6502()
        cpu.loadAndRun(program: [0xA9, 0xFF, 0xAA, 0xE8, 0x00])
        XCTAssertEqual(cpu[.X], 0)
    }

    func testSDA() {
        var cpu = CPU6502()
        cpu[0x10] = 0x55
        cpu.loadAndRun(program: [0xA5, 0x10, 0x85, 0x56, 0x00])
        XCTAssertEqual(cpu[0x56], 0x55)
    }

    func testADC() {
        var cpu = CPU6502()
        cpu.loadAndRun(program: [0xA9, 0x05, 0x69, 0x02, 0x00])
        XCTAssertEqual(cpu[.A], 0x07)
    }

    func testAND() {
        var cpu = CPU6502()
        cpu.loadAndRun(program: [0xA9, 0x05, 0x29, 0x05, 0x00])
        XCTAssertEqual(cpu[.A], 0x05 & 0x05)
    }

    func testANDFromMemory() {
        var cpu = CPU6502()
        cpu[0x10] = 0x05
        cpu.loadAndRun(program: [0xA5, 0x10, 0x29, 0x05, 0x00])
        XCTAssertEqual(cpu[.A], 0x05 & 0x05)
    }

    func testASL() {
        var cpu = CPU6502()
        cpu.loadAndRun(program: [0xA9, 0x05, 0x0A, 0x00])
        XCTAssertEqual(cpu[.A], 0x0A)
        XCTAssertTrue(cpu[.P] & 0x2 == 0)
        XCTAssertTrue(cpu[.P] & 0x80 == 0)
    }

    // func testBIT() {
    //     var cpu = CPU6502()
    //     cpu.loadAndRun(program: [0xA9, 0x05, 0x24, 0x00])
    //     XCTAssertEqual(cpu[.P] & 0x2, 0)
    //     XCTAssertEqual(cpu[.P] & 0x80, 0)
    // }

    // func testBPL() {
    //     var cpu = CPU6502()
    //     cpu.loadAndRun(program: [0x10, 0x00, 0xA9, 0x05, 0x00])
    //     XCTAssertEqual(cpu.PC, 0x02)
    // }
}
