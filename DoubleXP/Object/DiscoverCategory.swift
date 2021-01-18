//
//  DiscoverCategory.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 11/22/20.
//  Copyright © 2020 Peterson, Toussaint. All rights reserved.
//

import Foundation

class DiscoverCategory: NSObject, NSCoding {
    var _imgUrl = ""
    var imgUrl:String {
        get {
            return (_imgUrl)
        }
        set (newVal) {
            _imgUrl = newVal
        }
    }
    
    var _categoryName = ""
    var categoryName : String {
        get {
            return (_categoryName)
        }
        set (newVal) {
            _categoryName = newVal
        }
    }
    
    var _categoryVal = ""
    var categoryVal : String {
        get {
            return (_categoryVal)
        }
        set (newVal) {
            _categoryVal = newVal
        }
    }
    
    init(imgUrl: String, categoryName: String, categoryVal: String)
    {
        super.init()
        self.imgUrl = imgUrl
        self.categoryName = categoryName
        self.categoryVal = categoryVal
    }
    
    required init(coder decoder: NSCoder)
    {
        super.init()
        self.imgUrl = (decoder.decodeObject(forKey: "tag") as! String)
        self.categoryName = (decoder.decodeObject(forKey: "categoryName") as! String)
        self.categoryVal = (decoder.decodeObject(forKey: "categoryVal") as! String)
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(self.imgUrl, forKey: "imgUrl")
        coder.encode(self.categoryName, forKey: "categoryName")
        coder.encode(self.categoryVal, forKey: "categoryVal")
    }
    
}
