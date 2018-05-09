//
//  AFRequest.swift
//  SwiftAFRequest
//
//  Created by YuanGu on 2018/5/9.
//  Copyright © 2018年 YuanGu. All rights reserved.
//

import UIKit
import SwiftyJSON
import AFNetworking

//枚举定义请求方式
enum HTTPRequestType {
    case GET
    case POST
}

let AirUrl = "https://www.cooldrivehud.com:8443/HUDServer/querycityair.action"

class AFRequest: AFHTTPSessionManager {
    
    //单例
    static let shared: AFRequest = {
        
        let manager = AFRequest(baseURL: NSURL(string: AirUrl)! as URL, sessionConfiguration: .default)
        
        let cerPath = Bundle.main.path(forResource: "HUDHttps", ofType: "cer")
        let certData = NSData(contentsOfFile: cerPath ?? "") as Data?
        
        var certSet: Set<Data> = []
        certSet.insert(certData!)
        
        manager.securityPolicy = AFSecurityPolicy.init(pinningMode: .certificate, withPinnedCertificates: certSet)
        //如果是需要验证自建证书，需要设置为YES
        manager.securityPolicy.allowInvalidCertificates = true
        //validatesDomainName 是否需要验证域名，默认为YES；
        manager.securityPolicy.validatesDomainName = true
        manager.responseSerializer = AFHTTPResponseSerializer()
        manager.responseSerializer.acceptableContentTypes = Set<AnyHashable>(["text/html", "text/plain", "application/json"]) as? Set<String>
        
        return manager
    }()
    
    func request(method: HTTPRequestType , urlString: String, parameters: AnyObject? ,result : @escaping(JSON?, Error?) -> ()){
        
        // 定义一个请求成功之后要执行的闭包
        // 成功闭包
        let success = { (task: URLSessionDataTask, response: Any?) in
            
            if let value = response as? [String: AnyObject] {
                
                let json = JSON(value)
                
                result(json ,nil)
            }
        }
        
        // 失败的闭包
        let failure = { (task: URLSessionDataTask?, error: Error) in
            result(nil, error)
        }
        
        // Get 请求
        if method == .GET {
            get(urlString, parameters: parameters, progress: nil, success: success, failure: failure)
        }
        
        // Post 请求
        if method == .POST {
            post(urlString, parameters: parameters, progress: nil, success: success, failure: failure)
        }
    }
    
    class func getRequest(urlString: String ,
                          parameters: [String: Any]? = nil,
                          complete:@escaping (_ percent: CGFloat) -> () ,
                          success:@escaping (_ response: AnyObject?) -> () ,
                          failure:@escaping (_ error: Error) -> ()) -> Void {
        
        AFRequest.shared.get(urlString, parameters: parameters, progress: { (value) in
            
            let percent: CGFloat = CGFloat(value.fractionCompleted)
            
            complete(percent)
            
        }, success: { (task, reponse) in
            
            success(reponse as AnyObject?)
            
        }) { (task, error) in
            
            failure(error)
        }
    }
    
    class func postRequest(urlString: String ,
                           parameters: [String: Any]? = nil,
                           complete:@escaping (_ percent: CGFloat) -> () ,
                           success:@escaping (_ response: Any?) -> () ,
                           failure:@escaping (_ error: Error) -> ()) -> Void {
        
        AFRequest.shared.post(urlString, parameters: parameters, progress: { (value) in
            
            let percent: CGFloat = CGFloat(value.fractionCompleted)
            
            complete(percent)
            
        }, success: { (task, reponse) in
            
            success(reponse as Any?)
        }) { (task, error) in
            
            failure(error)
        }
    }
    
    func getJsonParam(params: [String : Any]) -> [String : Any] {
        
        let data = try? JSONSerialization.data(withJSONObject: params, options: JSONSerialization.WritingOptions.prettyPrinted)
        
        let str = String(data:data!, encoding: String.Encoding.utf8)
        
        let jsonParam = ["json": str as Any]
        
        return jsonParam as Any as! [String : Any]
    }
}
