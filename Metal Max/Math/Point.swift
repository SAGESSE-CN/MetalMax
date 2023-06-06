//
//  Point.swift
//  Metal Max
//
//  Created by SAGESSE on 2023/5/29.
//

import JSONDecoderEx


public struct Point: Decodable {
    
    public let x: Int
    public let y: Int
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        x = try container.decode(Int.self)
        y = try container.decode(Int.self)
    }
    
}
