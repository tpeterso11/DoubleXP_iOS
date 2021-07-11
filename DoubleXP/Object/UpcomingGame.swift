//
//  UpcomingGame.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 8/14/20.
//  Copyright © 2020 Peterson, Toussaint. All rights reserved.
//

import Foundation
import CoreData

class UpcomingGame: NSObject, NSCoding {
    var _game = ""
    var game:String {
        get {
            return (_game)
        }
        set (newVal) {
            _game = newVal
        }
    }
    
    var _trailerUrls = [String: String]()
    var trailerUrls : [String: String] {
        get {
            return (_trailerUrls)
        }
        set (newVal) {
            _trailerUrls = newVal
        }
    }
    
    var _blurb = ""
    var blurb:String {
        get {
            return (_blurb)
        }
        set (newVal) {
            _blurb = newVal
        }
    }
    
    var _releaseDateMillis = ""
    var releaseDateMillis: String {
        get {
            return (_releaseDateMillis)
        }
        set (newVal) {
            _releaseDateMillis = newVal
        }
    }
    
    var _releaseDate = ""
    var releaseDate:String {
        get {
            return (_releaseDate)
        }
        set (newVal) {
            _releaseDate = newVal
        }
    }
    
    var _releaseDateProper = ""
       var releaseDateProper:String {
           get {
               return (_releaseDateProper)
           }
           set (newVal) {
               _releaseDateProper = newVal
           }
    }
    
    var _id = ""
    var id:String {
        get {
            return (_id)
        }
        set (newVal) {
            _id = newVal
        }
    }
    
    var _gameImageUrl = ""
    var gameImageUrl:String {
        get {
            return (_gameImageUrl)
        }
        set (newVal) {
            _gameImageUrl = newVal
        }
    }
    
    var _gameDesc = ""
    var gameDesc:String {
        get {
            return (_gameDesc)
        }
        set (newVal) {
            _gameDesc = newVal
        }
    }
    
    var _developer = ""
    var developer: String {
        get {
            return (_developer)
        }
        set (newVal) {
            _developer = newVal
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
    
    init(id: String, game: String, blurb: String, releaseDateMillis: String, releaseDate: String, trailerUrls: [String: String],
         gameImageUrl: String, gameDesc: String, releaseDateProper: String)
    {
        super.init()
        self.id = id
        self.game = game
        self.blurb = blurb
        self.releaseDateMillis = releaseDateMillis
        self.releaseDate = releaseDate
        self.trailerUrls = trailerUrls
        self.gameImageUrl = gameImageUrl
        self.gameDesc = gameDesc
        self.releaseDateProper = releaseDateProper
    }
    
    required init(coder decoder: NSCoder)
    {
        super.init()
        self.id = (decoder.decodeObject(forKey: "id") as! String)
        self.game = (decoder.decodeObject(forKey: "game") as! String)
        self.blurb = (decoder.decodeObject(forKey: "blurb") as! String)
        self.releaseDateMillis = (decoder.decodeObject(forKey: "releaseDateMillis") as! String)
        self.releaseDate = (decoder.decodeObject(forKey: "releaseDate") as! String)
        self.trailerUrls = (decoder.decodeObject(forKey: "trailerUrls") as! [String: String])
        self.gameImageUrl = (decoder.decodeObject(forKey: "gameImageUrl") as! String)
        self.gameDesc = (decoder.decodeObject(forKey: "gameDesc") as! String)
        self.releaseDateProper = (decoder.decodeObject(forKey: "releaseDateProper") as! String)
        self.consoles = (decoder.decodeObject(forKey: "consoles") as! [String])
        self.developer = (decoder.decodeObject(forKey: "developer") as! String)
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(self.id, forKey: "id")
        coder.encode(self.game, forKey: "game")
        coder.encode(self.blurb, forKey: "blurb")
        coder.encode(self.releaseDateMillis, forKey: "releaseDateMillis")
        coder.encode(self.releaseDate, forKey: "releaseDate")
        coder.encode(self.trailerUrls, forKey: "trailerUrls")
        coder.encode(self.gameImageUrl, forKey: "gameImageUrl")
        coder.encode(self.gameDesc, forKey: "gameDesc")
        coder.encode(self.releaseDateProper, forKey: "releaseDateProper")
        coder.encode(self.consoles, forKey: "consoles")
        coder.encode(self.developer, forKey: "developer")
    }
    
}
