//
//  LoginController.swift
//  instapicture
//
//  Created by Pavel Zaitsev on 8/19/19.
//  Copyright © 2019 Pavel Zaitsev. All rights reserved.
//

import UIKit
import SwiftHTTP
import Locksmith

class RailsResponse: Codable{
    var email: String
    var authentication_token: String
}

class LoginController: UIViewController, UITextFieldDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var Username: UITextField!
    @IBOutlet weak var Login: UIButton!

    @IBOutlet weak var Password: UITextField!
    override func viewDidLoad() {
        self.Password.delegate = self
        super.viewDidLoad()

        let serverUrl = Config.serverURL()

//        let locker = Locksmith.loadDataForUserAccount(userAccount: "account")
//        print("TOKEN")
//        if locker?["token"] != nil {
//            DispatchQueue.main.async {
//                self.performSegue(withIdentifier: "go", sender: nil)
//            }
//        }

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

        HTTP.POST(
                Config.serverURL() + "/users/sign_in",
                parameters: parameters,
                headers: ["ContentType":"application/json", "Accept":"application/json"],
                requestSerializer: JSONParameterSerializer()
        ) { response in
                if let err = response.error {
                    print("Error: \(err.localizedDescription)")
                    return
                }
                let decoder = JSONDecoder()
                    print("RESPONSE: ")
                    print(response.data)
                    let data = try! decoder.decode(RailsResponse.self, from: response.data)
                    print(data.authentication_token)
                    print("TOKEN")
//                    if locker?["token"] != nil {
//                        DispatchQueue.main.async {
//                            self.performSegue(withIdentifier: "go", sender: nil)
//                        }
//                    }

                    DispatchQueue.main.async {
                        do {
                            let locker = Locksmith.loadDataForUserAccount(userAccount: "account")
                            print(locker)
                            if locker?["email"] != nil {
                                print("Update login info")
                                try Locksmith.updateData(data: ["token": data.authentication_token,"email": self.Username.text ?? ""], forUserAccount: "account")
                            } else {
                                print("New login info")
                                try Locksmith.saveData(data: ["token": data.authentication_token, "email": self.Username.text ?? ""], forUserAccount: "account")
                            }

                        } catch {
                            print("ERROR saving a token")
                        }
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
