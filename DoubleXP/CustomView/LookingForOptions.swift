//
//  LookingForOptions.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 2/27/21.
//  Copyright © 2021 Peterson, Toussaint. All rights reserved.
//

import Foundation
import UIKit
//import collection_view_layouts

class LookingForOptions: UITableViewCell, UICollectionViewDelegate, UICollectionViewDataSource {
    
    @IBOutlet weak var lookingForOptionCollection: UICollectionView!
    var payload = [String]()
    var currentSelection: LookingForSelection?
    var currentLookingFor: LookingFor?
    var currentSelectedCount = 0
    
    func setLayout(list: [String], selection: LookingForSelection, lookingFor: LookingFor){
        payload = list
        self.currentSelection = selection
        self.currentLookingFor = lookingFor

        lookingForOptionCollection.delegate = self
        lookingForOptionCollection.dataSource = self
        lookingForOptionCollection.reloadData()
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let current = self.payload[indexPath.item]
        self.currentLookingFor?.addRemoveChoice(selected: current, choice: self.currentSelection!)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return payload.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let current = self.payload[indexPath.item]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "option", for: indexPath) as! LookingOptionCell
        cell.lookingLabel.text = current
        cell.coverLabel.text = current
        
        if(self.currentLookingFor!.selectionHasBeenSelected(option: current, current: self.currentSelection!)){
            cell.cover.alpha = 1
        } else {
            cell.cover.alpha = 0
        }
        
        return cell
    }
}
