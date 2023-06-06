import UIKit
import JSONDecoderEx


// chilren: [
//  {
//    x: ...,
//    y: ...,
//    width: ...,
//    height: ...,
//    settings: ...
//  }
// ]
// entrances: [
//  {
//   x: ...,
//   y: ...,
//   id: ...
//  }
// ]
// settings: {
//   fill: ...
//   inset: ...
//   tiling: ...
//   north: {
//    fill: [ 0 ]
//    inset: 1
//    tiling: [ 0, 1 ]
//   }
// }
open class Map {
    
    public let name: String
    public let width: Int
    public let height: Int
    
    public let settings: Settings
    public let entrances: [Entrance]
    
    public let bgm: String

    private let data: UnsafeMutablePointer<UInt32>
    
    public init(named: String, in bundle: Bundle? = nil) throws {
        
        guard let url = Self.search("map/\(named)", in: bundle ?? .main) else {
            throw DecodingError(message: "Can't found map \(named)")
        }
        
        let image = try Self.loadImage(url)
        let settings = try Self.loadSetting(url)
        
        // 获取 CGImage 的宽高和颜色空间
        let width = image.width
        let height = image.height
        let colorSpace = CGColorSpaceCreateDeviceRGB()

        // 创建一个包含 CGImage 所有像素数据的 buffer
        let bytesPerPixel = 4   // RGBA
        let bufferSize = width * height * bytesPerPixel
        let buffer = UnsafeMutableRawPointer.allocate(byteCount: bufferSize, alignment: 0)

        // 获取 CGImage 像素到该 buffer
        let context = CGContext(data: buffer,
                                width: width,
                                height: height,
                                bitsPerComponent: 8,
                                bytesPerRow: bytesPerPixel * width,
                                space: colorSpace,
                                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        context?.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        self.name = named
        self.width = width
        self.height = height
        self.settings = settings
        self.entrances = settings.entrances
        self.bgm = "\(settings.bgm - 3)" // why???
        self.data = buffer.bindMemory(to: UInt32.self, capacity: width * height)
    }
    
    deinit {
        self.data.deallocate()
    }
    
    public subscript(_ x: Int, _ y: Int) -> Int {
        
        // ..
        if let value = settings.west.fixed(x) ?? settings.east.fixed(width - x - 1) {
            return value
        }
        
        // ..
        if let value = settings.north.fixed(y) ?? settings.south.fixed(height - y - 1) {
            return value
        }

        var tx = x
        if let offset = settings.west.resolve(tx) {
            tx = offset
        }
        if let offset = settings.east.resolve(width - tx - 1) {
            tx = width - offset - 1
        }

        var ty = y
        if let offset = settings.north.resolve(ty) {
            ty = offset
        }
        if let offset = settings.south.resolve(height - ty - 1) {
            ty = height - offset - 1
        }
        
        return Int(data[ty * width + tx].bigEndian >> 8)
    }
    
    public struct Settings: Decodable {
        
        public let north: Edge
        public let west: Edge
        public let east: Edge
        public let south: Edge
        
        fileprivate let bgm: Int
        fileprivate let entrances: [Entrance]
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: JSONDecoderEx.JSONKey.self)
            let settings = try container.nestedContainer(keyedBy: JSONDecoderEx.JSONKey.self, forKey: "settings")
            let base = try container.decode(Edge.self, forKey: "settings")
            self.north = try settings.decodeIfPresent(Edge.self, forKey: "north") ?? base
            self.west = try settings.decodeIfPresent(Edge.self, forKey: "west") ?? base
            self.east = try settings.decodeIfPresent(Edge.self, forKey: "east") ?? base
            self.south = try settings.decodeIfPresent(Edge.self, forKey: "south") ?? base
            self.bgm = try settings.decode(Int.self, forKey: "bgm")
            self.entrances = try container.decode([Entrance].self, forKey: "entrances")
        }
    }
    
    public struct Entrance: Decodable {
        
        public let from: Point
        public let to: Point
        public let id: Int
    }
    
    public struct Edge: Decodable {
        
        public let fill: [Int]
        public let inset: Int
        public let tiling: [Int]
        
        func fixed(_ offset: Int) -> Int? {
            
            guard offset < inset else {
                return nil
            }
            
           guard !fill.isEmpty else {
               guard tiling.isEmpty else {
                   return nil
               }
               return 0
            }
            
            let count = fill.count
            guard count != 0 else {
                return nil
            }
            
            return fill[(inset - offset - 1) % count]
        }
        
        func resolve(_ offset: Int) -> Int? {
            
            guard offset < inset else {
                return nil
            }
            
            let count = tiling.count
            guard count != 0 else {
                return 0
            }
            
            return tiling[(inset - offset - 1) % count]
        }
    }
    
    
    public struct DecodingError: Error {
        public let message: String
    }
    
    
    private static func search(_ named: String, in bundle: Bundle) -> URL? {
        return bundle.url(forResource: named, withExtension: "png")
    }
    
    private static func loadImage(_ url: URL) throws -> CGImage {
        guard  let image = UIImage(contentsOfFile: url.path)?.cgImage else {
            throw DecodingError(message: "Can't decoding map \(url)")
        }
        return image
    }
    
    private static func loadSetting(_ url: URL) throws -> Settings {
        let decoder = JSONDecoderEx()
        let contentsURL = url.deletingPathExtension().appendingPathExtension("json")
        guard let contents = try? Data(contentsOf: contentsURL) else {
            // build a empty settings.
            return try decoder.decode(Settings.self, from: [String:Any]())
        }
        return try decoder.decode(Settings.self, from: contents)
    }
}

