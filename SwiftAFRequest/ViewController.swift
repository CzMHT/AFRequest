//
//  ViewController.swift
//  SwiftAFRequest
//
//  Created by YuanGu on 2018/5/9.
//  Copyright © 2018年 YuanGu. All rights reserved.
//

import UIKit
import SnapKit
import SwiftyJSON

class ViewController: UIViewController {

    var label: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Swift Request"
        
        label = UILabel.init()
        label.textColor = UIColor.black
        label.textAlignment = .center
        label.isUserInteractionEnabled = true
        label.text = "请点击屏幕进行网络请求 ,结果将在展示在label中"
        label.numberOfLines = 0
        self.view.addSubview(label)
        
        label.snp.makeConstraints { (make) in
            make.left.equalTo(50)
            make.height.equalTo(300)
            make.center.equalTo(self.view)
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        let city = ["city": "上海"] as [String : Any]
        
        AFRequest.postRequest(urlString: AirUrl,
                              parameters: getJsonParam(params: city),
                              complete: { (value) in
                                //print(value)
        }, success: { [weak self] (json) in
            
            guard let data:Data = json as? Data else{
                return
            }
            
            do {
                let jsonData = try JSON(data: data)
                
                self?.label.text = jsonData.stringValue
                
                let date: String = jsonData["result" ,"date"].string!
                
                print("AFNet date: \(date)")
                
            } catch let error {
                print("AFNet error:\(error.localizedDescription)")
            }
            
        }) { (error) in
            
            self?.label.text = error.localizedDescription
            
            print("error: \(error.localizedDescription)")
        }
    }
    
    func getJsonParam(params: [String : Any]) -> [String : Any] {
        
        let data = try? JSONSerialization.data(withJSONObject: params, options: JSONSerialization.WritingOptions.prettyPrinted)
        
        let str = String(data:data!, encoding: String.Encoding.utf8)
        
        let jsonParam = ["json": str as Any]
        
        return jsonParam as Any as! [String : Any]
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}

