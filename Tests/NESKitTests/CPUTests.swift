@testable import NESKit
import XCTest

final class CPUTests: XCTestCase {
    func testLDAImmidiateLoadData() {
        var cpu = CPU6502()
        cpu.interpret(program: [0xa9, 0x05, 0x00])
        XCTAssertEqual(cpu[.A], 0x05)
        XCTAssertTrue(cpu[.P] & 0x2 == 0)
        XCTAssertTrue(cpu[.P] & 0x80 == 0)
    }
    
    func testLDAZeroFlag() {
        var cpu = CPU6502()
        cpu.interpret(program: [0xa9, 0x00, 0x00])
        XCTAssertTrue(cpu[.P] & 0x2 == 2)
    }
    
    func testTAX() {
        var cpu = CPU6502()
        cpu.interpret(program: [0xa9, 0x05, 0xaa, 0x00])
        XCTAssertEqual(cpu[.X], cpu[.A])
    }
    
    func testINX() {
        var cpu = CPU6502()
        cpu.interpret(program: [0xe8, 0x00])
        XCTAssertEqual(cpu[.X], 1)
    }
    
    func testINXOverflow() {
        var cpu = CPU6502()
        cpu.interpret(program: [0xa9, 0xff, 0xaa, 0xe8, 0x00])
        XCTAssertEqual(cpu[.X], 0)
    }
}
