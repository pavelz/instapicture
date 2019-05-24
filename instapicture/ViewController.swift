//
//  ViewController.swift
//  instapicture
//
//  Created by Pavel Zaitsev on 3/30/19.
//  Copyright © 2019 Pavel Zaitsev. All rights reserved.
//

import UIKit
import SwiftHTTP

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet var selectPhoto: UIButton!
    @IBOutlet var takePhoto: UIButton!
    @IBOutlet var ImageView: UIImageView!
    
    @IBOutlet var SendImage: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    @IBAction func takePhoto(button: UIButton){
        if UIImagePickerController.isSourceTypeAvailable(.camera){
            let picker: UIImagePickerController = UIImagePickerController()

            picker.delegate = self
            picker.allowsEditing = true
            picker.sourceType = .camera
            self.present(picker, animated:true, completion: nil)

        }
    }
    
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let pickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            ImageView.contentMode = .scaleToFill
            ImageView.image = pickedImage
        }
        
        picker.dismiss(animated: true, completion: nil)
     }
    
    
    @IBAction func SendImage(button: UIButton){
        let data = ImageView.image?.jpegData(compressionQuality: 0.1)
        if let image = data {
            HTTP.POST("http://kek.arslogi.ca:3001/photos",parameters: ["photo[name]": "image.jpg" ,"photo[image]": Upload(data: image, fileName: "image.jpg", mimeType: "image/jpeg" )]) { response in
                if let err = response.error {
                    print("Error: \(err.localizedDescription)")
                    return
                }
            }
        }
        
    }
    
}

