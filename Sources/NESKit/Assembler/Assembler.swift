import Foundation

public struct Assembler6502 {
    var index: Int = 0
    var position: Position = .init(line: 0, column: 0)
    var source: String = ""
    var tokens: [Token] = []
}
