//
//  AdminActivity.swift
//  DoubleXP
//
//  Created by Peterson, Toussaint on 4/16/19.
//  Copyright © 2019 Peterson, Toussaint. All rights reserved.
//

import UIKit

class AdminActivity: UIViewController {
    @IBOutlet weak var headerImage: UIImageView!
    //@IBOutlet weak var lookAround: UIButton!
    @IBOutlet weak var registerButton: UIButton!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet var background: UIView!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.performSegue(withIdentifier: "adminLogin", sender: nil)
//        let theImage = headerImage.image!
//        let filter = CIFilter(name: "CIColorInvert")
//        filter?.setValue(CIImage(image: theImage), forKey: kCIInputImageKey)
//        let newImage = UIImage(ciImage: (filter?.outputImage)!)
//        headerImage.image = newImage
//
//        loginButton.addTarget(self, action: #selector(loginButtonClicked), for: .touchUpInside)
//        registerButton.addTarget(self, action: #selector(registerButtonClicked), for: .touchUpInside)
//
//        background.applyGradient(colours:  [#colorLiteral(red: 1, green: 1, blue: 1, alpha: 1), #colorLiteral(red: 0.9280989766, green: 0.9225817919, blue: 0.9323399663, alpha: 1)], orientation: .vertical)
    }
    
    @objc func loginButtonClicked(_ sender: AnyObject?) {
        self.performSegue(withIdentifier: "adminLogin", sender: nil)
    }
    
    @objc func registerButtonClicked(_ sender: AnyObject?) {
        self.performSegue(withIdentifier: "adminRegister", sender: nil)
    }
}
