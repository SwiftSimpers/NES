import XCTest
@testable import NESKit

final class CPUTests: XCTestCase {
    func testImmidiateLoadData() {
      var cpu = CPU6502()
      cpu.interpret(program: [0xa9, 0x05, 0x00])
      XCTAssertEqual(cpu[.A], 0x05)
      XCTAssertEqual(cpu.PC, 0x0002)
      // and tbh swift extension doesnt work right
      // windows fucky wucky
      // or other os too?
      // nah it's okay in macos
      // welp
      // can you see terminal?
      // ye
    }
}
