//
//  LoginController.swift
//  instapicture
//
//  Created by Pavel Zaitsev on 8/19/19.
//  Copyright © 2019 Pavel Zaitsev. All rights reserved.
//

import UIKit
import SwiftHTTP

class LoginController: UIViewController {

    @IBOutlet weak var Username: UITextField!
    @IBOutlet weak var Login: UIButton!
    
    @IBOutlet weak var Password: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func LogIn(){
        print("Login already")
        priznt(Username.text ?? "")
        print(Password.text ?? "")
        // http://kek.arslogi.ca:3001/users/sign_in
        let parameters: [String:Any] = [
            "user[email]": Username.text ?? "",
            "user[password]": Password.text ?? "",
            "user[mobile_type]": "ios",
            "user[mobile_key]":
            "APA91bG6G4UvjeCWvb8mMAH1ZO3I-8FB3nkRPyCHnwZiXgd16HK18GgoV5n7gjJtZNs038iaFGutzdxnhes3WyaXEX52-xmOyvuEK8S1abBdpuhD9AD5bzLWeu-1Ow_yZRTVg3Nypz1z"
            ]
        
            HTTP.POST("http://kek.arslogi.ca:3001/users/sign_in", parameters: parameters) { response in
                if let err = response.error {
                    print("Error: \(err.localizedDescription)")
                    return
                }
                
                print("posted login info!")
            }

    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
