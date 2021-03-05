//
//  Recommended.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 12/27/20.
//  Copyright © 2020 Peterson, Toussaint. All rights reserved.
//

import Foundation
import UIKit
import SPStorkController

class Recommeded: UIViewController, UITableViewDelegate, UITableViewDataSource, SPStorkControllerDelegate {
    
    @IBOutlet weak var hookupTable: UITableView!
    var payload = [Any]()
    var currentSelection = "best"
    var currentTag = "legend, like hidden temple."
    var users = [User]()
    var count = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let manager = appDelegate.recommendedUsersManager
        
        if(!manager.bestMatch.isEmpty){
            count += 1
            if(!manager.locationUsers.isEmpty) {
                count += 1
            }
            if(!manager.random.isEmpty){
                count += 1
            }
            setBestSelected(count: count)
        } else if(!manager.locationUsers.isEmpty) {
            count += 1
            if(!manager.random.isEmpty){
                count += 1
            }
            setLocationSelected(count: count)
        } else if(!manager.random.isEmpty){
            count += 1
            setLuckySelected(count: count)
        }
        
        if(count == 1){
            setLuckySelected(count: count)
        }
        
        self.hookupTable.delegate = self
        self.hookupTable.dataSource = self
    }
    
    @objc private func handleSwitch(sender: RecommededGesture){
        if(sender.recommedTag == "lucky" && self.currentSelection != "lucky"){
            self.setLuckySelected(count: sender.count)
        } else if(sender.recommedTag == "best" && self.currentSelection != "best"){
            self.setBestSelected(count: sender.count)
        } else if(sender.recommedTag == "location" && self.currentSelection != "location"){
            self.setLocationSelected(count: sender.count)
        }
    }
    
    private func setLocationSelected(count: Int){
        self.payload = [Any]()
        self.payload.append("header")
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let manager = appDelegate.recommendedUsersManager
        self.currentSelection = "location"
        self.currentTag = "irl distance"
        if(count > 1){
            self.payload.append([self.currentSelection, self.currentTag])
        }
        var locationPayload = [Any]()
        locationPayload.append(manager.getRecommendedGame())
        locationPayload.append(contentsOf: manager.locationUsers)
        self.payload.append(locationPayload)
        payload.append(true)
        self.hookupTable.reloadData()
    }
    
    private func setLuckySelected(count: Int){
        self.payload = [Any]()
        self.payload.append("header")
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let manager = appDelegate.recommendedUsersManager
        self.currentSelection = "lucky"
        self.currentTag = "our best guess based on this and that."
        if(count > 1){
            self.payload.append([self.currentSelection, self.currentTag])
        }
        var locationPayload = [Any]()
        locationPayload.append(manager.getRecommendedGame())
        locationPayload.append(contentsOf: manager.random)
        self.payload.append(locationPayload)
        payload.append(true)
        self.hookupTable.reloadData()
    }
    
    private func setBestSelected(count: Int){
        self.payload = [Any]()
        self.payload.append("header")
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let manager = appDelegate.recommendedUsersManager
        self.currentSelection = "best"
        self.currentTag = "legend, like hidden temple."
        if(count > 1){
            self.payload.append([self.currentSelection, self.currentTag])
        }
        var locationPayload = [Any]()
        locationPayload.append(manager.getRecommendedGame())
        locationPayload.append(contentsOf: manager.bestMatch)
        self.payload.append(locationPayload)
        payload.append(true)
        self.hookupTable.reloadData()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.payload.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let current = self.payload[indexPath.item]
        if(current is String){
            let cell = tableView.dequeueReusableCell(withIdentifier: "header", for: indexPath) as! RecommendHeaderCell
            
            let testBounds = CGRect(x: cell.headerImage.bounds.minX, y: cell.headerImage.bounds.minY, width: self.view.bounds.width + 200, height: cell.headerImage.bounds.height)
            let maskLayer = CAGradientLayer(layer: cell.headerImage.layer)
            maskLayer.colors = [UIColor.init(named: "whiteBackToDarkGrey")?.cgColor ?? UIColor.black.cgColor, UIColor.clear.cgColor]
            maskLayer.startPoint = CGPoint(x: 0, y: 0.7)
            maskLayer.endPoint = CGPoint(x: 0, y: 1)
            maskLayer.frame = testBounds
            cell.headerImage.layer.mask = maskLayer
            return cell
        }
        else if(current is [String]){
            let cell = tableView.dequeueReusableCell(withIdentifier: "options", for: indexPath) as! RecommendOptionsCell
            cell.selection.text = self.currentSelection
            cell.selectedTag.text = self.currentTag
            
            cell.luckyButton.layer.shadowColor = UIColor.black.cgColor
            cell.luckyButton.layer.shadowOffset = CGSize(width: 0, height: 2.0)
            cell.luckyButton.layer.shadowRadius = 2.0
            cell.luckyButton.layer.shadowOpacity = 0.5
            cell.luckyButton.layer.masksToBounds = false
            cell.luckyButton.layer.shadowPath = UIBezierPath(roundedRect: cell.luckyButton.bounds, cornerRadius: cell.luckyButton.layer.cornerRadius).cgPath
            
            cell.bestMatch.layer.shadowColor = UIColor.black.cgColor
            cell.bestMatch.layer.shadowOffset = CGSize(width: 0, height: 2.0)
            cell.bestMatch.layer.shadowRadius = 2.0
            cell.bestMatch.layer.shadowOpacity = 0.5
            cell.bestMatch.layer.masksToBounds = false
            cell.bestMatch.layer.shadowPath = UIBezierPath(roundedRect: cell.bestMatch.bounds, cornerRadius: cell.bestMatch.layer.cornerRadius).cgPath
            
            cell.locationButton.layer.shadowColor = UIColor.black.cgColor
            cell.locationButton.layer.shadowOffset = CGSize(width: 0, height: 2.0)
            cell.locationButton.layer.shadowRadius = 2.0
            cell.locationButton.layer.shadowOpacity = 0.5
            cell.locationButton.layer.masksToBounds = false
            cell.locationButton.layer.shadowPath = UIBezierPath(roundedRect: cell.locationButton.bounds, cornerRadius: cell.locationButton.layer.cornerRadius).cgPath
            
            if(currentSelection == "best"){
                cell.selection.text = "best match"
                cell.bestMatch.backgroundColor = #colorLiteral(red: 0.5058823824, green: 0.3372549117, blue: 0.06666667014, alpha: 1)
                cell.luckyButton.backgroundColor = #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)
                cell.locationButton.backgroundColor = #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)
                
                cell.luckyTag.font = UIFont.systemFont(ofSize: cell.luckyTag.font.pointSize)
                cell.locationTag.font = UIFont.systemFont(ofSize: cell.locationTag.font.pointSize)
                cell.bestTag.font = UIFont.boldSystemFont(ofSize: cell.bestTag.font.pointSize)
                
            } else if(currentSelection == "lucky") {
                cell.selection.text = "basic"
                cell.bestMatch.backgroundColor = #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)
                cell.luckyButton.backgroundColor = #colorLiteral(red: 0.1764705926, green: 0.4980392158, blue: 0.7568627596, alpha: 1)
                cell.locationButton.backgroundColor = #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)
                
                cell.luckyTag.font = UIFont.boldSystemFont(ofSize: cell.luckyTag.font.pointSize)
                cell.locationTag.font = UIFont.systemFont(ofSize: cell.locationTag.font.pointSize)
                cell.bestTag.font = UIFont.systemFont(ofSize: cell.bestTag.font.pointSize)
            } else {
                cell.selection.text = "better"
                
                cell.bestMatch.backgroundColor = #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)
                cell.luckyButton.backgroundColor = #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)
                cell.locationButton.backgroundColor = #colorLiteral(red: 0.6423664689, green: 0, blue: 0.04794860631, alpha: 1)
                
                cell.luckyTag.font = UIFont.systemFont(ofSize: cell.luckyTag.font.pointSize)
                cell.locationTag.font = UIFont.boldSystemFont(ofSize: cell.locationTag.font.pointSize)
                cell.bestTag.font = UIFont.systemFont(ofSize: cell.bestTag.font.pointSize)
            }
            
            let luckyTap = RecommededGesture(target: self, action: #selector(handleSwitch))
            luckyTap.recommedTag = "lucky"
            luckyTap.count = self.count
            cell.luckyButton.isUserInteractionEnabled = true
            cell.luckyButton.addGestureRecognizer(luckyTap)
            
            let bestTap = RecommededGesture(target: self, action: #selector(handleSwitch))
            bestTap.recommedTag = "best"
            bestTap.count = self.count
            cell.bestMatch.isUserInteractionEnabled = true
            cell.bestMatch.addGestureRecognizer(bestTap)
            
            let locationTap = RecommededGesture(target: self, action: #selector(handleSwitch))
            locationTap.recommedTag = "location"
            locationTap.count = self.count
            cell.locationButton.isUserInteractionEnabled = true
            cell.locationButton.addGestureRecognizer(locationTap)
            
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let manager = appDelegate.recommendedUsersManager
            if(manager.bestMatch.isEmpty){
                cell.bestMatch.alpha = 0.3
                cell.bestMatch.isUserInteractionEnabled = false
            }
            if(manager.locationUsers.isEmpty){
                cell.locationButton.alpha = 0.3
                cell.locationButton.isUserInteractionEnabled = false
            }
            if(manager.random.isEmpty){
                cell.luckyButton.alpha = 0.3
                cell.luckyButton.isUserInteractionEnabled = false
            }
            
            return cell
        } else if(current is Bool){
            let cell = tableView.dequeueReusableCell(withIdentifier: "empty", for: indexPath) as! EmptyCell
            return cell
        } else {
            let currentArray = self.payload[indexPath.item] as? [Any] ?? [Any]()
            let cell = tableView.dequeueReusableCell(withIdentifier: "users", for: indexPath) as! RecommendUsersCell
            cell.setPayload(payload: currentArray, recommeded: self)
            return cell
        }
    }
    
    func launchGamePage(game: GamerConnectGame){
        let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "discoverGame") as! DiscoverGamePage
        currentViewController.game = game
        
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
    
    func launchProfileForUser(uid: String){
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.cachedTest = uid
        
        let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "playerProfile") as! PlayerProfile
        let transitionDelegate = SPStorkTransitioningDelegate()
        currentViewController.transitioningDelegate = transitionDelegate
        currentViewController.modalPresentationStyle = .custom
        currentViewController.modalPresentationCapturesStatusBarAppearance = true
        currentViewController.editMode = false
        transitionDelegate.showIndicator = true
        transitionDelegate.swipeToDismissEnabled = true
        transitionDelegate.hapticMoments = [.willPresent, .willDismiss]
        transitionDelegate.storkDelegate = self
        self.present(currentViewController, animated: true, completion: nil)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let current = payload[indexPath.item]
        if(current is String){
            return 295
        } else if(current is [String]){
            return 190
        } else if(current is Bool){
            return 50
        } else {
            return 400
        }
    }
}

class RecommededGesture: UITapGestureRecognizer {
    var recommedTag: String!
    var count: Int!
}
