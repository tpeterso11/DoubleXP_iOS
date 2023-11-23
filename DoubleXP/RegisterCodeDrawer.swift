//
//  RegisterCodeDrawer.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 12/24/20.
//  Copyright © 2020 Peterson, Toussaint. All rights reserved.
//

import Foundation
import UIKit
import Firebase
import FirebaseAuth
import Lottie
import FirebaseDatabase
import PopupDialog

class RegisterCodeDrawer: UIViewController, UITextFieldDelegate {
    @IBOutlet weak var submitCode: UIButton!
    @IBOutlet weak var nevermindButton: UIButton!
    @IBOutlet weak var codeEntry: UITextField!
    @IBOutlet weak var loadingView: UIVisualEffectView!
    @IBOutlet weak var loadingAnimation: LottieAnimationView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        codeEntry.delegate = self
        codeEntry.addTarget(self, action: #selector(textFieldDidChange), for: UIControl.Event.editingChanged)
        nevermindButton.addTarget(self, action: #selector(nevermind), for: .touchUpInside)
        
        addDoneButtonOnKeyboard()
    }
    
    @objc private func nevermind(){
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc private func signUpUser(){
        loadingAnimation.loopMode = .loop
        loadingAnimation.play()
        UIView.animate(withDuration: 0.8, animations: {
            self.loadingView.alpha = 1
        }, completion: { (finished: Bool) in
            let verificationID = UserDefaults.standard.string(forKey: "authVerificationID")
            if(verificationID != nil){
                let credential = PhoneAuthProvider.provider().credential(
                    withVerificationID: verificationID!,
                    verificationCode: self.codeEntry.text!)
                
                
                Auth.auth().signIn(with: credential) { (authResult, error) in
                  if let error = error {
                    let authError = error as NSError
                    var buttons = [PopupDialogButton]()
                    let title = "code error"
                    let message = "sorry, there was a problem with your code."
                    
                    let button = DefaultButton(title: "try again.") { [weak self] in
                        self?.hideWork()
                        // do nothing
                    }
                    buttons.append(button)
                    let popup = PopupDialog(title: title, message: message)
                    popup.addButtons(buttons)

                    // Present dialog
                    self.present(popup, animated: true, completion: nil)
                      
                    // ...
                    return
                  }
                    //logged in
                    if(authResult != nil){
                        UserDefaults.standard.set(authResult!.user.uid, forKey: "userId")
                        DispatchQueue.main.async {
                            self.dismiss(animated: true) {
                                let delegate = UIApplication.shared.delegate as! AppDelegate
                                delegate.currentLoginActivity?.transitionAfterPhoneRegistration(uid: authResult!.user.uid)
                                delegate.currentRegisterActivity?.transitionAfterPhoneRegistration(uid: authResult!.user.uid)
                            }
                        }
                    }
                }
            } else {
                self.dismiss(animated: true, completion: nil)
            }
        })
    }
    
    private func hideWork(){
        UIView.animate(withDuration: 0.8, animations: {
            self.loadingView.alpha = 0
        }, completion: { (finished: Bool) in
            self.loadingAnimation.pause()
        })
    }
    
    func addDoneButtonOnKeyboard() {
        let doneToolbar: UIToolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: 320, height: 50))
        doneToolbar.barStyle       = UIBarStyle.default
        let flexSpace              = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil)
        let done: UIBarButtonItem  = UIBarButtonItem(title: "Done", style: UIBarButtonItem.Style.done, target: self, action: #selector(doneButtonAction))

        var items = [UIBarButtonItem]()
        items.append(flexSpace)
        items.append(done)

        doneToolbar.items = items
        doneToolbar.sizeToFit()

        self.codeEntry.inputAccessoryView = doneToolbar
    }
    
    @objc func doneButtonAction() {
        self.codeEntry.resignFirstResponder()
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let maxLength = 6
        let currentString: NSString = (textField.text ?? "") as NSString
        let newString: NSString =
            currentString.replacingCharacters(in: range, with: string) as NSString
        return newString.length <= maxLength
    }
    
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        if(self.codeEntry.text?.count == 6){
            self.submitCode.alpha = 1
            self.submitCode.addTarget(self, action: #selector(signUpUser), for: .touchUpInside)
            self.submitCode.isUserInteractionEnabled = true
        } else {
            self.submitCode.alpha = 0.3
            self.submitCode.isUserInteractionEnabled = false
        }
    }
}
