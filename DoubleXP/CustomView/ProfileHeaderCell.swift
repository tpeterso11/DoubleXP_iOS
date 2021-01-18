//
//  ProfileHeaderCell.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 10/31/20.
//  Copyright © 2020 Peterson, Toussaint. All rights reserved.
//

import Foundation
import UIKit

class ProfileHeaderCell: UITableViewCell, UICollectionViewDelegate, UICollectionViewDataSource {
    @IBOutlet weak var more: UIImageView!
    @IBOutlet weak var gamertag: UILabel!
    @IBOutlet weak var consoleCollection: UICollectionView!
    @IBOutlet weak var onlineStatus: UILabel!
    @IBOutlet weak var onlineDot: UIImageView!
    var payload = [String]()
    
    
    func setConsoles(consoles: [String]){
        self.payload = consoles
        self.consoleCollection.delegate = self
        self.consoleCollection.dataSource = self
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return payload.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "console", for: indexPath) as! ProfileConsoleCell
        let current = self.payload[indexPath.item]
        cell.console.text = current
        
        cell.contentView.layer.cornerRadius = 10.0
        cell.contentView.layer.borderWidth = 1.0
        cell.contentView.layer.borderColor = UIColor.clear.cgColor
        cell.contentView.layer.masksToBounds = true
        
        cell.layer.shadowColor = UIColor.black.cgColor
        cell.layer.shadowOffset = CGSize(width: 0, height: 1.0)
        cell.layer.shadowRadius = 1.0
        cell.layer.shadowOpacity = 0.5
        cell.layer.masksToBounds = false
        cell.layer.shadowPath = UIBezierPath(roundedRect: cell.bounds, cornerRadius: cell.contentView.layer.cornerRadius).cgPath
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: CGFloat(80), height: CGFloat(50))
    }
}
