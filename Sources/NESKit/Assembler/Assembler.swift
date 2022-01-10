import Foundation

public struct Assembler6502 {
    var index: Int = 0
    var position: Position = .init(line: 0, column: 0)
    var span: Span = .init(start: .init(line: 0, column: 0), end: .init(line: 0, column: 0))
    var source: String = ""
    var tokens: [Token] = []
    var nodes: [Node] = []
    var labels: [String: Int] = [:]
    var instructionOffset: Int = 0
    var assembly: Data? = nil
    
    public init() {}
}
