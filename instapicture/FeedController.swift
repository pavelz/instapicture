//
// Created by Pavel Zaitsev on 5/10/20.
// Copyright (c) 2020 Pavel Zaitsev. All rights reserved.
//

import Foundation
import UIKit
import SwiftHTTP
import Locksmith
import SwiftyJSON
import CoreGraphics
import AVKit

struct MediaItem: Codable {
    let url: String
    let className: String
    let screenshot: String
    
    enum CodingKeys: String, CodingKey { // FIX for 'class' field
        case className = "class"
        case url = "url"
        case screenshot = "screenshot"
    }
}

class FeedController: UIViewController, UINavigationControllerDelegate {
    
    @IBOutlet weak var Scroller: UIScrollView!
    @IBOutlet weak var Images: UIStackView!
    @IBOutlet var MainView: UIView!
    
    var refreshControl = UIRefreshControl()
    
    @IBAction func takePhoto(_ sender: Any) {
        DispatchQueue.main.async {
            self.performSegue(withIdentifier: "take_photo", sender: nil)
        }
    }
    
    override func viewDidLoad() {
        // refresh the feed
        refreshControl.addTarget(self, action: #selector(self.refresh(_:)), for: .valueChanged)
        Scroller.addSubview(refreshControl)
        loadFeed()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
    }
    @objc func tapTap(sender: UITapGestureRecognizer){
        print("\(sender.view!.frame)")
    }
    // TODO can probably incrementally load views
    func loadFeed(){
        let locker = Locksmith.loadDataForUserAccount(userAccount: "account")
        HTTP.GET(Config.serverURL() + "/photos.json", headers: [
            "X-User-Email": locker?["email"] as? String ?? "",
            "X-User-Token": locker?["token"] as? String ?? ""
        ]) { response in
            // populate UI elements - images
            let decoder = JSONDecoder()
            let data = try! decoder.decode([MediaItem].self, from: response.data)
            
            DispatchQueue.main.async {
                print("IMAGES")
                var height = 0;
                self.Images.distribution = .fillProportionally
                self.Images.spacing = 40
                self.Images.translatesAutoresizingMaskIntoConstraints = false
                
                self.Images.subviews.forEach({ $0.removeFromSuperview() })
                
                for bit in data {
                    print(bit.url)
                    var image_url = ""
                    
                    if(bit.className == "Photo") {
                        print("📷")
                        image_url = bit.url
                    } else {
                        print("🎥")
                        image_url = bit.screenshot
                    }
                    
                    switch bit.className {
                    case "Photo":
                        let view = ImageView(url: bit.url)
                        self.Images.addArrangedSubview(view)
                    case "Video":
                        let view = VideoView(url: bit.url, screenshot: bit.screenshot)
                        self.Images.addArrangedSubview(view)
                    default:
                        print("💩 what kind of view is that? \(bit)")
                    }

//                    HTTP.GET(Config.serverURL() +  image_url){ response in
//                            DispatchQueue.main.async {
//                                
//                                let image = UIImage(data: response.data)
//                                height += Int(image?.size.height ?? 0) + 60 // 40 - spacing set above
//                                
//                                let view = ImageView()
//                                
//                                view.image = image
//                                if image?.size.width ?? 0 > image?.size.height ?? 0 {
//                                    view.contentMode = .scaleAspectFit                            //since the width > height we may fit it and we'll have bands on top/bottom
//                                } else {
//                                    view.contentMode = .scaleAspectFill
//                                    //width < height we fill it until width is taken up and clipped on top/bottom
//                                }
//                                view.frame.size = CGSize(width: image?.size.width ?? 0, height: image?.size.height ?? 0)
//                                self.Images.addArrangedSubview(view)
//                            }
//                            
//                    }
                    
//                    if(bit.className == "Video"){
//                        DispatchQueue.main.async {
//
//                            // display screenshot.
//                            // 1 move all this code into video view
//                            // 2 move code above for photos in to photo view
//
//                            let screenshot = UIImage()
//
//                            HTTP.GET(Config.serverURL() +  bit.screenshot){ response in
//
//                            }
//
//                            let player = AVPlayer(url: URL(string: "https://arslogi.ca" + bit.url)!)
//                            let view = VideoView(url: bit.url, screenshot: bit.screenshot)
//                            view.player = player
//                            //view.playerLayer.videoGravity = .resizeAspect
//
//                            //                        let playerLayer = AVPlayerLayer(player: player)
//                            //                        view.playerLayer.frame.size = CGSize(width: 300, height: 200)
//
//                            //view.frame.size = CGSize(width: 200, height: 100)
//                            //                        view.frame.origin = .zero
//                            //                        view.playerLayer = playerLayer
//
//                            //                        playerLayer.needsDisplayOnBoundsChange = true
//                            //view.layer.addSublayer(playerLayer)
//
//                            self.Images.addArrangedSubview(view)
//
//                            player.seek(to: CMTime(seconds: 0.1, preferredTimescale: 500))
//                            view.leftAnchor.constraint(equalTo: self.Images.leftAnchor).isActive = true
//                            view.rightAnchor.constraint(equalTo: self.Images.rightAnchor).isActive = true
//                            //                        view.topAnchor.constraint(equalTo: self.Images.topAnchor).isActive = true
//                            let videoRect = view.playerLayer.videoRect
//                            print("🍔 NATURAL SIZE \(player.currentItem?.asset.tracks(withMediaType: .video)[0].naturalSize)")
//                            view.heightAnchor.constraint(equalToConstant: (player.currentItem?.asset.tracks(withMediaType: .video)[0].naturalSize.height)!).isActive = true // This is a sync action that is SLOW - all videos must be pre-loaded before getting sizing info.
//
//
//                            var playerItemContext = 0
//                            player.currentItem?.addObserver(view, forKeyPath: #keyPath(AVPlayerItem.status), options: [.initial,.prior, .old,.new], context: &playerItemContext)
//                            //                        player.play()
//
//                        }
//                    }
                    
                }
                
                //self.Scroller.contentSize = CGSize(width: 400, height: height)
                print("height: \(height)")
                
                self.refreshControl.endRefreshing()
            }
        }
    }
    
    @objc func refresh(_ sender: AnyObject) {
        // Code to refresh table view
        loadFeed()
    }
    
    @IBAction func LogOut() {
        var locker = Locksmith.loadDataForUserAccount(userAccount: "account")
        locker?.removeAll()
        DispatchQueue.main.async {
            self.performSegue(withIdentifier: "logout_to_main", sender: nil)
        }
    }
}
