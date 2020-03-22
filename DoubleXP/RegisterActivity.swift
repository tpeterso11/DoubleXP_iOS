//
//  RegisterActivity.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 10/12/19.
//  Copyright © 2019 Peterson, Toussaint. All rights reserved.
//

import UIKit
import Firebase
import ImageLoader
import ValidationComponents
import FBSDKCoreKit

class RegisterActivity: UIViewController, UITextFieldDelegate {
    @IBOutlet weak var headerImage: UIImageView!
    
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var closeX: UIImageView!
    @IBOutlet weak var psSwitch: UISwitch!
    @IBOutlet weak var xboxSwitch: UISwitch!
    @IBOutlet weak var nintendoSwitch: UISwitch!
    @IBOutlet weak var pcSwitch: UISwitch!
    @IBOutlet weak var nextButton: UIButton!
    
    private var emailEntered = false
    private var passwordEntered = false
    private var consoleChosen = false
    private var switches = [UISwitch]()
    
    @IBOutlet weak var backX: UIImageView!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        nextButton.addTarget(self, action: #selector(nextButtonClicked(_:)), for: .touchUpInside)
        
        let backTap = UITapGestureRecognizer(target: self, action: #selector(backButtonClicked))
        backX.isUserInteractionEnabled = true
        backX.addGestureRecognizer(backTap)
        
        emailField.returnKeyType = .done
        emailField.delegate = self
        passwordField.returnKeyType = .done
        passwordField.delegate = self
        
        switches.append(psSwitch)
        switches.append(xboxSwitch)
        switches.append(pcSwitch)
        switches.append(nintendoSwitch)
        
        psSwitch.addTarget(self, action: #selector(psSwitchChanged), for: UIControl.Event.valueChanged)
        xboxSwitch.addTarget(self, action: #selector(xboxSwitchChanged), for: UIControl.Event.valueChanged)
        nintendoSwitch.addTarget(self, action: #selector(nintendoSwitchChanged), for: UIControl.Event.valueChanged)
        pcSwitch.addTarget(self, action: #selector(pcSwitchChanged), for: UIControl.Event.valueChanged)
        
        checkNextButton()
        
        AppEvents.logEvent(AppEvents.Name(rawValue: "Register"))
    }
    
    @objc func psSwitchChanged(stationSwitch: UISwitch) {
        checkNextButton()
    }
    
    @objc func xboxSwitchChanged(stationSwitch: UISwitch) {
        checkNextButton()
    }
    
    @objc func pcSwitchChanged(stationSwitch: UISwitch) {
        checkNextButton()
    }
    
    @objc func nintendoSwitchChanged(stationSwitch: UISwitch) {
        checkNextButton()
    }
    
    func registerUser(email: String, pass: String){
        Auth.auth().createUser(withEmail: email, password: pass) { authResult, error in
            if(authResult != nil){
                let uId = authResult?.user.uid ?? ""
                let user = User(uId: uId)
                
                if(self.psSwitch.isOn){
                    user.ps = true
                }
                
                if(self.pcSwitch.isOn){
                    user.pc = true
                }
                
                if(self.xboxSwitch.isOn){
                    user.xbox = true
                }
                
                if(self.nintendoSwitch.isOn){
                    user.nintendo = true
                }
                
                let ref = Database.database().reference().child("Users").child((authResult?.user.uid)!)
                ref.child("consoles").child("xbox").setValue(self.xboxSwitch.isOn)
                ref.child("consoles").child("ps").setValue(self.psSwitch.isOn)
                ref.child("consoles").child("nintendo").setValue(self.nintendoSwitch.isOn)
                ref.child("consoles").child("pc").setValue(self.pcSwitch.isOn)
                ref.child("platform").child("ios")
                ref.child("model").child(self.modelIdentifier())
                ref.child("notifications").setValue("true")
                
                DispatchQueue.main.async {
                    let delegate = UIApplication.shared.delegate as! AppDelegate
                    delegate.currentUser = user
                    
                    if(!user.pc && !user.xbox && !user.ps && !user.nintendo){
                        AppEvents.logEvent(AppEvents.Name(rawValue: "Register - No GC"))
                        self.performSegue(withIdentifier: "registerNoGC", sender: nil)
                    }
                    else{
                        if(user.pc){
                            AppEvents.logEvent(AppEvents.Name(rawValue: "Register - PC User"))
                        }
                        if(user.xbox){
                            AppEvents.logEvent(AppEvents.Name(rawValue: "Register - xBox User"))
                        }
                        if(user.ps){
                            AppEvents.logEvent(AppEvents.Name(rawValue: "Register - PS User"))
                        }
                        if(user.nintendo){
                            AppEvents.logEvent(AppEvents.Name(rawValue: "Register - Nintendo User"))
                        }
                        
                        AppEvents.logEvent(AppEvents.Name(rawValue: "Register - GC"))
                        self.performSegue(withIdentifier: "registerGC", sender: nil)
                    }
                }
            }
        }
    }
    
    func checkNextButton(){
        if(self.emailEntered && passwordEntered && checkSwitches()){
            self.nextButton.alpha = 1
        }
        else{
            self.nextButton.alpha = 0.3
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool
    {
        textField.resignFirstResponder()
        return true
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        if(textField == self.emailField && textField.text?.count ?? 0 > 5){
            self.emailEntered = true
            checkNextButton()
        }
        else{
            if(textField.text?.count ?? 0 > 5){
                self.passwordEntered = true
                checkNextButton()
            }
        }
    }
    
    private func checkSwitches() -> Bool{
        var switchOn = false
        for uiSwitch in self.switches{
            if(uiSwitch.isOn){
                switchOn = true
                break
            }
        }
        
        return switchOn
    }
    
    private func modelIdentifier() -> String {
        if let simulatorModelIdentifier = ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] { return simulatorModelIdentifier }
        var sysinfo = utsname()
        uname(&sysinfo) // ignore return value
        return String(bytes: Data(bytes: &sysinfo.machine, count: Int(_SYS_NAMELEN)), encoding: .ascii)!.trimmingCharacters(in: .controlCharacters)
    }
    
    @objc func nextButtonClicked(_ sender: AnyObject?) {
        let email = emailField.text ?? ""
        let pass = passwordField.text ?? ""
        
        let rule = EmailValidationPredicate()
        
        if(!email.isEmpty && !pass.isEmpty && rule.evaluate(with: email)){
            registerUser(email: email, pass: pass)
        }
        else{
            if(!rule.evaluate(with: email)){
                let message = "Must enter a valid email to continue."
                let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                self.display(alertController: alertController)
                
                return
            }
            
            if(pass.isEmpty){
                let message = "Must enter a password to continue."
                let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                self.display(alertController: alertController)
                
                return
            }
            
            let message = "Must enter a valid email and/or password to continue."
            let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            self.display(alertController: alertController)
        }
    }
    
    @objc func backButtonClicked(_ sender: AnyObject?) {
        self.performSegue(withIdentifier: "registerBack", sender: nil)
    }
    
    private func display(alertController: UIAlertController){
        self.present(alertController, animated: true, completion: nil)
    }
}
