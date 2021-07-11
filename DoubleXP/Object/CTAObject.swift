//
//  CTAObject.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 4/9/21.
//  Copyright © 2021 Peterson, Toussaint. All rights reserved.
//

import Foundation
import CoreData
import UIKit

class CTAObject: NSObject, NSCoding {
    var _title:String? = ""
    var title:String {
        get {
            return (_title)!
        }
        set (newVal) {
            _title = newVal
        }
    }
    
    var _sub:String? = ""
    var sub:String {
        get {
            return (_sub)!
        }
        set (newVal) {
            _sub = newVal
        }
    }
    
    var _action:String? = ""
    var action:String {
        get {
            return (_action)!
        }
        set (newVal) {
            _action = newVal
        }
    }
    
    var _imgUrlDark:String? = ""
    var imgUrlDark:String {
        get {
            return (_imgUrlDark)!
        }
        set (newVal) {
            _imgUrlDark = newVal
        }
    }
    
    var _imgUrlLight:String? = ""
       var imgUrlLight:String {
           get {
               return (_imgUrlLight)!
           }
           set (newVal) {
               _imgUrlLight = newVal
           }
       }
    
    var _buttonText:String? = ""
       var buttonText:String {
           get {
               return (_buttonText)!
           }
           set (newVal) {
               _buttonText = newVal
           }
       }
    
    init(title: String, sub: String, lightUrl: String, darkUrl: String, buttonText: String)
    {
        super.init()
        self.title = title
        self.sub = sub
        self.imgUrlLight = lightUrl
        self.imgUrlDark = darkUrl
        self.buttonText = buttonText
    }
    
    required init(coder decoder: NSCoder)
    {
        super.init()
        self.title = (decoder.decodeObject(forKey: "title") as! String)
        self.sub = (decoder.decodeObject(forKey: "sub") as! String)
        self.imgUrlDark = (decoder.decodeObject(forKey: "imgUrlDark") as! String)
        self.imgUrlLight = (decoder.decodeObject(forKey: "imgUrlLight") as! String)
        self.buttonText = (decoder.decodeObject(forKey: "buttonText") as! String)
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(self.title, forKey: "title")
        coder.encode(self.sub, forKey: "sub")
        coder.encode(self.imgUrlDark, forKey: "imgUrlDark")
        coder.encode(self.imgUrlLight, forKey: "imgUrlLight")
        coder.encode(self.buttonText, forKey: "buttonText")
    }
}

