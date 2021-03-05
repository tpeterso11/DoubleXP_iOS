//
//  ProfileLookingForCell.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 2/28/21.
//  Copyright © 2021 Peterson, Toussaint. All rights reserved.
//

import Foundation
import UIKit

class ProfileLookingForCell : UITableViewCell, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    @IBOutlet weak var lookingForCollection: UICollectionView!
    var payload = [String]()
    var collectionViewObserver: NSKeyValueObservation?

    
    func setCollection(list: [LookingForSelection], completion: (() -> Void)?){
        self.payload = createPayload(list: list)
        
        self.lookingForCollection.delegate = self
        self.lookingForCollection.dataSource = self
        self.lookingForCollection.reloadData()
        //self.updateConstraintsIfNeeded()
        //self.layoutIfNeeded()
    }
    
    override func systemLayoutSizeFitting(_ targetSize: CGSize, withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority, verticalFittingPriority: UILayoutPriority) -> CGSize {
            // `collectionView.contentSize` has a wrong width because in this nested example, the sizing pass occurs before the layout pass,
            // so we need to force a layout pass with the correct width.
            self.contentView.frame = self.bounds
            self.contentView.layoutIfNeeded()
            // Returns `collectionView.contentSize` in order to set the UITableVieweCell height a value greater than 0.
        return CGSize(width: self.lookingForCollection.contentSize.width, height: self.lookingForCollection.contentSize.height + 80)
    }
    
    private func createPayload(list: [LookingForSelection]) -> [String] {
        var payload = [String]()
        for selection in list {
            payload.append(contentsOf: selection.choices)
        }
        return payload
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.payload.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let current = self.payload[indexPath.item]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "option", for: indexPath) as! LookingOptionCell
        cell.lookingLabel.text = current
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
            return 8.0
        }
        
        func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
            return 8.0
        }
}
