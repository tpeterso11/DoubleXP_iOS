//
//  InviteFrag.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 3/22/20.
//  Copyright © 2020 Peterson, Toussaint. All rights reserved.
//

import Foundation
import UIKit
import MessageUI

class InviteFrag: ParentVC, MFMessageComposeViewControllerDelegate, MFMailComposeViewControllerDelegate{
    
    
    @IBOutlet weak var emailButton: UIView!
    @IBOutlet weak var smsButton: UIView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let delegate = UIApplication.shared.delegate as! AppDelegate
        navDictionary = ["state": "backOnly"]
        delegate.currentLanding?.updateNavigation(currentFrag: self)
        
        self.pageName = "Invite"
        delegate.addToNavStack(vc: self)

        let emailTap = UITapGestureRecognizer(target: self, action: #selector(sendEmail))
        emailButton.isUserInteractionEnabled = true
        emailButton.addGestureRecognizer(emailTap)
        
        let smsTap = UITapGestureRecognizer(target: self, action: #selector(smsButtonClicked))
        smsButton.isUserInteractionEnabled = true
        smsButton.addGestureRecognizer(smsTap)
    }
    
    @objc func smsButtonClicked(_ sender: AnyObject?) {
        if (MFMessageComposeViewController.canSendText()) {
            let controller = MFMessageComposeViewController()
            controller.body = "Download DoubleXP! https://apps.apple.com/us/app/id1472888221"
            controller.messageComposeDelegate = self
            self.present(controller, animated: true, completion: nil)
        }
    }
    
    @objc func sendEmail(_ sender: AnyObject?) {
        if (MFMailComposeViewController.canSendMail()) {
            let composeVC = MFMailComposeViewController()
            composeVC.mailComposeDelegate = self
            // Configure the fields of the interface.
            composeVC.setSubject("News Team...ASSEM-BULL!")
            composeVC.setMessageBody("I created a team on DoubleXP. Download, join and join my squad! https://apps.apple.com/us/app/id1472888221", isHTML: false)
            // Present the view controller modally.
            self.present(composeVC, animated: true, completion: nil)
        }
    }
    
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        //... handle sms screen actions
        self.dismiss(animated: true, completion: nil)
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        self.dismiss(animated: true, completion: nil)
    }

    override func viewWillDisappear(_ animated: Bool) {
        self.navigationController?.isNavigationBarHidden = false
    }
}
