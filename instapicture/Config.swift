//
// Created by Pavel Zaitsev on 11/14/19.
// Copyright (c) 2019 Pavel Zaitsev. All rights reserved.
//

import Foundation
import SwiftHTTP

class Config {
    static var url = ""

    static var dataTask: URLSessionDataTask? = nil
    class func serverURL() -> String{
        var dict: NSDictionary?
        if(url != ""){ // return relevant url
            print("######## SERVER URL is already set \(url)")
            return url
        }
        // figure out one of valid urls to work with.
        // TODO there is an issue with tokens being invalidated if url is different.

        if let path = Bundle.main.path(forResource: "Info", ofType: "plist") {
            dict = NSDictionary(contentsOfFile: path)
        }

        if let dictt = dict {
            var data = dictt.object(forKey: "ServerConfig")
            switch(data){

                case let ff as Array<String>:
                    var lol = NSLock()
                    ff.forEach({ (str) -> Void in
                        print("TRY: \(str)/alive")

                        var s = URLSession(configuration: .default)
                        var st: URLSessionDataTask?
                        if var uc = URLComponents(string: str + "/alive") {
                            guard let a_url = uc.url else {
                                return
                            }

                            //dataTask?.cancel()
                            dataTask = s.dataTask(with: a_url) {  data, response, error in
                                defer {
                                    Config.dataTask = nil
                                }

                                if let error = error {
                                    print("task error: \(error.localizedDescription)")
                                }else if let data = data, let response = response as? HTTPURLResponse,
                                         response.statusCode == 200 {
                                    if(url == "") {
                                        print("Seting URL to : \(str)")

                                        url = str

                                    }
                                    print("response \(response)")
                                    print("data \(String(data: data, encoding: .utf8)!)")
                                }
                            }
                            dataTask?.resume()

                        }

                    })
                    return url
                default:
                    url = "\(url)"
                }
        }
        var dispatchGroup = DispatchGroup()
        dispatchGroup.notify(queue: .main){
        }
        return url
    }
}
