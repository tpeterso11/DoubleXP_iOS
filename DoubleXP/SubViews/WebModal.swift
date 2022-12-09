//
//  WebModal.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 5/19/22.
//  Copyright © 2022 Peterson, Toussaint. All rights reserved.
//

import Foundation
import UIKit
import WebKit

class WebModal: UIViewController, WKNavigationDelegate {
    
    @IBOutlet weak var webView: WKWebView!
    var url: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let url = URL(string: self.url ?? "")!
        webView.navigationDelegate = self
        webView.load(URLRequest(url: url))
        webView.allowsBackForwardNavigationGestures = true
    }
}
