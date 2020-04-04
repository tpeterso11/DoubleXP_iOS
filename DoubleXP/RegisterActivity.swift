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
        emailField.addTarget(self, action: #selector(textFieldDidChange), for: UIControl.Event.editingChanged)
        passwordField.addTarget(self, action: #selector(textFieldDidChange), for: UIControl.Event.editingChanged)

        
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
                ref.child("platform").setValue("ios")
                ref.child("search").setValue("true")
                ref.child("model").setValue(UIDevice.modelName)
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
        
        //registerUser(email: email, pass: pass)
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

public extension UIDevice {

    static let modelName: String = {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }

        func mapToDevice(identifier: String) -> String { // swiftlint:disable:this cyclomatic_complexity
            #if os(iOS)
            switch identifier {
            case "iPod5,1":                                 return "iPod touch (5th generation)"
            case "iPod7,1":                                 return "iPod touch (6th generation)"
            case "iPod9,1":                                 return "iPod touch (7th generation)"
            case "iPhone3,1", "iPhone3,2", "iPhone3,3":     return "iPhone 4"
            case "iPhone4,1":                               return "iPhone 4s"
            case "iPhone5,1", "iPhone5,2":                  return "iPhone 5"
            case "iPhone5,3", "iPhone5,4":                  return "iPhone 5c"
            case "iPhone6,1", "iPhone6,2":                  return "iPhone 5s"
            case "iPhone7,2":                               return "iPhone 6"
            case "iPhone7,1":                               return "iPhone 6 Plus"
            case "iPhone8,1":                               return "iPhone 6s"
            case "iPhone8,2":                               return "iPhone 6s Plus"
            case "iPhone9,1", "iPhone9,3":                  return "iPhone 7"
            case "iPhone9,2", "iPhone9,4":                  return "iPhone 7 Plus"
            case "iPhone8,4":                               return "iPhone SE"
            case "iPhone10,1", "iPhone10,4":                return "iPhone 8"
            case "iPhone10,2", "iPhone10,5":                return "iPhone 8 Plus"
            case "iPhone10,3", "iPhone10,6":                return "iPhone X"
            case "iPhone11,2":                              return "iPhone XS"
            case "iPhone11,4", "iPhone11,6":                return "iPhone XS Max"
            case "iPhone11,8":                              return "iPhone XR"
            case "iPhone12,1":                              return "iPhone 11"
            case "iPhone12,3":                              return "iPhone 11 Pro"
            case "iPhone12,5":                              return "iPhone 11 Pro Max"
            case "iPad2,1", "iPad2,2", "iPad2,3", "iPad2,4":return "iPad 2"
            case "iPad3,1", "iPad3,2", "iPad3,3":           return "iPad (3rd generation)"
            case "iPad3,4", "iPad3,5", "iPad3,6":           return "iPad (4th generation)"
            case "iPad6,11", "iPad6,12":                    return "iPad (5th generation)"
            case "iPad7,5", "iPad7,6":                      return "iPad (6th generation)"
            case "iPad7,11", "iPad7,12":                    return "iPad (7th generation)"
            case "iPad4,1", "iPad4,2", "iPad4,3":           return "iPad Air"
            case "iPad5,3", "iPad5,4":                      return "iPad Air 2"
            case "iPad11,4", "iPad11,5":                    return "iPad Air (3rd generation)"
            case "iPad2,5", "iPad2,6", "iPad2,7":           return "iPad mini"
            case "iPad4,4", "iPad4,5", "iPad4,6":           return "iPad mini 2"
            case "iPad4,7", "iPad4,8", "iPad4,9":           return "iPad mini 3"
            case "iPad5,1", "iPad5,2":                      return "iPad mini 4"
            case "iPad11,1", "iPad11,2":                    return "iPad mini (5th generation)"
            case "iPad6,3", "iPad6,4":                      return "iPad Pro (9.7-inch)"
            case "iPad7,3", "iPad7,4":                      return "iPad Pro (10.5-inch)"
            case "iPad8,1", "iPad8,2", "iPad8,3", "iPad8,4":return "iPad Pro (11-inch)"
            case "iPad8,9", "iPad8,10":                     return "iPad Pro (11-inch) (2nd generation)"
            case "iPad6,7", "iPad6,8":                      return "iPad Pro (12.9-inch)"
            case "iPad7,1", "iPad7,2":                      return "iPad Pro (12.9-inch) (2nd generation)"
            case "iPad8,5", "iPad8,6", "iPad8,7", "iPad8,8":return "iPad Pro (12.9-inch) (3rd generation)"
            case "iPad8,11", "iPad8,12":                    return "iPad Pro (12.9-inch) (4th generation)"
            case "AppleTV5,3":                              return "Apple TV"
            case "AppleTV6,2":                              return "Apple TV 4K"
            case "AudioAccessory1,1":                       return "HomePod"
            case "i386", "x86_64":                          return "Simulator \(mapToDevice(identifier: ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] ?? "iOS"))"
            default:                                        return identifier
            }
            #elseif os(tvOS)
            switch identifier {
            case "AppleTV5,3": return "Apple TV 4"
            case "AppleTV6,2": return "Apple TV 4K"
            case "i386", "x86_64": return "Simulator \(mapToDevice(identifier: ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] ?? "tvOS"))"
            default: return identifier
            }
            #endif
        }

        return mapToDevice(identifier: identifier)
    }()

}
