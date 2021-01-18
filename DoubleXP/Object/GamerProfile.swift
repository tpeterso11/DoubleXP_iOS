//
//  GamerTagObject.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 10/10/19.
//  Copyright © 2019 Peterson, Toussaint. All rights reserved.
//

import Foundation
import CoreData

class GamerProfile: NSObject, NSCoding {
    var _gamerTag:String = ""
    var gamerTag:String {
        get {
            return (_gamerTag)
        }
        set (newVal) {
            _gamerTag = newVal
        }
    }
    
    var _game:String = ""
    var game:String {
        get {
            return (_game)
        }
        set (newVal) {
            _game = newVal
        }
    }
    
    var _console:String = ""
    var console:String {
        get {
            return (_console)
        }
        set (newVal) {
            _console = newVal
        }
    }
    
    var _quizTaken:String = ""
    var quizTaken:String {
        get {
            return (_quizTaken)
        }
        set (newVal) {
            _quizTaken = newVal
        }
    }
    
    var _filterQuestions:[[String: Any]] = [[String: Any]]()
    var filterQuestions:[[String: Any]] {
        get {
            return (_filterQuestions)
        }
        set (newVal) {
            _filterQuestions = newVal
        }
    }
    
    init(gamerTag: String, game: String, console: String, quizTaken: String)
    {
        super.init()
        self.gamerTag = gamerTag
        self.game = game
        self.console = console
        self.quizTaken = quizTaken
    }
    
    required init(coder decoder: NSCoder)
    {
        super.init()
        self.gamerTag = (decoder.decodeObject(forKey: "gamerTag") as! String)
        self.game = (decoder.decodeObject(forKey: "game") as! String)
        self.console = (decoder.decodeObject(forKey: "console") as! String)
        self.quizTaken = (decoder.decodeObject(forKey: "quizTaken") as! String)
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(self.gamerTag, forKey: "gamerTag")
        coder.encode(self.game, forKey: "game")
        coder.encode(self.console, forKey: "console")
        coder.encode(self.quizTaken, forKey: "quizTaken")
        /*coder.encode(self.soundUrl, forKey: "soundUrl")
         coder.encode(self.soundName, forKey: "soundName")
         coder.encode(self.active, forKey: "active")
         coder.encode(self.repeatAlarm, forKey: "repeat")
         coder.encode(self.repeatAlarm, forKey: "id")*/
    }
}
