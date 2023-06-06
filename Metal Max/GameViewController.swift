//
//  GameViewController.swift
//  Metal Max
//
//  Created by SAGESSE on 2023/5/11.
//

import UIKit
import AVKit
import JSONDecoderEx

class GameViewController: UIViewController, UIScrollViewDelegate {
    
    let label = UILabel()
    
    let contentView = MapView()
    let scrollView = UIScrollView()
    
    var slks: Any?
    
    let audioPlayer = AudioPlayer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        let size = CGSize(width: 16, height: 16)
        
        // { "location": [ $2,$1 ], "id": $3 },
        
//        contentView.map = Map(named: "0")
        contentView.texture = Texutre(named: "tile/all.png", tileSize: .init(width: 16, height: 16))
        contentView.tileSize = size
        contentView.frame = .init(x: 0, y: 0, width: 256 * size.width, height: 256 * size.height)
        
        scrollView.frame = view.bounds
        scrollView.delegate = self
//        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        scrollView.contentSize = contentView.frame.size
        scrollView.backgroundColor = .black
        scrollView.maximumZoomScale = 2.0
        scrollView.minimumZoomScale = 0.5
        scrollView.addSubview(contentView)
        view.addSubview(scrollView)
        scrollView.zoomScale = 2
        
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor),
            label.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
        ])
        
        change(0)
        
        
//        if let url = Bundle.main.url(forResource: "sound/5", withExtension: "m4a") {
//
//            do {
//
//                class MMM: AVQueuePlayer {
//                    override func insert(_ item: AVPlayerItem, after afterItem: AVPlayerItem?) {
//                        print(#function, item.currentTime().seconds)
//                        super.insert(item, after: afterItem)
//                    }
//                    override func advanceToNextItem() {
//                        print(#function)
//                        super.advanceToNextItem()
//                    }
//                }
//
//                let asset = AVAsset(url: url)
//                let p1 = AVPlayerItem(asset: asset)
//                let player = MMM()
//
//
//                slks = [player]
//                if let js = try? Data(contentsOf: url.deletingPathExtension().appendingPathExtension("json")) {
//                    struct Q: Codable {
//                        let start: TimeInterval
//                        let end: TimeInterval
//                    }
//                    struct QM: Codable {
//                        let loop: [Q]
//                    }
//                    if let qd = try? JSONDecoderEx().decode(QM.self, from: js) {
//
//                        let sp = CMTime(seconds: qd.loop[0].start, preferredTimescale: 44100)
//                        let ep = CMTime(seconds: qd.loop[0].end, preferredTimescale: 44100)
////                        let looper = AVPlayerLooper(player: player, templateItem: p1, timeRange: .init(start: sp, end: ep))
////                        slks = [player, looper]
////                        player.actionAtItemEnd = .advance
//                        for i in 0 ..< 10 {
//                            let p2 = AVPlayerItem(asset: asset)
//                            p2.reversePlaybackEndTime = sp
//                            p2.forwardPlaybackEndTime = ep
//                            p2.seek(to: sp)
//                            player.insert(p2, after: nil)
//                        }
////                        player.seek(to: sp, toleranceBefore: .zero, toleranceAfter: .zero) { _ in
////                        }
//                    }
//                }
////                if player.items().isEmpty {
////                    player.insert(p1, after: nil)
////                }
//
//
////                player.insert(.init(url: url), after: nil)
//
////                let player = AVPlayer(url: url)
////                let playerLayer = AVPlayerLayer(player: player)
//                player.addPeriodicTimeObserver(forInterval: .init(seconds: 0.25, preferredTimescale: 44100), queue: nil) { [weak player] time in
////                    let x = time.convertScale(44100, method: .roundAwayFromZero)
////                    //print(#function, time)
////                    if x == ep {
//                    print(#function, time.seconds)
////                        player?.seek(to: sp)
////                    }
//                }
////                view.layer.addSublayer(playerLayer)
//                //player.seek(to: .init(seconds: 70, preferredTimescale: 44100))
//                player.play()
//
////                slks = player
//
//                NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: nil, queue: nil) {
//                    print(#function, $0)
//                }
//                //            let playWavAction = SKAction.playSound(wavUrl, waitForCompletion: true)
//            } catch {
//
//            }
//        }
//
//        if let view = self.view as! SKView? {
//            // Load the SKScene from 'GameScene.sks'
//            let scene = GameScene(size: CGSize(width: 500, height: 500))
//            scene.scaleMode = .aspectFill
//            view.presentScene(scene)
//
//            view.ignoresSiblingOrder = true
//
//            view.showsFPS = true
//            view.showsNodeCount = true
//            self.scene = scene
//        }
//
        let tap = UITapGestureRecognizer(target: self, action: #selector(tap(_:)))
        tap.numberOfTapsRequired = 2
        view.addGestureRecognizer(tap)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let rect = view.bounds
        scrollView.contentInset = .init(top: rect.height / 2,
                                        left: rect.width / 2,
                                        bottom: rect.height / 2,
                                        right: rect.width / 2)
    }
    
    var id = 0
    
    func change(_ no: Int) {
        label.text = "Map \(no)"
        guard let map = try? Map(named: "\(no)") else {
            return
        }
//        let size = contentView.tileSize
//        let width = size.width * .init(map.width)
//        let height = size.height * .init(map.height)
        id = no
        play(map.bgm)
        
        contentView.map = map
        contentView.reloadData()
//        scrollView.zoomScale = 1
//        scrollView.contentOffset = .init(x: -scrollView.adjustedContentInset.left, y: -scrollView.adjustedContentInset.top)
//        contentView.bounds = .init(x: 0, y: 0, width: width, height: height)
//        contentView.center = .init(x: width / 2, y: height / 2)
////        scrollView.contentSize = .init(width: width / scale, height: height / scale)
    }
    
    var lastBGM: String?
    
    func play(_ no: String) {
        guard lastBGM != no else {
            return
        }
        lastBGM = no
        guard let song = try? AudioPlayer.Item(named: no) else {
            return
        }
        if audioPlayer.items.isEmpty {
            audioPlayer.append(song)
            audioPlayer.play()
        } else {
            audioPlayer.append(song)
            audioPlayer.next()
        }
    }

    
    @objc func tap(_ : Any) {
        let nid = id + 1
        print(#function, nid)
        change(nid % 240)
        //
        //        let columns = map.width
        //        let rows = map.height
        //        tilemap?.numberOfRows = rows
        //        tilemap?.numberOfColumns = columns
        //
        //        for row in 0 ..< rows {
        //            for column in 0 ..< columns {
        //                let i = Int(map[column, rows - row - 1]) & 0xffff
        //                tilemap?.setTileGroup(tileGroups[i % 1904], forColumn: column, row: row)
        //            }
        //        }
        //
        //        children.forEach {
        //            $0.position = .zero
        //        }
        //
        ////        cameraNode.position = .zero
        //    }

    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        contentView.setNeedsLayout()
////        scene?.camera?.attributeValues.lazy
//        cameraNode.position.x = 5   // 水平滚动 5 点
//        cameraNode.position.y = 5   // 垂直滚动 5 点
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return contentView
    }
    

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
    
//    var scene: GameScene?
}
