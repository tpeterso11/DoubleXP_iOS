//
//  GCInfoCell.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 10/21/19.
//  Copyright © 2019 Peterson, Toussaint. All rights reserved.
//

import UIKit

class GCInfoCell: UICollectionViewCell{
    @IBOutlet weak var gameName: UILabel!
    @IBOutlet weak var psSwitch: UISwitch!
    @IBOutlet weak var xboxSwitch: UISwitch!
    @IBOutlet weak var nintendoSwitch: UISwitch!
    @IBOutlet weak var pcSwitch: UISwitch!
    @IBOutlet weak var gamertagField: UITextField!
    @IBOutlet weak var importLayout: UIView!
    @IBOutlet weak var importSwitch: UISwitch!
    @IBOutlet weak var gamerTagAll: UISwitch!
    @IBOutlet weak var gamerTagAllTag: UILabel!
    @IBOutlet weak var gamerTagCover: UIView!
    @IBOutlet weak var gamerTagCoverEmblem: UIImageView!
    
    @IBOutlet weak var progressSpinner: UIActivityIndicatorView!
    func consoleSwitchIsOn() -> Bool{
        var switchIsOn = false
        
        if(pcSwitch.isOn){
            switchIsOn = true
        }
        
        if(psSwitch.isOn){
            switchIsOn = true
        }
        
        if(xboxSwitch.isOn){
            switchIsOn = true
        }
        
        if(nintendoSwitch.isOn){
            switchIsOn = true
        }
        
        return switchIsOn
    }
    
    func gamerTagEntered() -> Bool{
        if(gamertagField.text != nil && !gamertagField.text!.isEmpty){
            return true
        }
        else{
            return false
        }
    }
    
    func getChosenConsole() -> String{
        var console = ""
        if(pcSwitch.isOn){
            console = "pc"
        }
        
        if(psSwitch.isOn){
            console = "ps"
        }
        
        if(xboxSwitch.isOn){
            console = "xbox"
        }
        
        if(nintendoSwitch.isOn){
            console = "switch"
        }
        
        return console
    }
}
