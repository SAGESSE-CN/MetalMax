//
//  Texutre.swift
//  Metal Max
//
//  Created by SAGESSE on 2023/5/26.
//

import UIKit

class Texutre {
    
    let tileSize: CGSize
    
    init?(named: String, tileSize: CGSize) {
        guard let image = UIImage(named: named) else {
            return nil
        }
        self.tileSize = tileSize
        
        var images = [CGImage]()
        let columns = max(Int(image.size.width / tileSize.width), 1)
        let rows = max(Int(image.size.height / tileSize.height), 1)
        for row in 0 ..< rows {
            for col in 0 ..< columns {
                let rect = CGRect(x: tileSize.width * .init(col),
                                  y: tileSize.height * .init(row),
                                  width: tileSize.width,
                                  height: tileSize.height)
                guard let n = image.cgImage?.cropping(to: rect) else {
                    continue
                }
                images.append(n)
            }
        }
        self.images = images
        
    }
    
    func image(at index: Int) -> CGImage? {
        let i = index & 0xffff
        return images[i % images.count]
    }
    
    
    private let images: [CGImage]
}
