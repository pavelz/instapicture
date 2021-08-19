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

                }
                
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
