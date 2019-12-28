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

class RegisterActivity: UIViewController {
    @IBOutlet weak var headerImage: UIImageView!
    
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var closeX: UIImageView!
    @IBOutlet weak var psSwitch: UISwitch!
    @IBOutlet weak var xboxSwitch: UISwitch!
    @IBOutlet weak var nintendoSwitch: UISwitch!
    @IBOutlet weak var pcSwitch: UISwitch!
    @IBOutlet weak var nextButton: UIImageView!
    @IBOutlet weak var backX: UIImageView!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let theImage = headerImage.image!
        let filter = CIFilter(name: "CIColorInvert")
        filter?.setValue(CIImage(image: theImage), forKey: kCIInputImageKey)
        let newImage = UIImage(ciImage: (filter?.outputImage)!)
        headerImage.image = newImage
        
        let xImage = closeX.image!
        let xFilter = CIFilter(name: "CIColorInvert")
        xFilter?.setValue(CIImage(image: xImage), forKey: kCIInputImageKey)
        let newXImage = UIImage(ciImage: (xFilter?.outputImage)!)
        closeX.image = newXImage
        
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(nextButtonClicked))
        nextButton.isUserInteractionEnabled = true
        nextButton.addGestureRecognizer(singleTap)
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
                //ref.child("messagingNotifications").setValue(true)
                
                DispatchQueue.main.async {
                    let delegate = UIApplication.shared.delegate as! AppDelegate!
                    delegate?.currentUser = user
                    
                    if(!user.pc && !user.xbox && !user.ps && !user.nintendo){
                        self.performSegue(withIdentifier: "registerNoGC", sender: nil)
                    }
                    else{
                        self.performSegue(withIdentifier: "registerGC", sender: nil)
                    }
                }
            }
        }
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
        
        if(!email.isEmpty && !pass.isEmpty){
            registerUser(email: email, pass: pass)
        }
        else{
            let message = "Must enter a valid email and/or password to continue."
            let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            self.display(alertController: alertController)
        }
        //self.performSegue(withIdentifier: "registerGC", sender: nil)
    }
    
    private func display(alertController: UIAlertController){
        self.present(alertController, animated: true, completion: nil)
    }
}
