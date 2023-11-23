//
//  CreatePost.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 12/28/22.
//  Copyright © 2022 Peterson, Toussaint. All rights reserved.
//

import Foundation
import UIKit
import Lottie

class CreatePost: UIViewController {
    
    @IBOutlet weak var connectButton: UIView!
    @IBOutlet weak var googleAnimation: LottieAnimationView!
    @IBOutlet weak var youtubeConnectCover: UIView!
    @IBOutlet weak var createTable: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        if(appDelegate.currentUser!.googleApiAccessToken.isEmpty){
            self.youtubeConnectCover.isHidden = true
        } else {
            //self.connectButton.addTarget(self, action: #selector(self.googleSignIn), for: .touchUpInside)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                self.googleAnimation.loopMode = .playOnce
                self.googleAnimation.play()
            }
        }
    }
    
    /*@objc private func googleSignIn(){
        GIDSignIn.sharedInstance()?.scopes = ["https://www.googleapis.com/auth/youtube.readonly"]
        GIDSignIn.sharedInstance().signIn()
    }*/
}
