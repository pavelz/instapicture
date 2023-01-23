//
//  VideoView.swift
//  instapicture
//
//  Created by Pavel Zaitsev on 8/13/20.
//  Copyright © 2020 Pavel Zaitsev. All rights reserved.
//

import Foundation
import AVKit
import CoreVideo
import SwiftHTTP


class VideoView: UIView {
    var url:String = ""
    var screenshot:String?
    var screenshotView:UIImageView?
    
    required init(url:String, screenshot:String){
        super.init(frame: CGRect.zero)
        self.url = url
        self.screenshot = screenshot
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didMoveToSuperview() {
        // TODO:
        // Load screenshot
        // onClick handler hides screenshot view and plays video
        if let url = screenshot {
            if url == "" {
                return
            }
            
            HTTP.GET(Config.serverURL() + url){ response in
                DispatchQueue.main.async {
                    let image = UIImage(data: response.data)
                    
                    let view = UIImageView()
                    self.screenshotView = view
                    view.image = image
                    if image?.size.width ?? 0 > image?.size.height ?? 0 {
                        view.contentMode = .scaleAspectFit                            //since the width > height we may fit it and we'll have bands on top/bottom
                    } else {
                        view.contentMode = .scaleAspectFill
                        //width < height we fill it until width is taken up and clipped on top/bottom
                    }
                    
                    var ratio:CGFloat = 1
                    if self.superview != nil && image != nil {
                        ratio = self.superview!.frame.size.width / image!.size.width
                    }

                    view.frame.size = CGSize(width: image!.size.width * ratio,height: image!.size.height * ratio)
                    self.frame.size = view.frame.size
                    //                self.frame = CGRect(x:0, y: 0,width: image!.size.width,height: image!.size.height)
                    self.addSubview(view)
                    
                    //                view.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
                    view.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
                    view.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
                    //                view.heightAnchor.constraint(equalToConstant: image!.size.height).isActive = true
                    view.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
                    print("SCREENSHOT SIZE: \(image!.size) \(self.frame) \(view.frame)")
                    
                }
            }
            
        }
    }
    // TODO playback here when video is loaded - hide UIImageView of screenshot
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context:  UnsafeMutableRawPointer?){
        
        if keyPath == #keyPath(AVPlayerItem.status) {
            let status: AVPlayerItem.Status
            
            // Get the status change from the change dictionary
            if let statusNumber = change?[.newKey] as? NSNumber {
                status = AVPlayerItem.Status(rawValue: statusNumber.intValue)!
            } else {
                status = .unknown
            }
            
            // Switch over the status
            switch status {
            case .readyToPlay:
                // Player item is ready to play.
                print("💥ready to play")
                print("\(self.playerLayer.videoRect)")
                self.bounds = self.playerLayer.videoRect
                self.layoutIfNeeded()
                self.screenshotView!.isHidden = true
                self.player!.play()
            case .failed:
                // Player item failed. See error.
                print("observable failed")
            case .unknown:
                // Player item is not yet ready.
                print("🤷‍♂️")
            }
        }
        
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("\(self.frame)")
        if(self.screenshot != nil){
            self.screenshotView!.isHidden = true
        }
        
        if self.player == nil {
            self.player = AVPlayer(url: URL(string: Config.serverURL() + self.url)!)
            var playerItemContext = 0
            self.player!.currentItem?.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), options: [ .old,.new], context: &playerItemContext)
        } else {
            self.player!.seek(to: CMTime(seconds: 0.1, preferredTimescale: 600))
            self.player!.play()
        }
    }
    var playerLayer: AVPlayerLayer {
        return layer as! AVPlayerLayer
    }
    var player: AVPlayer? {
        get {
            return playerLayer.player
        }
        set {
            playerLayer.player = newValue
        }
    }
    override func layoutSubviews() {
        print("layout subviews \(playerLayer.frame) \(self.frame) \(playerLayer.videoRect)")
        super.layoutSubviews()
    }

    // Override UIView propertyz
    override static var layerClass: AnyClass {
        return AVPlayerLayer.self
    }
}