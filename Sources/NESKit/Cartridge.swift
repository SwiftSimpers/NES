import Foundation

public enum Mirroring {
    case vertical
    case horizontal
    case fourScreen
}

public enum CartridgeError: Error {
    case invalidHeader
}

public struct Cartridge {
    public let prg: Data
    public let chr: Data
    public let mapper: UInt8
    public let mirroring: Mirroring

    public init(prg: Data, chr: Data, mapper: UInt8, mirroring: Mirroring) {
        self.prg = prg
        self.chr = chr
        self.mapper = mapper
        self.mirroring = mirroring
    }

    public init(program: [UInt8]) {
        var prg = Data(repeating: 0, count: 0xFFFF)
        prg.replaceSubrange(0x600...0x600 + program.count, with: program)
        prg[0x7FFC + 1] = 134
        self.prg = prg
        self.chr = Data(repeating: 0, count: 0x2000)
        self.mapper = 0
        self.mirroring = .vertical
    }

    public static func load(rom: Data) throws -> Cartridge {
        let header = rom.subdata(in: 0 ..< 16)
        // NES^Z
        if header[0] != 0x4E || header[1] != 0x45 || header[2] != 0x53 || header[3] != 0x1A {
            throw CartridgeError.invalidHeader
        }

        if (header[7] >> 2) & 0b11 != 0 {
            throw CartridgeError.invalidHeader
        }

        let mapper = (header[7] & 0b1111_0000) | (header[6] >> 4)

        let fourScreen = header[6] & 0b1000 != 0
        let vertical = header[6] & 0b1 != 0

        var mirroring: Mirroring
        switch (fourScreen, vertical) {
            case (true, _):
                mirroring = .fourScreen
            case (false, true):
                mirroring = .vertical
            case (false, false):
                mirroring = .horizontal
        }

        let prgSize = Int(header[4]) * 0x4000
        let chrSize = Int(header[5]) * 0x2000

        let skipTrainer = header[6] & 0b100 != 0
        let prgStart = 16 + (skipTrainer ? 512 : 0)
        let chrStart = prgStart + prgSize

        let prg = rom.subdata(in: prgStart ..< prgStart + prgSize)
        let chr = rom.subdata(in: chrStart ..< chrStart + chrSize)

        return Cartridge(prg: prg, chr: chr, mapper: mapper, mirroring: mirroring)
    }
}
