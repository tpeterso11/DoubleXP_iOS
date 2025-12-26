//
//  Results.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 10/13/20.
//  Copyright © 2020 Peterson, Toussaint. All rights reserved.
//

import Foundation
import UIKit

class Results: UIViewController {
    var payload = [Any]()
    var returning = false
    var userUid = ""
    var currentUpgradeChoice = ""
    var animatedTitles = [String]()
    @IBOutlet weak var lineOne: UILabel!
    @IBOutlet weak var dividerOne: UIView!
    @IBOutlet weak var lineTwo: UILabel!
    @IBOutlet weak var lineTwoDivider: UIView!
    @IBOutlet weak var lineFour: UILabel!
    @IBOutlet weak var lineThree: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let delegate = UIApplication.shared.delegate as! AppDelegate
        delegate.currentResultsFrag = self
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            UIView.animate(withDuration: 0.8, animations: {
                self.lineOne.alpha = 1
                self.dividerOne.alpha = 1
            }, completion: { (finished: Bool) in
                UIView.animate(withDuration: 0.5, delay: 0.5, options: [], animations: {
                    self.lineTwo.alpha = 1
                }, completion: { (finished: Bool) in
                    UIView.animate(withDuration: 0.5, delay: 0.8, options: [], animations: {
                        self.lineTwoDivider.alpha = 1
                    }, completion: { (finished: Bool) in
                        UIView.animate(withDuration: 0.5, delay: 0.2, options: [], animations: {
                            self.lineThree.alpha = 1
                            self.lineFour.alpha = 1
                        }, completion: { (finished: Bool) in
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                                if(delegate.currentUser != nil){
                                    UserDefaults.standard.setValue("true", forKey: "registered")
                                    self.performSegue(withIdentifier: "home", sender: self)
                                }
                            }
                        })
                    })
                })
            })
        }
    }
}
