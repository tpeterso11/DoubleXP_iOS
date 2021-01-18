//
//  EditProfileTagCell.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 11/16/20.
//  Copyright © 2020 Peterson, Toussaint. All rights reserved.
//

import Foundation
import UIKit

class EditProfileTagCell: UICollectionViewCell, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tagTable: UITableView!
    var payload = [String]()
    var modal: ProfileFrag?
    
    func setTable(list: [String], modal: ProfileFrag){
        self.payload = list
        self.modal = modal
        self.tagTable.dataSource = self
        self.tagTable.delegate = self
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        self.payload.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! EditProfilePreferredTagCell
        let current = payload[indexPath.item]
        cell.coverLabel.text = current
        cell.mainLabel.text = current
        
        if(modal?.selectedTag == current){
            cell.cover.alpha = 1
            cell.mainLabel.alpha = 0
        } else {
            cell.cover.alpha = 0
            cell.mainLabel.alpha = 1
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let current = payload[indexPath.item]
        modal?.selectedTag = current
        tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return CGFloat(40)
    }
}
