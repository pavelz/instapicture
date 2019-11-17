//
// Created by Pavel Zaitsev on 11/14/19.
// Copyright (c) 2019 Pavel Zaitsev. All rights reserved.
//

import Foundation
import SwiftHTTP

class Config {
    static var url = ""

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
                    HTTP.GET(str + "/alive"){response in
                        print("@@@@@@")
                        if let err = response.error {
                            print("Error: \(err.localizedDescription)")
                            lol.unlock()
                            return
                        } else {
                            print("SUCCESS \(str)")
                            rett = str
                            lol.unlock()
                        }
                    }
                    lol.lock()
                })
                print("LIVE SERVER \(rett)")
                return rett
            default:
                url = "\(url)"
            }
        }
        return rett
    }
}
