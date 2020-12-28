//
//  ImageView.swift
//  instapicture
//
//  Created by Pavel Zaitsev on 8/15/20.
//  Copyright © 2020 Pavel Zaitsev. All rights reserved.
//

import Foundation
import UIKit
import SwiftHTTP

class ImageView: UIImageView {
    var url:String
    init(url:String) {
        self.url = url
        super.init(frame: CGRect.zero)
        //self.gestureRecognizers?.removeAll()
        self.isUserInteractionEnabled = true

        let recognizer = UITapGestureRecognizer(target: self, action: #selector(self.touch))
        recognizer.numberOfTapsRequired = 1
        recognizer.numberOfTouchesRequired = 1
        self.addGestureRecognizer(recognizer)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didMoveToSuperview(){
        // Load image
        var height = 0;
        HTTP.GET(Config.serverURL() + url){ response in
                DispatchQueue.main.async {
                    
                    let image = UIImage(data: response.data)
                    height += Int(image?.size.height ?? 0) + 60 // 40 - spacing set above
                                        
                    self.image = image
                    if image?.size.width ?? 0 > image?.size.height ?? 0 {
                        self.contentMode = .scaleAspectFit                            //since the width > height we may fit it and we'll have bands on top/bottom
                    } else {
                        self.contentMode = .scaleAspectFill
                        //width < height we fill it until width is taken up and clipped on top/bottom
                    }
                    self.frame.size = CGSize(width: image?.size.width ?? 0, height: image?.size.height ?? 0)
                }

        }
    }
    @objc func touch(e: UITapGestureRecognizer){
        print("\(e.view!.frame)")
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("\(self.frame)")
    }
}
