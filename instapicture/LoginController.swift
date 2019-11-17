//
//  LoginController.swift
//  instapicture
//
//  Created by Pavel Zaitsev on 8/19/19.
//  Copyright © 2019 Pavel Zaitsev. All rights reserved.
//

import UIKit
import SwiftHTTP

class RailsResponse: Codable{
    var email: String
    var authentication_token: String
}

class LoginController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var Username: UITextField!
    @IBOutlet weak var Login: UIButton!
    
    @IBOutlet weak var Password: UITextField!
    override func viewDidLoad() {
        self.Password.delegate = self
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == Password {
            textField.resignFirstResponder()
            LogIn()
            return false
        }
        return true
    }
    
    @IBAction func LogIn(){
        print("Login already")
        print(Username.text ?? "")
        print(Password.text ?? "")
        
        // http://kek.arslogi.ca:3001/users/sign_in
        let parameters: [String:Any] = [
            "user": [
            "email": Username.text ?? "",
            "password": Password.text ?? ""
            ]
        ]
        
        HTTP.POST("http://127.0.0.1:3001/users/sign_in", parameters: parameters, headers: ["ContentType":"application/json", "Accept":"application/json"], requestSerializer: JSONParameterSerializer()) { response in
                if let err = response.error {
                    print("Error: \(err.localizedDescription)")
                    return
                }
                let decoder = JSONDecoder()
        
                    let data = try! decoder.decode(RailsResponse.self, from: response.data)
                    print(data.authentication_token)
            
                    DispatchQueue.main.async {
                        self.performSegue(withIdentifier: "go", sender: nil)
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
