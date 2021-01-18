//
//  OptionObj.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 6/11/20.
//  Copyright © 2020 Peterson, Toussaint. All rights reserved.
//

import Foundation
import CoreData

class OptionObj: NSObject, NSCoding {
    var _optionLabel = ""
    var optionLabel:String {
        get {
            return (_optionLabel)
        }
        set (newVal) {
            _optionLabel = newVal
        }
    }
    
    var _imageUrl = ""
    var imageUrl:String {
        get {
            return (_imageUrl)
        }
        set (newVal) {
            _imageUrl = newVal
        }
    }
    
    var _title = ""
    var title:String {
        get {
            return (_title)
        }
        set (newVal) {
            _title = newVal
        }
    }
    
    var _sortingTags = [String]()
    var sortingTags: [String] {
        get {
            return (_sortingTags)
        }
        set (newVal) {
            _sortingTags = newVal
        }
    }
    
    init(optionLabel: String, imageUrl: String, sortingTags: [String])
    {
        super.init()
        self.optionLabel = optionLabel
        self.imageUrl = imageUrl
        self.sortingTags = sortingTags
    }
    
    required init(coder decoder: NSCoder)
    {
        super.init()
        self.optionLabel = (decoder.decodeObject(forKey: "optionLabel") as! String)
        self.imageUrl = (decoder.decodeObject(forKey: "imageUrl") as! String)
        self.sortingTags = (decoder.decodeObject(forKey: "sortingTags") as! [String])
        self.title = (decoder.decodeObject(forKey: "title") as! String)
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(self.sortingTags, forKey: "sortingTags")
        coder.encode(self.imageUrl, forKey: "imageUrl")
        coder.encode(self.optionLabel, forKey: "optionLabel")
        coder.encode(self.title, forKey: "title")
    }
    
}
