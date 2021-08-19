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
import Locksmith
import NotificationBannerSwift
import MobileCoreServices


enum KeychainError: Swift.Error {
    case whoops
}
class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, CLLocationManagerDelegate {
    var locs: [CLLocation] = []
    @IBOutlet var selectPhoto: UIButton!
    @IBOutlet var takePhoto: UIButton!
    @IBOutlet var ImageView: UIImageView!
    
    @IBOutlet weak var MediaView: UIView!
    @IBOutlet var MainView: UIView!
    @IBOutlet var SendImage: UIButton!
    
    var upload_url:String = ""
    var upload_data:Data?
    var upload_filename:String?
    var upload_mime:String?
    var exportSession: AVAssetExportSession?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Config.serverURL()
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
        let session =  AVAudioSession.sharedInstance()
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
        locationManager.requestLocation()
        
        if UIImagePickerController.isSourceTypeAvailable(source){
            
            print("camera avail")
            let picker: UIImagePickerController = UIImagePickerController()
            
            picker.delegate = self
            picker.allowsEditing = true
            picker.sourceType = source
            picker.mediaTypes = [kUTTypeMovie as String,kUTTypeImage as String]    //UIImagePickerController.availableMediaTypes(for: .camera)!
            picker.cameraCaptureMode = .video

            picker.videoMaximumDuration = 4
            
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
        
        // TODO Video show and play VideoView sub
        if info[UIImagePickerController.InfoKey.mediaType] as! String == "public.image" {
            if let pickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
                ImageView = UIImageView() // FIXME do  not create again
                ImageView.contentMode = .scaleAspectFill
                ImageView.clipsToBounds = true
                ImageView.image = pickedImage
                upload_url = "/photos"
                upload_mime = "image/jpeg"
                upload_filename = "image.jpg"
                upload_data = pickedImage.jpegData(compressionQuality: 0.4)
                
                MediaView.addSubview(ImageView)
            }
        }
        
