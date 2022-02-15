import Foundation

public let ProgramOffset: UInt16 = 0x600

public struct Bus {
    var vram = Data(repeating: 0, count: 2048)
    var cartridge: Cartridge? = nil

    public init() {}

    subscript(index: Int) -> UInt8 {
        get {
            return read(at: UInt16(index))
        }
        set {
            write(at: UInt16(index), value: newValue)
        }
    }

    public func read(at index: UInt16) -> UInt8 {
        switch index {
        case 0x0000...0x1FFF:
            return vram[Int(index) & 0b00000111_11111111]
        case 0x2000...0x3FFF:
            // let addr = Int(index) & 0b00100000_00000111
            fatalError("PPU not implemented")
        case 0x8000...0xFFFF:
            return readPrgRom(at: index)
        default:
            print("Unhandled read at \(index)")
            return 0
        }
    }

    public func readPrgRom(at index: UInt16) -> UInt8 {
        if let cartridge = cartridge {
            var idx = index - 0x8000
            if cartridge.prg.count == 0x4000 && idx >= 0x4000 {
                idx = idx % 0x4000
            }
            return cartridge.prg[Int(idx)]
        } else {
            fatalError("Cartridge not loaded")
        }
    }

    public mutating func write(at index: UInt16, value: UInt8) {
        switch index {
        case 0x0000...0x1FFF:
            vram[Int(index) & 0b11111111111] = value
        case 0x2000...0x3FFF:
            // let addr = Int(index) & 0b00100000_00000111
            fatalError("PPU not implemented")
        case 0x8000...0xFFFF:
            fatalError("Attempted to write in read-only PRG ROM")
        default:
            print("Unhandled write at \(index)")
        }
    }

    public func read16(at: UInt16) -> UInt16 {
        return UInt16(read(at: at)) | UInt16(read(at: at &+ 1)) << 8
    }

    public mutating func write16(at: UInt16, value: UInt16) {
        write(at: at, value: UInt8(value & 0xFF))
        write(at: at &+ 1, value: UInt8(value >> 8))
    }
}
