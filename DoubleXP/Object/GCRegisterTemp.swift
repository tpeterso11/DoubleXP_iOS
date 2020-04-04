//
//  GCRegisterTemp.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 3/29/20.
//  Copyright © 2020 Peterson, Toussaint. All rights reserved.
//

import Foundation
import CoreData

class GCRegisterTemp: NSObject, NSCoding {
    var _gameName:String = ""
    var gameName:String {
        get {
            return (_gameName)
        }
        set (newVal) {
            _gameName = newVal
        }
    }

    var _gamerTag: String = ""
    var gamerTag: String {
        get {
            return (_gamerTag)
        }
        set (newVal) {
            _gamerTag = newVal
        }
    }

    var _console: String = ""
    var console: String {
        get {
            return (_console)
        }
        set (newVal) {
            _console = newVal
        }
    }

    var _importStats: Bool = false
    var importStats: Bool {
        get {
            return (_importStats)
        }
        set (newVal) {
            _importStats = newVal
        }
    }
    
    init(gameName: String, gamerTag: String, console: String, importStats: Bool)
    {
        super.init()
        self.gameName = gameName
        self.gamerTag = gamerTag
        self.console = console
        self.importStats = importStats
    }
    
    required init(coder decoder: NSCoder)
    {
        super.init()
        self.gameName = (decoder.decodeObject(forKey: "gameName") as! String)
        self.gamerTag = (decoder.decodeObject(forKey: "gamerTag") as! String)
        self.console = (decoder.decodeObject(forKey: "console") as! String)
        self.importStats = (decoder.decodeObject(forKey: "importStats") as! Bool)
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(self.gameName, forKey: "gameName")
        coder.encode(self.gamerTag, forKey: "gamerTag")
        coder.encode(self.console, forKey: "console")
        coder.encode(self.importStats, forKey: "importStats")
    }
}