        if info[UIImagePickerController.InfoKey.mediaType] as! String == "public.movie" {
            if let url = info[UIImagePickerController.InfoKey.mediaURL] as? URL {

                let player = AVPlayer(url: url)
                let view = VideoView(url: url.absoluteString, screenshot: "")
                view.player = player
                view.playerLayer.videoGravity = .resizeAspect
                view.frame = MainView.frame

                MediaView.addSubview(view)

                // TODO convert to mp4
                
                upload_url = "/videos"
                upload_filename = url.lastPathComponent.lowercased()
                upload_mime = "video/quicktime"
                let group = DispatchGroup()
                group.enter()
                encodeVideo(videoURL: url as NSURL, group: group)
                group.wait()
                let ourl:URL = exportSession!.outputURL!
                upload_data = try! Data(contentsOf: ourl)
                upload_filename = ourl.lastPathComponent.lowercased()
                upload_mime = "video/mp4"
                
                view.player!.play()
            }
            
        }
        picker.dismiss(animated: true, completion: nil)

    }
    static func copyConstraints(fromView sourceView: UIView, toView destView: UIView) {
        guard let sourceViewSuperview = sourceView.superview else {
            return
        }
        for constraint in sourceViewSuperview.constraints {
            if constraint.firstItem as? UIView == sourceView {
                sourceViewSuperview.addConstraint(NSLayoutConstraint(item: destView, attribute: constraint.firstAttribute, relatedBy: constraint.relation, toItem: constraint.secondItem, attribute: constraint.secondAttribute, multiplier: constraint.multiplier, constant: constraint.constant))
            } else if constraint.secondItem as? UIView == sourceView {
                sourceViewSuperview.addConstraint(NSLayoutConstraint(item: constraint.firstItem, attribute: constraint.firstAttribute, relatedBy: constraint.relation, toItem: destView, attribute: constraint.secondAttribute, multiplier: constraint.multiplier, constant: constraint.constant))
            }
        }
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
        
        if locs.count == 0 {
            return
        }
        
        print("about to send")
        let locker = Locksmith.loadDataForUserAccount(userAccount: "account")
        let token = locker?["token"]
        var filename_param = "photo[name]"
        var data_param = "photo[image]"
        if upload_mime == "video/quicktime" || upload_mime == "video/mp4" {
            filename_param = "video[name]"
            data_param = "video[video]"
        }
        let parameters: [String:Any] = [
            filename_param: upload_filename!,
             data_param: Upload(data:upload_data!, fileName: upload_filename!, mimeType: upload_mime! ),
            "location[lat]": NSString(format: "%f",locs[0].coordinate.latitude as Double),
            "location[lng]": NSString(format: "%f",locs[0].coordinate.longitude as Double)
        ]
        
        let popup = {(message: String) in
            DispatchQueue.main.async {
                print("POPUP is CALLED\n")
                let banner  = NotificationBanner(title: message, style: .success)
                banner.haptic = .heavy
                banner.show()
            }
        }
        print("SENDING\n")
        HTTP.POST(Config.serverURL() + upload_url, parameters: parameters, headers: [
            "X-User-Email": locker?["email"] as? String ?? "",
            "X-User-Token": token as? String ?? ""
        ]) { response in
            
            if let err = response.error {
                print("Error: \(err.localizedDescription)")
                popup("Error uploading photo.")
                return  
            } else {					                print("\(response.description)")
                print("\(response.data)")
                popup("Photo pploaded.")
            }
        }
    }
    
    func encodeVideo(videoURL: NSURL, group: DispatchGroup)  {
        let avAsset = AVURLAsset(url: videoURL as URL, options: nil)
        
        let startDate = NSDate()
        
        // Create Export session
        exportSession = AVAssetExportSession(asset: avAsset, presetName: AVAssetExportPresetPassthrough)
        
        // exportSession = AVAssetExportSession(asset: composition, presetName: mp4Quality)
        //Creating temp path to save the converted video
        
        
        let documentsDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let myDocumentPath = NSURL(fileURLWithPath: documentsDirectory).appendingPathComponent("temp.mp4")?.absoluteString

        let documentsDirectory2 = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0] as NSURL
        
        let filePath = documentsDirectory2.appendingPathComponent("rendered-Video.mp4")
        deleteFile(filePath: filePath! as NSURL)
        
        //Check if the file already exists then remove the previous file
        if FileManager.default.fileExists(atPath: myDocumentPath ?? "") {
            do {
                try FileManager.default.removeItem(atPath: myDocumentPath ?? "")
            }
            catch let error {
                print(error)
            }
        }
        

        exportSession!.outputURL = filePath
        exportSession!.outputFileType = AVFileType.mp4
        exportSession!.shouldOptimizeForNetworkUse = true
        let start = CMTimeMakeWithSeconds(0.0, preferredTimescale: 0)
        let range = CMTimeRangeMake(start: start, duration: avAsset.duration)
        exportSession?.timeRange = range
        
        exportSession!.exportAsynchronously(completionHandler: {() -> Void in
            switch self.exportSession!.status {
            case .failed:
                print("%@",self.exportSession?.error as Any)
            case .cancelled:
                print("Export canceled")
            case .completed:
                //Video conversion finished
                let endDate = NSDate()
                
                let time = endDate.timeIntervalSince(startDate as Date)
                print(time)
                print("Successful!")
                print(self.exportSession?.outputURL as Any)
                
            default:
                break
            }
            group.leave()
            
        })
        
        
    }
    
    func deleteFile(filePath:NSURL) {
        guard FileManager.default.fileExists(atPath: filePath.path!) else {
            return
        }
        
        do {
            try FileManager.default.removeItem(atPath: filePath.path!)
        }catch{
            fatalError("Unable to delete file: \(error) : \(#function).")
        }
    }
}

