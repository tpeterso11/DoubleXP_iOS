//
//  FreeAgentObject.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 12/3/19.
//  Copyright © 2019 Peterson, Toussaint. All rights reserved.
//

import Foundation

class FreeAgentObject: NSObject, NSCoding {

    var _gamerTag = ""
    var gamerTag:String {
        get {
            return (_gamerTag)
        }
        set (newVal) {
            _gamerTag = newVal
        }
    }

    var _competitionId = ""
    var competitionId: String {
        get {
            return (_competitionId)
        }
        set (newVal) {
            _competitionId = newVal
        }
    }
    
    var _consoles = [String]()
    var consoles: [String] {
        get {
            return (_consoles)
        }
        set (newVal) {
            _consoles = newVal
        }
    }

    var _game = ""
    var game: String {
        get {
            return (_game)
        }
        set (newVal) {
            _game = newVal
        }
    }
    
    var _userId = ""
    var userId: String {
        get {
            return (_userId)
        }
        set (newVal) {
            _userId = newVal
        }
    }
    
    var _questions = [FAQuestion]()
    var questions: [FAQuestion] {
        get {
            return (_questions)
        }
        set (newVal) {
            _questions = newVal
        }
    }
    
    var _statTree = [String: String]()
    var statTree: [String: String] {
        get {
            return (_statTree)
        }
        set (newVal) {
            _statTree = newVal
        }
    }

    init(gamerTag: String, competitionId: String, consoles: [String], game: String, userId: String, questions: [FAQuestion])
    {
        super.init()
        self.gamerTag = gamerTag
        self.competitionId = competitionId
        self.game = game
        self.consoles = consoles
        self.userId = userId
        self.questions = questions
    }

    required init(coder decoder: NSCoder)
    {
        super.init()
        self.gamerTag = (decoder.decodeObject(forKey: "gamerTag") as! String)
        self.competitionId = (decoder.decodeObject(forKey: "competitionId") as! String)
        self.game = (decoder.decodeObject(forKey: "game") as! String)
        self.consoles = (decoder.decodeObject(forKey: "consoles") as! [String])
        self.userId = (decoder.decodeObject(forKey: "userId") as! String)
        self.questions = (decoder.decodeObject(forKey: "questions") as! [FAQuestion])
        self.statTree = (decoder.decodeObject(forKey: "statTree") as! [String: String])
    }

    func encode(with coder: NSCoder) {
        coder.encode(self.gamerTag, forKey: "gamerTag")
        coder.encode(self.competitionId, forKey: "competitionId")
        coder.encode(self.game, forKey: "game")
        coder.encode(self.consoles, forKey: "consoles")
        coder.encode(self.userId, forKey: "userId")
        coder.encode(self.questions, forKey: "questions")
        coder.encode(self.statTree, forKey: "statTree")
    }
}
