//
//  MusicPlayer.swift
//  Metal Max
//
//  Created by SAGESSE on 2023/6/6.
//

import Foundation
import JSONDecoderEx
import AVKit


class AudioPlayer {
    
    var items: [Item] = []
    
    init() {
        observer = NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: nil, queue: nil) { [weak self] in
            self?.itemDidEnd($0)
        }
        player.addPeriodicTimeObserver(forInterval: .init(seconds: 0.25, preferredTimescale: 44100), queue: nil) { time in
            print(#function, time.seconds)
        }
    }
    
    
    func append(_ item: Item) {
        items.append(item)
        addToQueue(item)
    }
    
    func removeAllItems() {
        items.removeAll()
        queue.removeAll()
        player.removeAllItems()
    }

    func next() {
        guard !items.isEmpty else {
            return
        }
        removeFromQueue(items.removeFirst())
        player.advanceToNextItem()
    }
    
    func play() {
        player.play()
    }
    
    func pause() {
        player.pause()
    }
    
    private func addToQueue(_ item: Item) {
        let group = Group(item: item)
        queue.append(group)
        group.allPlayerItems.forEach {
            player.insert($0, after: nil)
        }
    }
    
    private func removeFromQueue(_ item: Item) {
        guard let index = queue.firstIndex(where: { $0.item === item }) else {
            return
        }
        let group = queue.remove(at: index)
        group.allPlayerItems.forEach {
            if player.currentItem !== $0 {
                player.remove($0)
            }
        }
    }
    
    
    private var player: AVQueuePlayer = .init()
    private var queue: [Group] = []
    private var observer: Any?
}


extension AudioPlayer {
    
    class Item {
        
        let asset: AVAsset
        let settings: Settings
        
        init(named: String, in bundle: Bundle? = nil) throws {
            guard let url = Self.search("sound/\(named)", in: bundle ?? .main) else {
                throw DecodingError(message: "Can't sound \(named)")
            }
            self.asset = AVAsset(url: url)
            self.settings = try Self.loadSetting(url)
        }
        
        struct Loop: Codable {
            let start: TimeInterval
            let end: TimeInterval
        }
        
        struct Settings: Codable {
            let loop: [Loop]
        }
        
        struct DecodingError: Error {
            let message: String
        }
        
        private static func search(_ named: String, in bundle: Bundle) -> URL? {
            let exts = ["m4a","mp3","wav","aac"]
            for ext in exts  {
                if let r = bundle.url(forResource: named, withExtension: ext) {
                    return r
                }
            }
            return nil
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

}


extension AudioPlayer {
    
    class Group {
        
        let item: Item
        let allPlayerItems: [AVPlayerItem]
        let loopingPlayerItems: [AVPlayerItem]
        
        init(item: Item) {
            self.item = item
            guard !item.settings.loop.isEmpty else {
                self.allPlayerItems = [AVPlayerItem(asset: item.asset)]
                self.loopingPlayerItems = []
                return
            }
            var allPlayerItems = [AVPlayerItem]()
            var loopingPlayerItems = [AVPlayerItem]()
            
            let start = CMTime(seconds: item.settings.loop[0].start, preferredTimescale: 44100)
            let end = CMTime(seconds: item.settings.loop[0].end, preferredTimescale: 44100)
            
            // insert first part
            let firstItem = AVPlayerItem(asset: item.asset)
            firstItem.reversePlaybackEndTime = .zero
            firstItem.forwardPlaybackEndTime = end
            allPlayerItems.append(firstItem)
            
            // insert loop part
            for i in 0 ..< 2 {
                let loopingItem = AVPlayerItem(asset: item.asset)
                loopingItem.reversePlaybackEndTime = start
                loopingItem.forwardPlaybackEndTime = end
                loopingItem.seek(to: start, toleranceBefore: .zero, toleranceAfter: .zero, completionHandler: nil)
                allPlayerItems.append(loopingItem)
                loopingPlayerItems.append(loopingItem)
            }
            
//            // insert last part
//            let lastItem = AVPlayerItem(asset: item.asset)
//            lastItem.reversePlaybackEndTime = end
//            lastItem.forwardPlaybackEndTime = .invalid
//            lastItem.seek(to: end, toleranceBefore: .zero, toleranceAfter: .zero, completionHandler: nil)
//            allPlayerItems.append(lastItem)

            self.allPlayerItems = allPlayerItems
            self.loopingPlayerItems = loopingPlayerItems
        }
    }
    
    private func itemDidEnd(_ ntf: Notification) {
        guard let item = ntf.object as? AVPlayerItem, let group = queue.first else {
            return
        }
        // this is a looping item?
        guard group.loopingPlayerItems.contains(item) else {
            // the item it play end?
            if group.allPlayerItems.last === item {
                queue.removeFirst()
                items.removeFirst()
            }
            return
        }
        // yep, we need reuse it
        player.advanceToNextItem()
        player.insert(item, after: player.currentItem)
        item.seek(to: item.reversePlaybackEndTime, toleranceBefore: .zero, toleranceAfter: .zero, completionHandler: nil)
        print(#function, item.currentTime().seconds)
    }
}
