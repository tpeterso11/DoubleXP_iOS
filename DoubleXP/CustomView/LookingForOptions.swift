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
    var set = false
    
    func setLayout(list: [String], selection: LookingForSelection, lookingFor: LookingFor){
        payload = list
        self.currentSelection = selection
        self.currentLookingFor = lookingFor

        //let alignedFlowLayout = AlignedCollectionViewFlowLayout(horizontalAlignment: .left, verticalAlignment: .top)
       // alignedFlowLayout.estimatedItemSize = .init(width: 100, height: 40)
        //self.lookingForOptionCollection.collectionViewLayout = alignedFlowLayout
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
        
        if(self.currentLookingFor!.usersSelected.contains(current)){
            cell.cover.alpha = 1
            cell.lookingLabel.alpha = 0
        } else {
            cell.cover.alpha = 0
            cell.lookingLabel.alpha = 1
        }
        
        return cell
    }
    
    override func systemLayoutSizeFitting(_ targetSize: CGSize, withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority, verticalFittingPriority: UILayoutPriority) -> CGSize {
            // `collectionView.contentSize` has a wrong width because in this nested example, the sizing pass occurs before the layout pass,
            // so we need to force a layout pass with the correct width.
            self.contentView.frame = self.bounds
            self.contentView.layoutIfNeeded()
            // Returns `collectionView.contentSize` in order to set the UITableVieweCell height a value greater than 0.
        return CGSize(width: self.lookingForOptionCollection.contentSize.width, height: self.lookingForOptionCollection.contentSize.height + 80)
    }
}
