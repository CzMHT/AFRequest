//
//  ALRequest.swift
//  AlamofireRequest
//
//  Created by YuanGu on 2018/5/9.
//  Copyright © 2018年 YuanGu. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

enum RequestMethod {
    case get
    case post
}

let AirUrl = "https://www.cooldrivehud.com:8443/HUDServer/querycityair.action"

class ALRequest: NSObject {

    fileprivate static let shareInstance = ALRequest()
    class var shareRequest: ALRequest{
        return shareInstance
    }
    
    override init() {
        super.init()
        SRAlamofireHttpsConfigure.sharedInstance.configAlamofireManager()
    }
    
    public func request(method: RequestMethod ,url: String ,params: [String : Any]? = nil ,success:@escaping (_ response: JSON)->() ,failure:@escaping(_ error: Error)->()) -> Void {
        
        let headers:HTTPHeaders = ["Content-type":"application/json;charset=utf-8",
                                   "Accept":"text/plain"]
        Alamofire.request(url,
                          method: .post,
                          parameters: params ,
                          encoding: URLEncoding.default ,
                          headers: headers)
            .validate(contentType: ["text/html" ,"text/plain" ,"application/json"])
            .responseJSON { (response) in
                
                switch response.result {
                    
                case .success( _):
                    
                    if let value = response.result.value as? [String: AnyObject] {
                        
                        let json = JSON(value)
                        
                        success(json)
                    }
                case .failure(let error):
                    
                    failure(error)
                    
                    print("AL error:\(error)")
                }
        }
    }
}
