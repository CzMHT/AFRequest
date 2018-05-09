//
//  SRAlamofireHttpsConfigure.swift
//  AlamofireRequest
//
//  Created by YuanGu on 2018/5/9.
//  Copyright © 2018年 YuanGu. All rights reserved.
//

import UIKit
import Alamofire

class SRAlamofireHttpsConfigure: NSObject {
    
    let ClientCerName: String = ""
    let ServerCerName: String = "HUDHttps.cer"
    let SignedHosts = ["www.cooldrivehud.com"] //自签名认证主机
    
    struct IdentityAndTrust {
        var identityRef:SecIdentity
        var trust:SecTrust
        var cerArray:AnyObject
    }
    
    /// 创建单例对象
    fileprivate static let shareInstance = SRAlamofireHttpsConfigure()
    class var sharedInstance: SRAlamofireHttpsConfigure{
        return shareInstance
    }
    
    
    /**
     配置Alamofire的Manager
     */
    func configAlamofireManager(){
        let manager = SessionManager.default
        
        manager.delegate.sessionDidBecomeInvalidWithError =  {(session:URLSession,error:NSError?)
            
            in
            if error != nil{
                print(error)
            }
            } as? ((URLSession, Error?) -> Void)
        
        manager.delegate.sessionDidReceiveChallenge = {[weak self](session:URLSession,challenge:URLAuthenticationChallenge) in
            
            if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust{
                
                //可能为双向认证 【认证服务器和本地证书】
                //return self!.serverTrust(session, challenge: challenge)
                //单项认证 【自签名host认证】
                return self!.signedTrust(session, challenge: challenge)
            }
                //            else if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodClientCertificate{
                //                //客户端证书认证
                //                return self!.clientTrust(session, challenge: challenge)
                //            }
            else
            {
                //其他情况不接受认证
                return (.cancelAuthenticationChallenge,nil)
            }
        }
    }
    
    /**
     自签名host认证 认证是否是安全服务器 【单项认证 不用匹配服务器和客户端证书】
     
     - parameter session:   session description
     - parameter challenge: 认证者
     
     - returns: 返回
     */
    fileprivate func signedTrust(_ session: URLSession, challenge: URLAuthenticationChallenge) -> (URLSession.AuthChallengeDisposition,URLCredential?) {
        
        print(challenge.protectionSpace.host)
        
        if SignedHosts.contains(challenge.protectionSpace.host){
            
            let disposition = URLSession.AuthChallengeDisposition.useCredential
            let credential = URLCredential(trust: challenge.protectionSpace.serverTrust!)
            return (disposition,credential)
        }else{
            
            return(.performDefaultHandling,nil)
        }
    }
    
    /**
     服务器认证
     
     - parameter session:   session description
     - parameter challenge: challenge description
     
     - returns: 返回
     */
    fileprivate func serverTrust(_ session: URLSession, challenge: URLAuthenticationChallenge) -> (URLSession.AuthChallengeDisposition,URLCredential?) {
        //使用默认的操作,如同没有实现这个代理方法
        var disposition: URLSession.AuthChallengeDisposition = .performDefaultHandling
        var credential: URLCredential?
        
        //服务器认证证书
        //获取服务器证书
        let serverTrust:SecTrust = challenge.protectionSpace.serverTrust!
        let certificate = SecTrustGetCertificateAtIndex(serverTrust, 0)!
        let remoteCertificateData = CFBridgingRetain(SecCertificateCopyData(certificate))!
        //获取本地证书
        let cerPath = Bundle.main.path(forResource: ServerCerName, ofType: nil)!
        let cerUrl = URL(fileURLWithPath: cerPath)
        let localCertificateData = try? Data(contentsOf: cerUrl)
        
        if remoteCertificateData.isEqual(localCertificateData){
            credential = URLCredential(trust: serverTrust)
            disposition = .useCredential //使用认证证书
        }else{
            disposition = .cancelAuthenticationChallenge //取消认证
        }
        return(disposition,credential)
        
    }
    
    /**
     客户端认证
     
     - parameter session:   session description
     - parameter challenge: challenge description
     
     - returns: 返回
     */
    fileprivate func clientTrust(_ session: URLSession, challenge: URLAuthenticationChallenge) -> (URLSession.AuthChallengeDisposition,URLCredential?){
        //使用默认的操作,如同没有实现这个代理方法
        let disposition: URLSession.AuthChallengeDisposition = .useCredential
        let identityAndTrust = extractIdentify()
        let credential: URLCredential? = URLCredential(identity: identityAndTrust.identityRef, certificates: identityAndTrust.cerArray as? [AnyObject], persistence: URLCredential.Persistence.forSession)
        return (disposition,credential)
    }
    
    /**
     获取客户端证书相关信息
     
     - returns: 返回证书信息
     */
    fileprivate func extractIdentify() -> IdentityAndTrust{
        
        var identityAndTrust:IdentityAndTrust!
        var securityError:OSStatus = errSecSuccess
        let path = Bundle.main.path(forResource: ClientCerName, ofType: nil)!
        
        let PKCS12Data = try! Data(contentsOf: URL(fileURLWithPath: path))
        let key:String = kSecImportExportPassphrase  as String
        let options = [key:"123456"] //客户端证书密码
        var items:CFArray?
        securityError = SecPKCS12Import(PKCS12Data as CFData, options as CFDictionary, &items)
        
        if securityError == errSecSuccess {
            
            let certItems:CFArray = items as CFArray!
            let certItmesArray:Array = certItems as Array
            let dict:AnyObject? = certItmesArray.first
            
            if let certEntry:Dictionary = dict as? Dictionary<String,AnyObject>{
                
                let identityPointer:AnyObject? = certEntry["identify"]
                let secIdentityRef:SecIdentity = identityPointer as! SecIdentity!
                
                let trustPointer:AnyObject? = certEntry["trust"]
                let trustRef:SecTrust = trustPointer as! SecTrust
                
                let chainPointer:AnyObject? = certEntry["chain"]
                
                identityAndTrust = IdentityAndTrust(identityRef: secIdentityRef, trust: trustRef, cerArray: chainPointer!)
            }
        }
        return identityAndTrust
    }
    
}

