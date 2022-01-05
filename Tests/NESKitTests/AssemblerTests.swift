@testable import NESKit
import XCTest

let assembly = """
// comment

/*
  long comment
  naisu
*/

LDA #0x69
LDA 0x6969
LDA 0x6969,X
LDA 0x6969,Y
JMP (0x6969)
LDA (0x6969,X)
LDA (0x6969,Y)
LDA #(0x69)
LDA #(0x69,X)
LDX #(0x69,Y)
BEQ 0x69
BRK
"""

final class AssemblerTests: XCTestCase {
    func testLexer() throws {
        var assembler = Assembler6502()
        try assembler.lex(source: assembly)
        // dump(assembler.tokens)
        XCTAssertEqual(assembler.tokens.count, 53)
    }
}
