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

struct MediaItem: Codable {
    let image: Data

    enum CodingKeys: String, CodingKey { // FIX for 'class' field
        case image = "image"
    }
}

class FeedController: UIViewController, UINavigationControllerDelegate {

    @IBOutlet weak var Scroller: UIScrollView!
    @IBOutlet weak var Images: UIStackView!
    @IBOutlet var MainView: UIView!

    @IBAction func takePhoto(_ sender: Any) {
        DispatchQueue.main.async {
            self.performSegue(withIdentifier: "take_photo", sender: nil)
        }
    }

    override func viewDidLoad() {
        let locker = Locksmith.loadDataForUserAccount(userAccount: "account")
        HTTP.GET(Config.serverURL() + "/photos.json", headers: [
            "X-User-Email": locker?["email"] as? String ?? "",
            "X-User-Token": locker?["token"] as? String ?? ""
        ]) { response in
            // populate UI elements - images
            let decoder = JSONDecoder()
            let data:[MediaItem]
            do {
                data = try decoder.decode([MediaItem].self, from: response.data)
            } catch {
                print("THERE was an error getting photos")
                return
            }

            DispatchQueue.main.async {
                print("IMAGES")
                var height = 0;
                self.Images.distribution = .fillProportionally
                self.Images.spacing = 40
                self.Images.translatesAutoresizingMaskIntoConstraints = false


//                self.Images.heightAnchor.constraint(equalToConstant: self.Scroller.frame.height - 100).isActive = true
//                self.Images.widthAnchor.constraint(equalToConstant: self.Scroller.frame.width - 40).isActive = true
//                self.Images.centerYAnchor.constraint(equalTo: self.Scroller.centerYAnchor).isActive = true
                //self.Images.centerXAnchor.constraint(equalTo: self.Scroller.centerXAnchor).isActive = true

                for bit in data {
                    //print(bit.url)

                    let image = UIImage(data: bit.image)
                    height += Int(image?.size.height ?? 0) + 60 // 40 - spacing set above

                    let imageView = UIImageView()

                    if image?.size.width ?? 0.0 > image?.size.height ?? 0.0 {
                        imageView.contentMode = .scaleAspectFit
                        //since the width > height we may fit it and we'll have bands on top/bottom
                    } else {
                        imageView.contentMode = .scaleAspectFill
                        //width < height we fill it until width is taken up and clipped on top/bottom
                    }
                    imageView.image = image

                    var displayimageHeightConstraint: NSLayoutConstraint! = nil
                    if imageView.frame.size.width < imageView.image?.size.width ?? 0 {

                        let constant = imageView.frame.size.width / (imageView.image?.size.width)! * (imageView.image?.size.height)!
                        displayimageHeightConstraint = NSLayoutConstraint(item: imageView, attribute: .width, relatedBy: .equal, toItem: imageView, attribute: .height, multiplier: 1, constant: constant)
                        imageView.addConstraint(displayimageHeightConstraint)
                    }

                    print("size \(image?.size)")
                    //imageView.frame.size = CGSize(width: image?.size.width ?? 0, height: image?.size.height ?? 0)
                    self.Images.addArrangedSubview(imageView)
                }
                self.Scroller.contentSize = CGSize(width: 400, height: height)
                print("height: \(height)")
            }
        }
    }

    @IBAction func LogOut() {
        var locker = Locksmith.loadDataForUserAccount(userAccount: "account")
        locker?.removeAll()
        DispatchQueue.main.async {
            self.performSegue(withIdentifier: "logout_to_main", sender: nil)
        }
    }
}
