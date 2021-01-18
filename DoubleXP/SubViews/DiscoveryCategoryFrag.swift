//
//  DiscoveryCategoryFrag.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 11/22/20.
//  Copyright © 2020 Peterson, Toussaint. All rights reserved.
//

import Foundation
import UIKit
import SPStorkController
import UnderLineTextField

class DiscoveryCategoryFrag : UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, SPStorkControllerDelegate, UITextFieldDelegate {
    var category: DiscoverCategory!
    
    @IBOutlet weak var categoryImage: UIImageView!
    @IBOutlet weak var categoryName: UILabel!
    @IBOutlet weak var searchSub: UILabel!
    @IBOutlet weak var categoryList: UICollectionView!
    
    @IBOutlet weak var search: UnderLineTextField!
    var payload = [GamerConnectGame]()
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.currentDiscoverCat = self
        self.categoryName.text = category.categoryName
        createPayload()
    }
    
    private func createPayload(){
        //image
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let cache = delegate.imageCache
        if(cache.object(forKey: category.imgUrl as NSString) != nil){
            self.categoryImage.image = cache.object(forKey: category.imgUrl as NSString)
        } else {
            self.categoryImage.image = Utility.Image.placeholder
            self.categoryImage.moa.onSuccess = { image in
                self.categoryImage.image = image
                delegate.imageCache.setObject(image, forKey: self.category.imgUrl as NSString)
                return image
            }
            self.categoryImage.moa.url = category.imgUrl
        }
        
        self.categoryImage.contentMode = .scaleAspectFill
        self.categoryImage.clipsToBounds = true
        
        self.payload = configureList()
        self.search.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        self.search.delegate = self
        self.search.returnKeyType = UIReturnKeyType.done
        
        self.categoryList.delegate = self
        self.categoryList.dataSource = self
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.payload.count
    }
    
    private func configureList() -> [GamerConnectGame]{
        var list = [GamerConnectGame]()
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let games = delegate.gcGames
        
        if(self.category.categoryVal == "alphabetical"){
            let sorted = games!.sorted(by: { $0.gameName < $1.gameName })
            list = sorted
        } else if(self.category.categoryVal == "my"){
            var fixedList = [GamerConnectGame]()
            for game in games! {
                if(delegate.currentUser!.games.contains(game.gameName)){
                    fixedList.append(game)
                }
            }
            let sorted = fixedList.sorted(by: { $0.gameName < $1.gameName })
            list = sorted
        } else {
            var fixedList = [GamerConnectGame]()
            for game in games! {
                if(game.categoryFilters.contains(self.category.categoryVal)){
                    fixedList.append(game)
                }
            }
            let sorted = fixedList.sorted(by: { $0.gameName < $1.gameName })
            list = sorted
        }
        
        return list
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        if(textField.text?.count == 0){
            self.payload = configureList()
        } else {
            self.payload = [GamerConnectGame]()
            var list = [GamerConnectGame]()
            for game in configureList() {
                var contained = false
                for userGame in list {
                    if(game.gameName == userGame.gameName){
                        contained = true
                    }
                }
                if(!contained){
                    list.append(game)
                }
            }
            for game in list {
                if(game.gameName.localizedCaseInsensitiveContains(textField.text!)){
                    self.payload.append(game)
                }
            }
        }
        self.categoryList.reloadData()
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let current = payload[indexPath.item]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "category", for: indexPath) as! DiscoverCategoryCell
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let cache = appDelegate.imageCache
        if(cache.object(forKey: current.imageUrl as NSString) != nil){
            cell.categoryBack.image = cache.object(forKey: current.imageUrl as NSString)
        } else {
            cell.categoryBack.image = Utility.Image.placeholder
            cell.categoryBack.moa.onSuccess = { image in
                cell.categoryBack.image = image
                appDelegate.imageCache.setObject(image, forKey: current.imageUrl as NSString)
                return image
            }
            cell.categoryBack.moa.url = current.imageUrl
        }
        
        cell.categoryBack.contentMode = .scaleAspectFill
        cell.categoryBack.clipsToBounds = true
        
        cell.contentView.layer.cornerRadius = 10.0
        cell.contentView.layer.borderWidth = 1.0
        cell.contentView.layer.borderColor = UIColor.clear.cgColor
        cell.contentView.layer.masksToBounds = true
        
        cell.layer.shadowColor = UIColor.black.cgColor
        cell.layer.shadowOffset = CGSize(width: 0, height: 2.0)
        cell.layer.shadowRadius = 2.0
        cell.layer.shadowOpacity = 0.5
        cell.layer.masksToBounds = false
        cell.layer.shadowPath = UIBezierPath(roundedRect: cell.bounds, cornerRadius: cell.contentView.layer.cornerRadius).cgPath
        
        cell.developer.text = current.developer
        cell.gameName.text = current.gameName
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.bounds.size.width - 20, height: CGFloat(80))
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        dismissKeyboard()
        let current = payload[indexPath.item]
        
        let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "discoverGame") as! DiscoverGamePage
        currentViewController.game = current
        
        let transitionDelegate = SPStorkTransitioningDelegate()
        currentViewController.transitioningDelegate = transitionDelegate
        currentViewController.modalPresentationStyle = .custom
        currentViewController.modalPresentationCapturesStatusBarAppearance = true
        transitionDelegate.showIndicator = true
        transitionDelegate.swipeToDismissEnabled = true
        transitionDelegate.hapticMoments = [.willPresent, .willDismiss]
        transitionDelegate.storkDelegate = self
        self.present(currentViewController, animated: true, completion: nil)
    }
    
    @objc func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool
    {
        textField.resignFirstResponder()
        return true
    }
}
