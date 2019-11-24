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
        var rett = ""
        if(url != ""){ // return relevan url
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
            var url = ""
            switch(data){

            case let ff as Array<String>:
                var lol = NSLock()
                ff.forEach({ (str) -> Void in
                    if rett != "" {
                        return
                    }
                    print("TRY: \(str)/alive")
                    print("RETT \(rett)")
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
                                print("response \(response)")
                                print("data \(String(data: data, encoding: .utf8)!)")
                                rett = url
                            }
                        }
                        dataTask?.resume()

                    }

//                    HTTP.GET(str + "/alive"){response in
//                        print("@@@@@@")
//                        if let err = response.error {
//                            print("Error: \(err.localizedDescription)")
//                            lol.unlock()
//                            return
//                        } else {
//                            print("SUCCESS \(str)")
//                            rett = str
//                            lol.unlock()
//                        }
//                    }
//                    lol.lock()
                })
                print("LIVE SERVER \(rett)")
                return rett
            default:
                url = "\(url)"
            }
        }
        var dispatchGroup = DispatchGroup()
        dispatchGroup.notify(queue: .main){
            print ("WOO")
        }
        return rett
    }
}
