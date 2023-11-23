//
//  FAQuizConsoles.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 12/21/19.
//  Copyright © 2019 Peterson, Toussaint. All rights reserved.
//

import UIKit
import Firebase
import moa
import SwiftHTTP
import SwiftNotificationCenter
import FBSDKCoreKit

class FAQuizConsoles: UIViewController{
    @IBOutlet weak var ps4Switch: UISwitch!
    @IBOutlet weak var xboxSwitch: UISwitch!
    @IBOutlet weak var nintendoSwitch: UISwitch!
    @IBOutlet weak var pcSwitch: UISwitch!
    @IBOutlet weak var nextButtonNew: UIButton!
    var interviewManager: InterviewManager?
    
    var switches = [UISwitch]()
    
    var selectedConsole = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ps4Switch.addTarget(self, action: #selector(psSwitchChanged), for: UIControl.Event.valueChanged)
        pcSwitch.addTarget(self, action: #selector(pcSwitchChanged), for: UIControl.Event.valueChanged)
        xboxSwitch.addTarget(self, action: #selector(xboxSwitchChanged), for: UIControl.Event.valueChanged)
        nintendoSwitch.addTarget(self, action: #selector(nintendoSwitchChanged), for: UIControl.Event.valueChanged)
        
        let delegate = UIApplication.shared.delegate as! AppDelegate
        interviewManager = delegate.interviewManager
        
        checkSwitches(selected: "")
        nextButtonNew.addTarget(self, action: #selector(nextButtonClicked), for: .touchUpInside)
    }
    
    @objc func nextButtonClicked(_ sender: AnyObject?) {
        guard !selectedConsole.isEmpty else {
            return
        }
        
        var chosenConsole = ""
        if(ps4Switch.isOn){
            chosenConsole = "ps"
        }
        if(xboxSwitch.isOn){
            chosenConsole = "xbox"
        }
        if(pcSwitch.isOn){
            chosenConsole = "pc"
        }
        if(nintendoSwitch.isOn){
            chosenConsole = "nintendo"
        }
        
        AppEvents.shared.logEvent(AppEvents.Name(rawValue: "FA Quiz - Console Chosen - " + chosenConsole))
        interviewManager?.setConsoles(console: selectedConsole)
    }
    
    @objc func psSwitchChanged(stationSwitch: UISwitch) {
        if(stationSwitch.isOn){
            selectedConsole = "ps"
            checkSwitches(selected: "ps")
        }
        else{
            selectedConsole = ""
            checkSwitches(selected: "")
        }
    }
    @objc func xboxSwitchChanged(xSwitch: UISwitch) {
        if(xSwitch.isOn){
            selectedConsole = "xbox"
            checkSwitches(selected: "xbox")
        }
        else{
            selectedConsole = ""
            checkSwitches(selected: "")
        }
    }
    @objc func nintendoSwitchChanged(switchSwitch: UISwitch) {
        if(switchSwitch.isOn){
            selectedConsole = "nintendo"
            checkSwitches(selected: "nintendo")
        }
        else{
            selectedConsole = ""
            checkSwitches(selected: "")
        }
    }
    @objc func pcSwitchChanged(compSwitch: UISwitch) {
        if(compSwitch.isOn){
            selectedConsole = "pc"
            checkSwitches(selected: "pc")
        }
        else{
            selectedConsole = ""
            checkSwitches(selected: "")
        }
    }
    
    private func checkSwitches(selected: String){
        if(selectedConsole == "ps"){
            ps4Switch.isOn = true
            pcSwitch.isOn = false
            xboxSwitch.isOn = false
            nintendoSwitch.isOn = false
            
            nextButtonNew.alpha = 1
            nextButtonNew.isUserInteractionEnabled = true
        }
        else if(selectedConsole == "XBox"){
            ps4Switch.isOn = false
            pcSwitch.isOn = false
            xboxSwitch.isOn = true
            nintendoSwitch.isOn = false
            
            nextButtonNew.alpha = 1
            nextButtonNew.isUserInteractionEnabled = true
        }
        else if(selectedConsole == "nintendo"){
            ps4Switch.isOn = false
            pcSwitch.isOn = false
            xboxSwitch.isOn = false
            nintendoSwitch.isOn = true
            
            nextButtonNew.alpha = 1
            nextButtonNew.isUserInteractionEnabled = true
        }
        else if(selectedConsole == "pc"){
            ps4Switch.isOn = false
            pcSwitch.isOn = true
            xboxSwitch.isOn = false
            nintendoSwitch.isOn = false
            
            nextButtonNew.alpha = 1
            nextButtonNew.isUserInteractionEnabled = true
        }
        else{
            ps4Switch.isOn = false
            pcSwitch.isOn = false
            xboxSwitch.isOn = false
            nintendoSwitch.isOn = false
            
            nextButtonNew.alpha = 0.4
            nextButtonNew.isUserInteractionEnabled = false
        }
    }
}
