//
//  Untitled.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 9/29/24.
//  Copyright © 2024 Peterson, Toussaint. All rights reserved.
//

import UIKit

class CustomTableView: UITableView {
    
    // Custom initializer
    init() {
        super.init(frame: .zero, style: .plain)
        
        // Set up table view properties
        self.translatesAutoresizingMaskIntoConstraints = false
        self.isScrollEnabled = false  // Disable scrolling so the height adjusts
        
        // Register a simple UITableViewCell
        self.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
