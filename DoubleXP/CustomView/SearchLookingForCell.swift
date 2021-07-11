//
//  SearchLookingForCell.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 4/4/21.
//  Copyright © 2021 Peterson, Toussaint. All rights reserved.
//

import Foundation
import UIKit
import PopupDialog
import SPStorkController

class SearchLookingForCell: UITableViewCell, UICollectionViewDelegate, UICollectionViewDataSource {
    @IBOutlet weak var lookingForCells: UICollectionView!
    @IBOutlet weak var lookingForDialogClickArea: UIView!
    var payload = [String]()
    var dataSet = false
    var search: GamerConnectSearch?
    
    func setPayload(payload: [String], search: GamerConnectSearch){
        self.payload = payload
        self.search = search
        
        let dialogTap = UITapGestureRecognizer(target: self, action: #selector(self.showLookingForDialog))
        self.lookingForDialogClickArea.isUserInteractionEnabled = true
        self.lookingForDialogClickArea.addGestureRecognizer(dialogTap)
        
        if(!dataSet){
            self.dataSet = true
            let alignedFlowLayout = AlignedCollectionViewFlowLayout(horizontalAlignment: .leading, verticalAlignment: .top)
            alignedFlowLayout.estimatedItemSize = .init(width: 100, height: 40)
            self.lookingForCells.collectionViewLayout = alignedFlowLayout
            self.lookingForCells.delegate = self
            self.lookingForCells.dataSource = self
        } else {
            self.lookingForCells.reloadData()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return payload.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let current = self.payload[indexPath.item]
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "option", for: indexPath) as! LookingOptionCell
        cell.lookingLabel.text = current
        cell.coverLabel.text = current
        
        if(delegate.searchManager.searchLookingFor.contains(current)){
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
        return CGSize(width: self.lookingForCells.contentSize.width, height: self.lookingForCells.contentSize.height + 80)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let current = self.payload[indexPath.item]
        self.search!.addRemoveChoice(selected: current)
    }
    
    @objc func showLookingForDialog(){
        var buttons = [PopupDialogButton]()
        let title = "what is this?"
        let message = "we search through gamer profiles to see who matches what you are looking for. by setting this in your gamer profile, we can help find your best match!"
        
        let button = DefaultButton(title: "setup MY gamer profile") { [weak self] in
            self?.showUpgradeFrag()
        }
        buttons.append(button)
        
        let buttonOne = CancelButton(title: "ohhhh, i get it.") { [weak self] in
            //do nothing
        }
        buttons.append(buttonOne)
        
        let popup = PopupDialog(title: title, message: message)
        popup.addButtons(buttons)

        // Present dialog
        search!.present(popup, animated: true, completion: nil)
    }
    
    private func showUpgradeFrag(){
        let currentViewController = self.search?.storyboard!.instantiateViewController(withIdentifier: "upgrade") as! Upgrade
        currentViewController.extra = "quiz"
        
        let transitionDelegate = SPStorkTransitioningDelegate()
        currentViewController.transitioningDelegate = transitionDelegate
        currentViewController.modalPresentationStyle = .custom
        currentViewController.modalPresentationCapturesStatusBarAppearance = true
        transitionDelegate.showIndicator = true
        transitionDelegate.swipeToDismissEnabled = true
        transitionDelegate.hapticMoments = [.willPresent, .willDismiss]
        transitionDelegate.storkDelegate = self.search
        self.search?.present(currentViewController, animated: true, completion: nil)
    }
}
