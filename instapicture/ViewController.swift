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

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, CLLocationManagerDelegate {
    var locs: [CLLocation] = []
    @IBOutlet var selectPhoto: UIButton!
    @IBOutlet var takePhoto: UIButton!
    @IBOutlet var ImageView: UIImageView!
    
    @IBOutlet var SendImage: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let center = UNUserNotificationCenter.current()
        
        center.requestAuthorization(options: [.alert, .badge, .sound]) { (granted, error) in
            if granted {
                print("Yay!")
            } else {
                print("D'oh")
            }
        }
        
        enableLocationServices()
    }
    
    let locationManager = CLLocationManager()
    func enableLocationServices() {
        locationManager.delegate = self
        
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

    
    
    @IBAction func takePhoto(button: UIButton){
        if UIImagePickerController.isSourceTypeAvailable(.camera){
            print("camera avail")
            let picker: UIImagePickerController = UIImagePickerController()

            picker.delegate = self
            picker.allowsEditing = true
            picker.sourceType = .camera
            self.present(picker, animated:true, completion: nil)
        }
    }
    
    @IBAction func pickImage(_ sender: Any) {
        //scheduleNotification()
        locationManager.requestLocation()
        
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
            ImageView.image = pickedImage
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
        
        print("Hey")
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5.0, repeats: false)
        print("triggering")
        let request = UNNotificationRequest(identifier: "notification", content: content, trigger: trigger)
        center.add(request,withCompletionHandler: nil)
        print("triggered")
    }
    
    @IBAction func SendImage(button: UIButton){
        let data = ImageView.image?.jpegData(compressionQuality: 0.1)
        if locs.count == 0 {
            return
        }

        if let image = data {
            
            let paramet : [String:Any] = [
                "photo[name]": "image.jpg",
                "photo[image]": Upload(data:image, fileName: "image.jpg", mimeType: "image/jpeg" ),
                "location[lat]": NSString(format: "%f",locs[0].coordinate.latitude as Double),
11                "location[lngZ1]": NSString(format: "%f",locs[0].coordinate.longitude as Double)
            ]
            
            HTTP.POST("http://kek.arslogi.ca:3001/photos", parameters: paramet) { response in
                if let err = response.error {
                    print("Error: \(err.localizedDescription)")
                    return
                }
                self.scheduleNotification()
            }
        }
    }
    
}

