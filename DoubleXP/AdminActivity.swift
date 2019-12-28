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
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let theImage = headerImage.image!
        let filter = CIFilter(name: "CIColorInvert")
        filter?.setValue(CIImage(image: theImage), forKey: kCIInputImageKey)
        let newImage = UIImage(ciImage: (filter?.outputImage)!)
        headerImage.image = newImage
        
        loginButton.addTarget(self, action: #selector(loginButtonClicked), for: .touchUpInside)
        registerButton.addTarget(self, action: #selector(registerButtonClicked), for: .touchUpInside)
    }
    
    @objc func loginButtonClicked(_ sender: AnyObject?) {
        self.performSegue(withIdentifier: "adminLogin", sender: nil)
    }
    
    @objc func registerButtonClicked(_ sender: AnyObject?) {
        self.performSegue(withIdentifier: "adminRegister", sender: nil)
    }
}
