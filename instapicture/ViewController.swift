//
//  ViewController.swift
//  instapicture
//
//  Created by Pavel Zaitsev on 3/30/19.
//  Copyright © 2019 Pavel Zaitsev. All rights reserved.
//

import UIKit
import SwiftHTTP
import UserNotifications
import CoreLocation
import CloudKit
import AVKit

enum KeychainError: Swift.Error {
    case whoops
}
class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, CLLocationManagerDelegate {
    var locs: [CLLocation] = []
    @IBOutlet var selectPhoto: UIButton!
    @IBOutlet var takePhoto: UIButton!
    @IBOutlet var ImageView: UIImageView!
    
    @IBOutlet var SendImage: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        Config.serverURL()
        // Do any additional setup after loading the view, typically from a nib.
        let center = UNUserNotificationCenter.current()
        
        center.requestAuthorization(options: [.alert, .badge, .sound]) { (granted, error) in
            if granted {
                print("Yay!")
            } else {
                print("D'oh")
            }
        }
        // audio video session
        var session =  AVAudioSession.sharedInstance()
        do {
            try session.setCategory(AVAudioSession.Category.record, mode: AVAudioSession.Mode.default, options: [])
        } catch is NSError {
            print("Audio Session whoops")
        }
        
        enableLocationServices()
    }

    func findUserPassword() throws -> String {
        let server = "kek.arslogi.ca"

        let query: [String: Any] = [kSecClass as String: kSecClassInternetPassword,
                                    kSecAttrServer as String: server,
                                    kSecMatchLimit as String: kSecMatchLimitOne,
                                    kSecReturnAttributes as String: true,
                                    kSecReturnData as String: true]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        if status != errSecItemNotFound {print("password found")} else {print("passworod not found");print(status)}
        if status == errSecSuccess {print("indeed found")} else { print("wth some error");print(status); }

        // extract password
        guard let existingItem = item as? [String : Any],
              let passwordData = existingItem[kSecValueData as String] as? Data,
              let password = String(data: passwordData, encoding: String.Encoding.utf8),
              let account = existingItem[kSecAttrAccount as String] as? String
        else {
            throw KeychainError.whoops
        }

        //let credentials = Credentials(username: account, password: password)
        return password
    }

    func addAuthUser(account: String, password: String) {
        let server = "kek.arslogi.ca"
        var query: [String: Any] = [kSecClass as String: kSecClassInternetPassword,
                                    kSecAttrAccount as String: account,
                                    kSecAttrServer as String: server,
                                    kSecValueData as String: password]

        let status = SecItemAdd(query as CFDictionary, nil)
        if status == errSecSuccess {print("Success Storing password")} else { print(status); print("error storing password"); }
    }

    func setAuthUser(account: String, pasword: String) {

    }


    let locationManager = CLLocationManager()
    func enableLocationServices() {
        locationManager.delegate = self
         false
        switch CLLocationManager.authorizationStatus() {
        case .notDetermined:
            // Request when-in-use authorization initially
            locationManager.requestWhenInUseAuthorization()
            break
            
        case .restricted, .denied:
            // Disable location features
            //disableMyLocationBasedFeatures()
            break
            
        case .authorizedWhenInUse:
            // Enable basic location features
            //enableMyWhenInUseFeatures()
            break
            
        case .authorizedAlways:
            // Enable any of your app's location features
            //enableMyAlwaysFeatures()
            break
        }
    }

    func selectImage(source:UIImagePickerController.SourceType){
        if UIImagePickerController.isSourceTypeAvailable(source){
            print("camera avail")
            let picker: UIImagePickerController = UIImagePickerController()
            
            picker.delegate = self
            picker.allowsEditing = true
            picker.sourceType = source
            self.present(picker, animated:true, completion: nil)
        }
    }
    @IBAction func takePhoto(button: UIButton){
        selectImage(source: .camera)
    }
    
    @IBAction func pickImage(_ sender: Any) {
        selectImage(source: .photoLibrary)
    }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Error")
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("Locate \(locations)")
        locs = locations
    }
    
 

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        if let pickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            ImageView.contentMode = .scaleAspectFill    
            ImageView.clipsToBounds = true
            ImageView.image = pickedImage
            locationManager.requestLocation()
        }

        picker.dismiss(animated: true, completion: nil)
    }
    
    func scheduleNotification() {
        let center = UNUserNotificationCenter.current()
        
        let content = UNMutableNotificationContent()
        content.title = "Late wake up call"
        content.body = "The early bird catches the worm, but the second mouse gets the cheese."
        content.badge = 1
        content.sound = UNNotificationSound.default
        

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5.0, repeats: false)
        print("triggering")
        let request = UNNotificationRequest(identifier: "notification", content: content, trigger: trigger)
        center.add(request,withCompletionHandler: nil)
        print("triggered")
    }
    
    @IBAction func SendImage(button: UIButton){
        print("send pressed")
        let data = ImageView.image?.jpegData(compressionQuality: 0.1)
        if locs.count == 0 {
            return
        }

        if let image = data {
            print("about to send")
            let parameters: [String:Any] = [
                "photo[name]": "image.jpg",
                "photo[image]": Upload(data:image, fileName: "image.jpg", mimeType: "image/jpeg" ),
                "location[lat]": NSString(format: "%f",locs[0].coordinate.latitude as Double),
                "location[lng]": NSString(format: "%f",locs[0].coordinate.longitude as Double)
            ]
            
            HTTP.POST(Config.serverURL() + "/photos", parameters: parameters) { response in

                if let err = response.error {
                    print("Error: \(err.localizedDescription)")
                    return
                } else {
                    print("\(response.description)")
                    print("\(response.data)")
                }

                print("sent")
                self.scheduleNotification()
            }
        }
    }
    
}

