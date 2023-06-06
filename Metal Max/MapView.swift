//
//  MapView.swift
//  Metal Max
//
//  Created by SAGESSE on 2023/5/26.
//

import UIKit

class MapView: UIView {
    
    var map: Map?
    var texture: Texutre?

    var tileSize: CGSize = .init(width: 16, height: 16)
    
    
    func reloadData() {
        visableRows = nil
        visableColumns = nil
        reusableCells.append(contentsOf: visableCells.values)
        visableCells.values.forEach {
            $0.isHidden = true
        }
        visableCells.removeAll()
        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard let window = window else {
            return
        }
        let width = window.bounds.width
        let height = window.bounds.height
        let rect = CGRect(x: -width / 2, y: -height / 2, width: width * 2, height: height * 2)
        update(window.convert(rect, to: self))
    }
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        setNeedsLayout()
    }
    
    private func update(_ rect: CGRect) {
        
        let col1 = Int(floor(rect.minX / pageSize.width))
        let col2 = Int(ceil(rect.maxX / pageSize.width))
        
        let row1 = Int(floor(rect.minY / pageSize.height))
        let row2 = Int(ceil(rect.maxY / pageSize.height))
        
        let rows = row1 ..< row2
        let columns = col1 ..< col2
        guard visableRows != rows || visableColumns != columns else {
            return
        }
        visableRows = rows
        visableColumns = columns
        
        var newItems = Set<IndexPath>()
        var removeItems = Set(visableCells.keys)
        
        for row in rows {
            for column in columns {
                let indexPath = IndexPath(item: column, section: row)
                if removeItems.remove(indexPath) == nil {
                    newItems.insert(indexPath)
                }
            }
        }
        
        removeItems.forEach {
            // add into reusable queue.
            if let layer = visableCells.removeValue(forKey: $0) {
                layer.isHidden = true
                reusableCells.append(layer)
            }
        }
        
        newItems.forEach {
            // reusable if queue is non empty.
            if let contentLayer = reusableCells.first {
                reusableCells.removeFirst()
                visableCells[$0] = contentLayer
                update(contentLayer, at: $0)
                return
            }
            // create a new layer.
            let contentLayer = CALayer()
            layer.addSublayer(contentLayer)
            visableCells[$0] = contentLayer
            update(contentLayer, at: $0)
        }
    }
    
    private func update(_ layer: CALayer, at indexPath: IndexPath) {
        let rect = CGRect(x: pageSize.width * .init(indexPath.item),
                          y: pageSize.height * .init(indexPath.section),
                          width: pageSize.width,
                          height: pageSize.height)
        print(#function, layer, indexPath)
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        layer.isHidden = false
        layer.frame = rect
        layer.borderColor = UIColor.red.cgColor
        layer.borderWidth = 0.5
        layer.contents = nil
        CATransaction.commit()
        // call
        pageRenderQueue.async {
            let image = UIGraphicsImageRenderer(size: rect.size).image { context in
                self.draw(rect, in: context.cgContext)
            }
            let cgImage = image.cgImage
            DispatchQueue.main.async {
                self.visableCells[indexPath]?.contents = cgImage
            }
        }
    }
    
    private func draw(_ rect: CGRect, in context: CGContext) {
        
        guard let map = map else {
            return
        }
        
        var transform = CGAffineTransform(scaleX: 1, y: -1)
        transform = transform.translatedBy(x: 0, y: -rect.height)
        context.concatenate(transform)
        context.interpolationQuality = .none

        UIColor.red.setStroke()
        UIColor.red.setFill()

        let col1 = Int(floor(rect.minX / tileSize.width))
        let col2 = Int(ceil(rect.maxX / tileSize.width))
        
        let row1 = Int(floor(rect.minY / tileSize.height))
        let row2 = Int(ceil(rect.maxY / tileSize.height))
        
        for row in row1 ..< row2 {
            for col in col1 ..< col2 {
                let rect = CGRect(x: -rect.minX + tileSize.width * .init(col),
                                  y: rect.maxY - tileSize.height * .init(row + 1),
                                  width: tileSize.width,
                                  height: tileSize.height)
                if let image = texture?.image(at: map[col, row]) {
                    context.draw(image, in: rect)
                }
                
                if map.entrances.contains(where: { $0.from.x == col && $0.from.y == row }) {
                    context.stroke(rect)
                }
            }
        }
    }
    
    private var visableRows: Range<Int>?
    private var visableColumns: Range<Int>?
    private var visableCells: [IndexPath: CALayer] = [:]
    private var reusableCells: [CALayer] = []

    private var pageSize: CGSize = .init(width: 256, height: 256)
    private var pageRenderQueue: DispatchQueue = .init(label: "GamePageRenderQueue", attributes: .concurrent)
}
