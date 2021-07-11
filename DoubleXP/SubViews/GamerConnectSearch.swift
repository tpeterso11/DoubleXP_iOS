//
//  GamerConnectSearch.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 11/16/19.
//  Copyright © 2019 Peterson, Toussaint. All rights reserved.
//

import UIKit
import Firebase
import moa
import SwiftNotificationCenter
import MSPeekCollectionViewDelegateImplementation
import FBSDKCoreKit
import SPStorkController
import Lottie
import SwiftLocation
import PopupDialog
import CoreLocation
import GeoFire

class GamerConnectSearch: ParentVC, UICollectionViewDelegate, UICollectionViewDataSource,  UICollectionViewDelegateFlowLayout, SearchCallbacks, SPStorkControllerDelegate, SearchManagerCallbacks, UITableViewDelegate, UITableViewDataSource, CLLocationManagerDelegate {
    
    var game: GamerConnectGame? = nil
    
    var returnedUsers = [Any]()
    var searchPS = false
    var searchXbox = false
    var searchNintendo = false
    var searchPC = false
    var searchMobile = false
    var set = false
    var frontSearchPayload = [Any]()
    
    @IBOutlet weak var searchBlur: UIVisualEffectView!
    @IBOutlet weak var filterButton: UIImageView!
    @IBOutlet weak var gameHeaderImage: UIImageView!
    @IBOutlet weak var gamerConnectResults: UICollectionView!
    @IBOutlet weak var psSwitch: UISwitch!
    @IBOutlet weak var xboxSwitch: UISwitch!
    @IBOutlet weak var nintendoSwitch: UISwitch!
    @IBOutlet weak var pcSwitch: UISwitch!
    @IBOutlet weak var searchEmpty: UIView!
    @IBOutlet weak var searchEmptyText: UILabel!
    @IBOutlet weak var searchEmptySub: UILabel!
    @IBOutlet weak var loadingView: UIView!
    @IBOutlet weak var searchAnimation: AnimationView!
    @IBOutlet weak var psLabel: UILabel!
    @IBOutlet weak var pcLabel: UILabel!
    @IBOutlet weak var xboxLabel: UILabel!
    @IBOutlet weak var nintendoLabel: UILabel!
    @IBOutlet weak var mobileLabel: UILabel!
    @IBOutlet weak var mobileSwitch: UISwitch!
    @IBOutlet weak var searchTable: UITableView!
    var basicFilterList = [filterCell]()
    var locationCell: filterCell?
    var popup: PopupDialog?
    var currentManager: SearchManager!
    var currentLocationActivationCell: FilterActivateCell?
    
    var currentUser: User!
    var locationManager: CLLocationManager?
    var req: LocationRequest?
    var currentLocationIndexPath: IndexPath?
    var usersSelectedTags = [String]()
    
    override func viewWillAppear(_ animated: Bool) {
        if self.traitCollection.userInterfaceStyle == .dark {
            self.searchBlur.effect = UIBlurEffect(style: .dark)
                } else {
                    self.searchBlur.effect = UIBlurEffect(style: .light)
                }
        super.viewWillAppear(animated)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //check rivals on entry.
        
        if(game != nil){
            //gameHeaderImage.alpha = 0
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let cache = appDelegate.imageCache
            if(cache.object(forKey: game!.imageUrl as NSString) != nil){
                gameHeaderImage.image = cache.object(forKey: game!.imageUrl as NSString)
            } else {
                gameHeaderImage.image = Utility.Image.placeholder
                gameHeaderImage.moa.onSuccess = { image in
                    self.gameHeaderImage.image = image
                    appDelegate.imageCache.setObject(image, forKey: self.game!.imageUrl as NSString)
                    return image
                }
                gameHeaderImage.moa.url = game!.imageUrl
            }
            gameHeaderImage.contentMode = .scaleAspectFill
            
            let testBounds = CGRect(x: self.gameHeaderImage.bounds.minX, y: self.gameHeaderImage.bounds.minY, width: self.view.bounds.width, height: self.gameHeaderImage.bounds.height)
            
            
            let maskLayer = CAGradientLayer(layer: self.gameHeaderImage.layer)
            maskLayer.colors = [UIColor.black.cgColor, UIColor.clear.cgColor]
            maskLayer.startPoint = CGPoint(x: 0, y: 0.5)
            maskLayer.endPoint = CGPoint(x: 0, y: 1)
            maskLayer.frame = testBounds
            self.gameHeaderImage.layer.mask = maskLayer
            
            /*gameHeaderImage.layer.shadowColor = UIColor.black.cgColor
            gameHeaderImage.layer.shadowOffset = CGSize(width: 0, height: 2.0)
            gameHeaderImage.layer.shadowRadius = 2.0
            gameHeaderImage.layer.shadowOpacity = 0.5
            gameHeaderImage.layer.masksToBounds = true
            gameHeaderImage.layer.shadowPath = UIBezierPath(roundedRect: gameHeaderImage.bounds, cornerRadius: gameHeaderImage.layer.cornerRadius).cgPath*/
            //gameImageHeader.clipsToBounds = true
            
            searchPS = false
            searchXbox = false
            searchNintendo = false
            searchPC = false
            
            let delegate = UIApplication.shared.delegate as! AppDelegate
            delegate.currentGCSearchFrag = self
            currentUser = delegate.currentUser
            let manager = delegate.searchManager
            manager.currentUser = currentUser
            manager.currentGameSearch = game?.gameName ?? ""
            manager.resetFilters()
            
            var availableCount = 0
            var userConsolesForGame = [String]()
            var psAvailable = false
            var xboxAvailable = false
            var nintendoAvailable = false
            var mobileAvailable = false
            var pcAvailable = false
            
            for profile in currentUser!.gamerTags {
                if(profile.game == game!.gameName){
                    userConsolesForGame.append(profile.console)
                }
            }
            
            if(game!.availablebConsoles.contains("ps")){
                psAvailable = true
                availableCount += 1
            }
            if(game!.availablebConsoles.contains("xbox")){
                xboxAvailable = true
                availableCount += 1
            }
            if(game!.availablebConsoles.contains("nintendo")){
                nintendoAvailable = true
                availableCount += 1
            }
            
            if(game!.availablebConsoles.contains("pc")){
                pcAvailable = true
                availableCount += 1
            }
            
            if(game!.availablebConsoles.contains("mobile")){
                mobileAvailable = true
                availableCount += 1
            }
            
            if(availableCount == 0 || availableCount == 1){
                self.pcSwitch.alpha = 0.4
                self.pcLabel.alpha = 0.4
                self.mobileSwitch.alpha = 0.4
                self.mobileLabel.alpha = 0.4
                self.psSwitch.alpha = 0.4
                self.psLabel.alpha = 0.4
                self.nintendoSwitch.alpha = 0.4
                self.nintendoLabel.alpha = 0.4
                self.xboxSwitch.alpha = 0.4
                self.xboxLabel.alpha = 0.4
                
                if(availableCount == 1){
                    if(psAvailable){
                        searchPS = true
                        self.psSwitch.setOn(true, animated: false)
                        manager.currentSelectedConsoles.append("ps")
                    }
                    if(xboxAvailable){
                        searchXbox = true
                        self.xboxSwitch.setOn(true, animated: false)
                        manager.currentSelectedConsoles.append("xbox")
                    }
                    if(nintendoAvailable){
                        searchNintendo = true
                        self.nintendoSwitch.setOn(true, animated: false)
                        manager.currentSelectedConsoles.append("nintendo")
                    }
                    if(pcAvailable){
                        searchPC = true
                        self.pcSwitch.setOn(true, animated: false)
                        manager.currentSelectedConsoles.append("pc")
                    }
                    if(mobileAvailable){
                        searchMobile = true
                        self.mobileSwitch.setOn(true, animated: false)
                        manager.currentSelectedConsoles.append("mobile")
                    }
                }
            } else  {
                if(psAvailable){
                    psSwitch.alpha = 1.0
                    psLabel.alpha = 1.0
                    psSwitch.isEnabled = true
                    
                    var contained = false
                    for console in userConsolesForGame {
                        if(console == "ps"){
                            contained = true
                        }
                    }
                    if(contained){
                        psSwitch.isOn = true
                        searchPS = true
                        manager.currentSelectedConsoles.append("ps")
                    } else {
                        if(userConsolesForGame.isEmpty){
                            psSwitch.isOn = true
                            searchPS = true
                            manager.currentSelectedConsoles.append("ps")
                        } else {
                            psSwitch.isOn = false
                            searchPS = false
                        }
                    }
                    psSwitch.addTarget(self, action: #selector(psSwitchChanged), for: UIControl.Event.valueChanged)
                } else {
                    psSwitch.alpha = 0.3
                    psLabel.alpha = 0.3
                    psSwitch.isEnabled = false
                }
                if(xboxAvailable){
                    xboxSwitch.alpha = 1.0
                    xboxLabel.alpha = 1.0
                    xboxSwitch.isEnabled = true
                    
                    var contained = false
                    for console in userConsolesForGame {
                        if(console == "xbox"){
                            contained = true
                        }
                    }
                    if(contained){
                        xboxSwitch.setOn(true, animated: false)
                        searchXbox = true
                        manager.currentSelectedConsoles.append("xbox")
                    } else {
                        if(userConsolesForGame.isEmpty){
                            xboxSwitch.setOn(true, animated: false)
                            searchXbox = true
                            manager.currentSelectedConsoles.append("xbox")
                        } else {
                            xboxSwitch.setOn(false, animated: false)
                            searchXbox = false
                        }
                    }
                    xboxSwitch.addTarget(self, action: #selector(xboxSwitchChanged), for: UIControl.Event.valueChanged)
                } else {
                    xboxSwitch.alpha = 0.3
                    xboxLabel.alpha = 0.3
                    xboxSwitch.isEnabled = false
                }
                if(nintendoAvailable){
                    nintendoSwitch.alpha = 1.0
                    nintendoLabel.alpha = 1.0
                    nintendoSwitch.isEnabled = true
                    
                    var contained = false
                    for console in userConsolesForGame {
                        if(console == "nintendo"){
                            contained = true
                        }
                    }
                    if(contained){
                        nintendoSwitch.setOn(true, animated: false)
                        searchNintendo = true
                        manager.currentSelectedConsoles.append("nintendo")
                    } else {
                        if(userConsolesForGame.isEmpty){
                            nintendoSwitch.setOn(true, animated: false)
                            searchNintendo = true
                            manager.currentSelectedConsoles.append("nintendo")
                        } else {
                            nintendoSwitch.setOn(false, animated: false)
                            searchNintendo = false
                        }
                    }
                    nintendoSwitch.addTarget(self, action: #selector(nintendoSwitchChanged), for: UIControl.Event.valueChanged)
                } else {
                    nintendoSwitch.alpha = 0.3
                    nintendoLabel.alpha = 0.3
                    nintendoSwitch.isEnabled = false
                }
                if(pcAvailable){
                    pcSwitch.alpha = 1.0
                    pcLabel.alpha = 1.0
                    pcSwitch.isEnabled = true
                    
                    var contained = false
                    for console in userConsolesForGame {
                        if(console == "pc"){
                            contained = true
                        }
                    }
                    if(contained){
                        pcSwitch.setOn(true, animated: false)
                        searchPC = true
                        manager.currentSelectedConsoles.append("pc")
                    } else {
                        if(userConsolesForGame.isEmpty){
                            pcSwitch.setOn(true, animated: false)
                            searchPC = true
                            manager.currentSelectedConsoles.append("pc")
                        } else {
                            pcSwitch.setOn(false, animated: false)
                            searchPC = false
                        }
                    }
                    pcSwitch.addTarget(self, action: #selector(pcSwitchChanged), for: UIControl.Event.valueChanged)
                } else {
                    pcSwitch.alpha = 0.3
                    pcLabel.alpha = 0.3
                    pcSwitch.isEnabled = false
                }
                if(mobileAvailable){
                    mobileSwitch.alpha = 1.0
                    mobileLabel.alpha = 1.0
                    mobileSwitch.isEnabled = true
                    
                    var contained = false
                    for console in userConsolesForGame {
                        if(console == "mobile"){
                            contained = true
                        }
                    }
                    if(contained){
                        mobileSwitch.setOn(true, animated: false)
                        searchMobile = true
                        manager.currentSelectedConsoles.append("mobile")
                    } else {
                        if(userConsolesForGame.isEmpty){
                            mobileSwitch.setOn(true, animated: false)
                            searchMobile = true
                            manager.currentSelectedConsoles.append("mobile")
                        } else {
                            mobileSwitch.setOn(false, animated: false)
                            searchMobile = false
                        }
                    }
                    mobileSwitch.addTarget(self, action: #selector(mobileSwitchChanged), for: UIControl.Event.valueChanged)
                } else {
                    mobileSwitch.alpha = 0.3
                    mobileLabel.alpha = 0.3
                    mobileSwitch.isEnabled = false
                }
            }
            
            psSwitch.addTarget(self, action: #selector(psSwitchChanged), for: UIControl.Event.valueChanged)
            pcSwitch.addTarget(self, action: #selector(pcSwitchChanged), for: UIControl.Event.valueChanged)
            xboxSwitch.addTarget(self, action: #selector(xboxSwitchChanged), for: UIControl.Event.valueChanged)
            nintendoSwitch.addTarget(self, action: #selector(nintendoSwitchChanged), for: UIControl.Event.valueChanged)
            
            Broadcaster.register(SearchCallbacks.self, observer: self)
            
            let singleTap = UITapGestureRecognizer(target: self, action: #selector(showFilters))
            filterButton.isUserInteractionEnabled = true
            filterButton.addGestureRecognizer(singleTap)
            
            checkRivals()
            FriendsManager().checkOnlineAnnouncements()
            
            self.searchTable.estimatedRowHeight = 250
            self.searchTable.rowHeight = UITableView.automaticDimension
            self.frontSearchPayload.append("")
            self.searchTable.delegate = self
            self.searchTable.dataSource = self
        }
    }
    
    private func showLoading(){
        if(self.loadingView.alpha == 0){
            self.searchAnimation.play()
            
            UIView.animate(withDuration: 0.5, delay: 0.2, options: [], animations: {
                self.loadingView.alpha = 1
            }, completion: nil)
        }
    }
    
    private func hideLoading(){
        if(self.searchBlur.alpha == 1){
            UIView.animate(withDuration: 0.5, animations: {
                self.loadingView.alpha = 0
            }, completion: { (finished: Bool) in
                UIView.animate(withDuration: 0.5, delay: 0.5, options: [], animations: {
                    self.searchBlur.alpha = 0
                }, completion: nil)
            })
        } else {
            if(self.loadingView.alpha == 1){
                self.searchAnimation.pause()
                
                UIView.animate(withDuration: 0.5, delay: 0.2, options: [], animations: {
                    self.loadingView.alpha = 0
                }, completion: nil)
            }
        }
    }
    
    func dismissModal(){
        self.searchTable.reloadData()
        /*let delegate = UIApplication.shared.delegate as! AppDelegate
        showLoading()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if(delegate.currentUser!.userLat != 0.0){
                delegate.searchManager.searchWithLocation(callbacks: self)
            } else {
                delegate.searchManager.searchWithFilters(callbacks: self)
            }
        }*/
    }
    
    @objc func didDismissStorkBySwipe(){
        self.searchTable.reloadData()
        /*let delegate = UIApplication.shared.delegate as! AppDelegate
        delegate.searchManager.searchWithFilters(callbacks: self)*/
    }
    
    private func checkRivals(){
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let manager = delegate.profileManager
        currentUser = delegate.currentUser
        manager.updateTempRivalsDB()
        
        showLoading()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            let delegate = UIApplication.shared.delegate as! AppDelegate
            let manager = delegate.searchManager
            //manager.searchWithFilters(callbacks: self)
            
            self.currentManager = delegate.searchManager
            
            if(delegate.currentUser!.userLat != 0.0){
                self.updateLocation()
            } else {
                self.buildFilterList()
            }
        }
    }
    
    @objc private func showFilters(){
        UIView.animate(withDuration: 0.5, animations: {
            self.searchBlur.alpha = 1
        }, completion: { (finished: Bool) in
            UIView.animate(withDuration: 0.5, delay: 0.3, options: [], animations: {
                self.searchTable.alpha = 1
            }, completion: nil)
        })
        /*let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "filters") as! GCSearchFilters
        if(self.game != nil){
            currentViewController.gcGame = game
            appDelegate.currentFrag = "Filters"
            
            let transitionDelegate = SPStorkTransitioningDelegate()
            currentViewController.transitioningDelegate = transitionDelegate
            currentViewController.modalPresentationStyle = .custom
            currentViewController.modalPresentationCapturesStatusBarAppearance = true
            transitionDelegate.showIndicator = true
            transitionDelegate.swipeToDismissEnabled = true
            transitionDelegate.hapticMoments = [.willPresent, .willDismiss]
            transitionDelegate.storkDelegate = self
            self.present(currentViewController, animated: true, completion: nil)
        }*/
    }
    
    func stringToDate(_ str: String)->Date{
        let formatter = DateFormatter()
        formatter.dateFormat="yyyy.MM.dd hh:mm aaa"
        return formatter.date(from: str)!
    }
    
    @objc func psSwitchChanged(stationSwitch: UISwitch) {
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let manager = delegate.searchManager
        if(stationSwitch.isOn){
            searchPS = true
            manager.currentSelectedConsoles.append("ps")
        }
        else{
            searchPS = false
            manager.currentSelectedConsoles.remove(at: manager.currentSelectedConsoles.index(of: "ps")!)
        }
        showLoading()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if(delegate.currentUser!.userLat != 0.0){
                delegate.searchManager.searchWithLocation(callbacks: self)
            } else {
                delegate.searchManager.searchWithFilters(callbacks: self)
            }
        }
    }
    @objc func xboxSwitchChanged(xSwitch: UISwitch) {
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let manager = delegate.searchManager
        if(xSwitch.isOn){
            searchXbox = true
            manager.currentSelectedConsoles.append("xbox")
        }
        else{
            searchXbox = false
            manager.currentSelectedConsoles.remove(at: manager.currentSelectedConsoles.index(of: "xbox")!)
        }
        showLoading()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if(delegate.currentUser!.userLat != 0.0){
                delegate.searchManager.searchWithLocation(callbacks: self)
            } else {
                delegate.searchManager.searchWithFilters(callbacks: self)
            }
        }
    }
    @objc func nintendoSwitchChanged(switchSwitch: UISwitch) {
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let manager = delegate.searchManager
        if(switchSwitch.isOn){
            searchNintendo = true
            manager.currentSelectedConsoles.append("nintendo")
        }
        else{
            searchNintendo = false
            manager.currentSelectedConsoles.remove(at: manager.currentSelectedConsoles.index(of: "nintendo")!)
        }
        showLoading()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if(delegate.currentUser!.userLat != 0.0){
                delegate.searchManager.searchWithLocation(callbacks: self)
            } else {
                delegate.searchManager.searchWithFilters(callbacks: self)
            }
        }
    }
    
    @objc func mobileSwitchChanged(switchSwitch: UISwitch) {
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let manager = delegate.searchManager
        if(switchSwitch.isOn){
            searchMobile = true
            manager.currentSelectedConsoles.append("mobile")
        }
        else{
            searchMobile = false
            manager.currentSelectedConsoles.remove(at: manager.currentSelectedConsoles.index(of: "mobile")!)
        }
        showLoading()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if(delegate.currentUser!.userLat != 0.0){
                delegate.searchManager.searchWithLocation(callbacks: self)
            } else {
                delegate.searchManager.searchWithFilters(callbacks: self)
            }
        }
    }
    @objc func pcSwitchChanged(compSwitch: UISwitch) {
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let manager = delegate.searchManager
        if(compSwitch.isOn){
            searchPC = true
            manager.currentSelectedConsoles.append("pc")
        }
        else{
            searchPC = false
            manager.currentSelectedConsoles.remove(at: manager.currentSelectedConsoles.index(of: "pc")!)
        }
        showLoading()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if(delegate.currentUser!.userLat != 0.0){
                delegate.searchManager.searchWithLocation(callbacks: self)
            } else {
                delegate.searchManager.searchWithFilters(callbacks: self)
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return returnedUsers.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let current = self.returnedUsers[indexPath.item]
        if(current is User){
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "userCell", for: indexPath) as! UserCell
            
            let manager = GamerProfileManager()
            let current = returnedUsers[indexPath.item]
            cell.gamerTag.text = manager.getGamerTag(user: (current as! User))
            
            if((current as! User).bio.isEmpty){
                cell.consoleTag.text = "No bio available."
            }
            else{
                cell.consoleTag.text = (current as! User).bio
            }
            
            if((current as! User).onlineStatus.isEmpty){
                cell.onlineStatus.alpha = 0
            } else {
                if((current as! User).onlineStatus == "online"){
                    cell.onlineStatus.alpha = 1
                    cell.onlineStatus.textColor = #colorLiteral(red: 0.2039215686, green: 0.7803921569, blue: 0.3490196078, alpha: 0.6032480736)
                    cell.onlineStatus.text = "online now!"
                } else if((current as! User).onlineStatus == "gaming right NOW!"){
                    cell.onlineStatus.alpha = 1
                    cell.onlineStatus.textColor = #colorLiteral(red: 0.2039215686, green: 0.7803921569, blue: 0.3490196078, alpha: 0.6032480736)
                    cell.onlineStatus.text = "gaming right NOW!"
                    cell.onlineStatus.font = UIFont.boldSystemFont(ofSize: cell.onlineStatus.font.pointSize)
                } else {
                    cell.onlineStatus.alpha = 0
                }
            }
            
            cell.consoleOne.alpha = 1
            
            var oneShowing = false
            var twoShowing = false
            var threeShowing = false
            var fourShowing = false
            for profile in (current as! User).gamerTags {
                if(profile.game == self.game!.gameName){
                    if(profile.console == "ps"){
                        oneShowing = true
                        cell.oneTag.text = "PS"
                    }
                    if(profile.console == "xbox"){
                        if(oneShowing && !twoShowing){
                            cell.twoTag.text = "XBox"
                            twoShowing = true
                            cell.consoleTwo.isHidden = false
                            cell.consoleThree.isHidden = true
                            cell.consoleFour.isHidden = true
                        }
                        else{
                            oneShowing = true
                            cell.oneTag.text = "XBox"
                            twoShowing = false
                            cell.consoleTwo.isHidden = true
                            cell.consoleThree.isHidden = true
                            cell.consoleFour.isHidden = true
                        }
                    }
                    if(profile.console == "nintendo"){
                        if(oneShowing && !twoShowing){
                            cell.twoTag.text = "Nintendo"
                            twoShowing = true
                            cell.consoleTwo.isHidden = false
                            cell.consoleThree.isHidden = true
                            cell.consoleFour.isHidden = true
                        }
                        else if(oneShowing && twoShowing && !threeShowing){
                            threeShowing = true
                            cell.threeTag.text = "Nintendo"
                            cell.consoleThree.isHidden = false
                            cell.consoleFour.isHidden = true
                        }
                        else{
                            oneShowing = true
                            cell.oneTag.text = "Nintendo"
                            twoShowing = false
                            cell.consoleTwo.isHidden = true
                            cell.consoleThree.isHidden = true
                            cell.consoleFour.isHidden = true
                        }
                    }
                    if(profile.console == "pc"){
                        if(oneShowing && !twoShowing){
                            cell.twoTag.text = "PC"
                            twoShowing = true
                            cell.consoleTwo.isHidden = false
                            cell.consoleThree.isHidden = true
                            cell.consoleFour.isHidden = true
                        }
                        else if(oneShowing && twoShowing && !threeShowing){
                            threeShowing = true
                            cell.threeTag.text = "PC"
                            cell.consoleThree.isHidden = false
                            cell.consoleFour.isHidden = true
                        }
                        else if(oneShowing && twoShowing && threeShowing && !fourShowing){
                            fourShowing = true
                            cell.consoleFour.isHidden = false
                            cell.fourTag.text = "PC"
                        }
                        else{
                            oneShowing = true
                            cell.oneTag.text = "PC"
                            cell.consoleTwo.isHidden = true
                            cell.consoleThree.isHidden = true
                            cell.consoleFour.isHidden = true
                        }
                    }
                    if(profile.console == "mobile"){
                        if(oneShowing && !twoShowing){
                            cell.twoTag.text = "Mobile"
                            twoShowing = true
                            cell.consoleTwo.isHidden = false
                            cell.consoleThree.isHidden = true
                            cell.consoleFour.isHidden = true
                        }
                        else if(oneShowing && twoShowing && !threeShowing){
                            threeShowing = true
                            cell.threeTag.text = "Mobile"
                            cell.consoleThree.isHidden = false
                            cell.consoleFour.isHidden = true
                        }
                        else if(oneShowing && twoShowing && threeShowing && !fourShowing){
                            fourShowing = true
                            cell.consoleFour.isHidden = false
                            cell.fourTag.text = "Mobile"
                        }
                        else{
                            oneShowing = true
                            cell.oneTag.text = "Mobile"
                            cell.consoleTwo.isHidden = true
                            cell.consoleThree.isHidden = true
                            cell.consoleFour.isHidden = true
                        }
                    }
                }
            }
            
            if(cell.oneTag.text == "Label"){
                cell.consoleOne.isHidden = true
            }
            
            
            cell.contentView.layer.borderColor = UIColor.clear.cgColor
            cell.contentView.layer.masksToBounds = true
            
            cell.layer.shadowColor = UIColor.black.cgColor
            cell.layer.shadowOffset = CGSize(width: 0, height: 2.0)
            cell.layer.shadowRadius = 2.0
            cell.layer.shadowOpacity = 0.5
            cell.layer.masksToBounds = false
            cell.layer.shadowPath = UIBezierPath(roundedRect: cell.bounds, cornerRadius: cell.contentView.layer.cornerRadius).cgPath
            
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "empty", for: indexPath) as! EmptyCollectionViewCell
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        AppEvents.logEvent(AppEvents.Name(rawValue: "GC Search - Profile Accessed"))
        
        let current = returnedUsers[indexPath.item]
        if(current is User){
            let uid = (current as! User).uId
            
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
    }
    
    private func searchUsers(userName: String?){
        if(self.searchPS){
            AppEvents.logEvent(AppEvents.Name(rawValue: "GC Search - Console: PS, Game: " + self.game!.gameName))
        }
        if(self.searchXbox){
            AppEvents.logEvent(AppEvents.Name(rawValue: "GC Search - Console: XBox, Game: " + self.game!.gameName))
        }
        if(self.searchPC){
            AppEvents.logEvent(AppEvents.Name(rawValue: "GC Search - Console: PC, Game: " + self.game!.gameName))
        }
        if(self.searchNintendo){
            AppEvents.logEvent(AppEvents.Name(rawValue: "GC Search - Console: Nintendo, Game: " + self.game!.gameName))
        }
        
        if(userName != nil){
            AppEvents.logEvent(AppEvents.Name(rawValue: "GC Search - User"))
        }
        
        if(self.loadingView.alpha == 0){
            self.searchAnimation.play()
            
            UIView.animate(withDuration: 0.8, delay: 0.2, options: [], animations: {
                self.loadingView.alpha = 1
            }, completion: { (finished: Bool) in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    self.searchUsers(userName: userName)
                }
            })
            return
        }
        
        self.returnedUsers = [Any]()
        let ref = Database.database().reference().child("Users")
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            // Get user value
            for user in snapshot.children{
                let value = (user as! DataSnapshot).value as? NSDictionary
                
                
                let search = value?["search"] as? String ?? "true"
                let gamerTag = value?["gamerTag"] as? String ?? ""
                
                //make users that did not enter a gamertag are not searchable
                if(search == "true" && !(gamerTag.isEmpty && gamerTag == "undefined")){
                    let games = value?["games"] as? [String] ?? [String]()
                    
                    if(games.contains(self.game!.gameName) && userName == nil){
                        let uId = (user as! DataSnapshot).key
                        let bio = value?["bio"] as? String ?? ""
                        let sentRequests = value?["sentRequests"] as? [FriendRequestObject] ?? [FriendRequestObject]()
                        
                        var friends = [FriendObject]()
                        let friendsArray = snapshot.childSnapshot(forPath: "friends")
                        for friend in friendsArray.children{
                            let currentObj = friend as! DataSnapshot
                            let dict = currentObj.value as? [String: Any]
                            let gamerTag = dict?["gamerTag"] as? String ?? ""
                            let date = dict?["date"] as? String ?? ""
                            let uid = dict?["uid"] as? String ?? ""
                            
                            let newFriend = FriendObject(gamerTag: gamerTag, date: date, uid: uid)
                            friends.append(newFriend)
                        }
                        
                        let games = value?["games"] as? [String] ?? [String]()
                        var gamerTags = [GamerProfile]()
                        let gamerTagsArray = (user as! DataSnapshot).childSnapshot(forPath: "gamerTags")
                        for gamerTagObj in gamerTagsArray.children {
                            let currentObj = gamerTagObj as! DataSnapshot
                            let dict = currentObj.value as? [String: Any]
                            let currentTag = dict?["gamerTag"] as? String ?? ""
                            let currentGame = dict?["game"] as? String ?? ""
                            let console = dict?["console"] as? String ?? ""
                            let quizTaken = dict?["quizTaken"] as? String ?? ""                            
                            
                            let currentGamerTagObj = GamerProfile(gamerTag: currentTag, game: currentGame, console: console, quizTaken: quizTaken)
                            gamerTags.append(currentGamerTagObj)
                        }
                        
                        let consoleArray = (user as! DataSnapshot).childSnapshot(forPath: "consoles")
                        let dict = consoleArray.value as? [String: Bool]
                        let nintendo = dict?["nintendo"] ?? false
                        let ps = dict?["ps"] ?? false
                        let xbox = dict?["xbox"] ?? false
                        let pc = dict?["pc"] ?? false
                        
                        let returnedUser = User(uId: uId)
                        returnedUser.gamerTags = gamerTags
                        returnedUser.games = games
                        returnedUser.friends = friends
                        returnedUser.sentRequests = sentRequests
                        returnedUser.gamerTag = gamerTag
                        returnedUser.pc = pc
                        returnedUser.ps = ps
                        returnedUser.xbox = xbox
                        returnedUser.nintendo = nintendo
                        returnedUser.bio = bio
                        
                        //if the returned user plays the game being searched AND the returned users gamertag
                        //does not equal the current users gamertag, then add to list.
                        let manager = FriendsManager()
                        if(returnedUser.games.contains(self.game!.gameName) && self.currentUser.uId != returnedUser.uId &&
                            !manager.isInFriendList(user: returnedUser, currentUser: self.currentUser)){
                            if(self.searchPS && returnedUser.ps){
                                self.addUserToList(returnedUser: returnedUser)
                            }
                            else if(self.searchPC && returnedUser.pc){
                                self.addUserToList(returnedUser: returnedUser)
                            }
                            else if(self.searchXbox && returnedUser.xbox){
                                self.addUserToList(returnedUser: returnedUser)
                            }
                            else if(self.searchNintendo && returnedUser.nintendo){
                                self.addUserToList(returnedUser: returnedUser)
                            }
                            else{
                                for profile in returnedUser.gamerTags{
                                    if(profile.game == self.game?.gameName){
                                        self.addUserToList(returnedUser: returnedUser)
                                    }
                                }
                            }
                        }
                    }
                    else if(userName != nil){
                        let trimmedUser = userName!.trimmingCharacters(in: .whitespacesAndNewlines)
                        var gamerTag = (value?["gamerTag"] as? String) ?? ""
                        if(!gamerTag.isEmpty){
                            gamerTag = gamerTag.trimmingCharacters(in: .whitespacesAndNewlines)
                        }
                        
                        var gamerTags = [GamerProfile]()
                        let gamerTagsArray = (user as! DataSnapshot).childSnapshot(forPath: "gamerTags")
                        for gamerTagObj in gamerTagsArray.children {
                            let currentObj = gamerTagObj as! DataSnapshot
                            let dict = currentObj.value as? [String: Any]
                            let currentTag = dict?["gamerTag"] as? String ?? ""
                            let currentGame = dict?["game"] as? String ?? ""
                            let console = dict?["console"] as? String ?? ""
                            let quizTaken = dict?["quizTaken"] as? String ?? ""
                            
                            let currentGamerTagObj = GamerProfile(gamerTag: currentTag, game: currentGame, console: console, quizTaken: quizTaken)
                            gamerTags.append(currentGamerTagObj)
                        }
                        
                        var contained = false
                        //check legacy users first
                        if(gamerTag == trimmedUser){
                            contained = true
                        }
                        
                        //if not legacy, or not found, check gamertags one more time
                        if(!contained){
                            for gamerTagObj in gamerTags{
                                if(gamerTagObj.gamerTag == trimmedUser){
                                    contained = true
                                    break
                                }
                            }
                        }
                        
                        if(contained){
                        let gamerProfileManager = GamerProfileManager()
                        
                        if(userName != nil){
                            if(!gamerTag.isEmpty && gamerTag == trimmedUser && (gamerProfileManager.getGamerTag(user: self.currentUser!) == userName)){
                                
                                let uId = (user as! DataSnapshot).key
                                let bio = value?["bio"] as? String ?? ""
                                let sentRequests = value?["sentRequests"] as? [FriendRequestObject] ?? [FriendRequestObject]()
                                
                                var friends = [FriendObject]()
                                let friendsArray = snapshot.childSnapshot(forPath: "friends")
                                for friend in friendsArray.children{
                                    let currentObj = friend as! DataSnapshot
                                    let dict = currentObj.value as? [String: Any]
                                    let gamerTag = dict?["gamerTag"] as? String ?? ""
                                    let date = dict?["date"] as? String ?? ""
                                    let uid = dict?["uid"] as? String ?? ""
                                    
                                    let newFriend = FriendObject(gamerTag: gamerTag, date: date, uid: uid)
                                    friends.append(newFriend)
                                }
                                
                                let games = value?["games"] as? [String] ?? [String]()
                                var gamerTags = [GamerProfile]()
                                let gamerTagsArray = (user as! DataSnapshot).childSnapshot(forPath: "gamerTags")
                                for gamerTagObj in gamerTagsArray.children {
                                    let currentObj = gamerTagObj as! DataSnapshot
                                    let dict = currentObj.value as? [String: Any]
                                    let currentTag = dict?["gamerTag"] as? String ?? ""
                                    let currentGame = dict?["game"] as? String ?? ""
                                    let console = dict?["console"] as? String ?? ""
                                    let quizTaken = dict?["quizTaken"] as? String ?? ""
                                    
                                    let currentGamerTagObj = GamerProfile(gamerTag: currentTag, game: currentGame, console: console, quizTaken: quizTaken)
                                    gamerTags.append(currentGamerTagObj)
                                }
                                
                                let consoleArray = (user as! DataSnapshot).childSnapshot(forPath: "consoles")
                                let dict = consoleArray.value as? [String: Bool]
                                let nintendo = dict?["nintendo"] ?? false
                                let ps = dict?["ps"] ?? false
                                let xbox = dict?["xbox"] ?? false
                                let pc = dict?["pc"] ?? false
                                
                                let returnedUser = User(uId: uId)
                                returnedUser.gamerTags = gamerTags
                                returnedUser.games = games
                                returnedUser.friends = friends
                                returnedUser.sentRequests = sentRequests
                                returnedUser.gamerTag = gamerTag
                                returnedUser.pc = pc
                                returnedUser.ps = ps
                                returnedUser.xbox = xbox
                                returnedUser.nintendo = nintendo
                                returnedUser.bio = bio
                                
                                self.returnedUsers.append(returnedUser)
                            }
                        }
                    }
                }
            }
        }
        
        if(!self.set){
            self.gamerConnectResults.delegate = self
            self.gamerConnectResults.dataSource = self
            
            self.set = true
            
            self.hideLoading()
            UIView.animate(withDuration: 0.8, animations: {
                self.loadingView.alpha = 0
            }, completion: { (finished: Bool) in
                UIView.animate(withDuration: 0.8, delay: 0.5, options: [], animations: {
                    if(!self.returnedUsers.isEmpty){
                        self.searchEmpty.isHidden = true
                    }
                    else{
                        self.searchEmpty.isHidden = false
                        
                        self.searchEmptyText.text = "No users returned for your chosen game."
                        self.searchEmptySub.text = "No worries, try your search again later."
                    }
                }, completion: nil)
            })
        }
        else{
            self.hideLoading()
            UIView.animate(withDuration: 0.8, animations: {
                self.loadingView.alpha = 0
            }, completion: { (finished: Bool) in
                self.gamerConnectResults.reloadData()
                
                if(!self.returnedUsers.isEmpty){
                    self.searchEmpty.isHidden = true
                }
                else{
                    self.searchEmpty.isHidden = false
                    
                    if(userName != nil){
                        self.searchEmptyText.text = "No users returned with that name."
                        self.searchEmptySub.text = "No worries.\nMake sure you typed their naame correctly, and try again."
                    }
                    else{
                        self.searchEmptyText.text = "No users returned for your chosen game."
                        self.searchEmptySub.text = "No worries, try your search again later."
                    }
                }
            })
        }
        
        }) { (error) in
            print(error.localizedDescription)
            AppEvents.logEvent(AppEvents.Name(rawValue: "GamerConnect Search "))
        }
    }
    
    func searchSubmitted(searchString: String) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.searchManager.searchForUser(searchTag: searchString, callbacks: self)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let current = self.returnedUsers[indexPath.item]
        if(current is String){
            return CGSize(width: collectionView.bounds.size.width - 20, height: CGFloat(40))
        } else {
            return CGSize(width: collectionView.bounds.size.width - 20, height: CGFloat(120))
        }
    }
    
    private func addUserToList(returnedUser: User){
        var contained = false
        let manager = GamerProfileManager()
        
        for obj in returnedUsers{
            if(obj is User){
                if((obj as! User).gamerTag == returnedUser.gamerTag){
                    contained = true
                    break
                }
            }
        }
        
        if(!contained){
            self.returnedUsers.append(returnedUser)
        }
    }
    
    func messageTextSubmitted(string: String, list: [String]?) {
    }
    
    func updateCell(indexPath: IndexPath) {
    }
    
    func showQuizClicked(questions: [[String]]) {
    }
    
    func onSuccess(returnedUsers: [User]) {
        if(returnedUsers.isEmpty){
            self.searchEmpty.alpha = 1
            self.searchEmpty.isHidden = false
            self.searchEmptySub.text = "please change a search filter or try again later."
            self.hideLoading()
            return
        }
        if(!set){
            self.searchEmpty.alpha = 0
            self.returnedUsers = returnedUsers
            self.returnedUsers.append("empty")
            self.gamerConnectResults.delegate = self
            self.gamerConnectResults.dataSource = self
            self.gamerConnectResults.reloadData()
            
            UIView.animate(withDuration: 0.5, delay: 0.2, options: [], animations: {
                self.gamerConnectResults.alpha = 1
            }, completion: nil)
        } else {
            self.searchEmpty.alpha = 0
            self.returnedUsers = returnedUsers
            self.returnedUsers.append("empty")
            self.gamerConnectResults.reloadData()
        }
        self.hideLoading()
    }
    
    func onFailure() {
        self.searchEmpty.alpha = 1
        self.searchEmptySub.text = "please change a search filter or try again later."
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.basicFilterList.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if(self.basicFilterList[section].opened == true){
            return self.basicFilterList[section].options.count + 1
        } else {
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if(indexPath.row == 0){
            if(self.basicFilterList[indexPath.section].header == true){
                if(self.basicFilterList[indexPath.section].mainHeader == true){
                    let cell = tableView.dequeueReusableCell(withIdentifier: "searchHeader", for: indexPath) as! SearchHeader
                    
                    let delegate = UIApplication.shared.delegate as! AppDelegate
                    let searchManager = delegate.searchManager
                    if(searchManager.searchLookingFor.isEmpty && (searchManager.locationFilter.isEmpty || searchManager.locationFilter == "none") && searchManager.ageFilters.isEmpty){
                        if(cell.searchButton.title(for: .normal) != "quick search"){
                            UIView.animate(withDuration: 0.5, delay: 0.2, options: [], animations: {
                                cell.searchButton.setTitle("quick search", for: .normal)
                                cell.searchButton.addTarget(self, action: #selector(self.quickSearch), for: UIControl.Event.touchUpInside)
                                cell.searchSub.text = "just show me what you've got"
                            }, completion: nil)
                        } else {
                            cell.searchButton.setTitle("quick search", for: .normal)
                            cell.searchButton.addTarget(self, action: #selector(self.quickSearch), for: UIControl.Event.touchUpInside)
                            cell.searchSub.text = "just show me what you've got"
                        }
                    } else if(searchManager.searchLookingFor.isEmpty && searchManager.ageFilters.isEmpty && (!searchManager.locationFilter.isEmpty && searchManager.locationFilter != "none")){
                        if(cell.searchButton.title(for: .normal) != "location search"){
                            UIView.animate(withDuration: 0.5, delay: 0.2, options: [], animations: {
                                cell.searchButton.setTitle("location search", for: .normal)
                                cell.searchSub.text = "we're getting warmer..."
                                cell.searchButton.addTarget(self, action: #selector(self.quickSearch), for: UIControl.Event.touchUpInside)
                            }, completion: nil)
                        } else {
                            cell.searchButton.setTitle("location search", for: .normal)
                            cell.searchSub.text = "we're getting warmer..."
                            cell.searchButton.addTarget(self, action: #selector(self.quickSearch), for: UIControl.Event.touchUpInside)
                        }
                    } else {
                        if(cell.searchButton.title(for: .normal) != "quick search"){
                            UIView.animate(withDuration: 0.5, delay: 0.2, options: [], animations: {
                                cell.searchButton.setTitle("filter search", for: .normal)
                                cell.searchSub.text = "ok, so you know what you're looking for."
                                cell.searchButton.addTarget(self, action: #selector(self.quickSearch), for: UIControl.Event.touchUpInside)
                            }, completion: nil)
                        } else {
                            cell.searchButton.setTitle("filter search", for: .normal)
                            cell.searchSub.text = "ok, so you know what you're looking for."
                            cell.searchButton.addTarget(self, action: #selector(self.quickSearch), for: UIControl.Event.touchUpInside)
                        }
                    }
                    
                    return cell
                }
                else if(self.basicFilterList[indexPath.section].type == "activate"){
                    let cell = tableView.dequeueReusableCell(withIdentifier: "activate", for: indexPath) as! FilterActivateCell
                    cell.actionButton.setTitle(self.basicFilterList[indexPath.section].title, for: .normal)
                    
                    if(self.basicFilterList[indexPath.section].title == "location"){
                        self.currentLocationActivationCell = cell
                        let delegate = UIApplication.shared.delegate as! AppDelegate
                        if(delegate.currentUser!.userLat != 0.0){
                            cell.switch.isOn = true
                            cell.actionButton.borderColor = #colorLiteral(red: 0.1667544842, green: 0.6060172915, blue: 0.279296875, alpha: 1)
                        } else {
                            cell.switch.isOn = false
                            cell.actionButton.borderColor = UIColor.init(named: "darkToWhite")
                        }
                        cell.actionButton.addTarget(self, action: #selector(locationButtonTriggered), for: UIControl.Event.touchUpInside)
                        cell.switch.addTarget(self, action: #selector(locationSwitchTriggered), for: UIControl.Event.valueChanged)
                    }
                    return cell
                } else if(self.basicFilterList[indexPath.section].type == "lookingFor"){
                    let cell = tableView.dequeueReusableCell(withIdentifier: "lookingFor", for: indexPath) as! SearchLookingForCell
                    cell.setPayload(payload: self.game!.lookingFor, search: self)
                    return cell
                } else {
                    let cell = tableView.dequeueReusableCell(withIdentifier: "category", for: indexPath) as! FilterCategory
                    cell.title.text = self.basicFilterList[indexPath.section].title
                    return cell
                }
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "header", for: indexPath) as! FilterHeader
                cell.headerAction.setTitle(self.basicFilterList[indexPath.section].title, for: .normal)
                
                if(self.basicFilterList[indexPath.section].title == "age range"){
                    cell.headerSwitch.alpha = 1
                    let delegate = UIApplication.shared.delegate as! AppDelegate
                    let searchManager = delegate.searchManager
                    if(searchManager.ageFilters.isEmpty){
                        cell.headerSwitch.isOn = false
                        cell.headerAction.borderColor = #colorLiteral(red: 0.6666666865, green: 0.6666666865, blue: 0.6666666865, alpha: 1)
                    } else {
                        cell.headerSwitch.isOn = true
                        cell.headerAction.borderColor = #colorLiteral(red: 0.1667544842, green: 0.6060172915, blue: 0.279296875, alpha: 1)
                    }
                } else {
                    cell.headerSwitch.alpha = 0
                }
                
                let headerTap = HeaderGesture(target: self, action: #selector(headerTriggered))
                headerTap.question = self.basicFilterList[indexPath.section].title
                headerTap.payload = self.basicFilterList[indexPath.section].choices
                cell.headerAction.addGestureRecognizer(headerTap)
                
                cell.headerSwitch.isUserInteractionEnabled = false
                return cell
            }
        } else {
            if(self.basicFilterList[indexPath.section].header == true){
                if(self.basicFilterList[indexPath.section].title == "location"){
                    let cell = tableView.dequeueReusableCell(withIdentifier: "distance", for: indexPath) as! DistanceCell
                    
                    let fiftyTap = DistanceGesture(target: self, action: #selector(distanceChosen))
                    fiftyTap.tag = "fifty_miles"
                    fiftyTap.section = indexPath.section
                    cell.fifty.isUserInteractionEnabled = true
                    cell.fifty.addGestureRecognizer(fiftyTap)
                    
                    if(self.currentManager.locationFilter == "fifty_miles"){
                        cell.fiftyCover.alpha = 1
                    } else {
                        cell.fiftyCover.alpha = 0
                    }
                    
                    let hundredTap = DistanceGesture(target: self, action: #selector(distanceChosen))
                    hundredTap.tag = "hundred_miles"
                    hundredTap.section = indexPath.section
                    cell.hundred.isUserInteractionEnabled = true
                    cell.hundred.addGestureRecognizer(hundredTap)
                    
                    if(self.currentManager.locationFilter == "hundred_miles"){
                        cell.hundredCover.alpha = 1
                    } else {
                        cell.hundredCover.alpha = 0
                    }
                    
                    let timezoneTap = DistanceGesture(target: self, action: #selector(distanceChosen))
                    timezoneTap.tag = "timezone"
                    timezoneTap.section = indexPath.section
                    cell.timezoneButton.isUserInteractionEnabled = true
                    cell.timezoneButton.addGestureRecognizer(timezoneTap)
                    
                    if(self.currentManager.locationFilter == "timezone"){
                        cell.timezoneCover.alpha = 1
                    } else {
                        cell.timezoneCover.alpha = 0
                    }
                    
                    let noneTap = DistanceGesture(target: self, action: #selector(distanceChosen))
                    noneTap.tag = "none"
                    noneTap.section = indexPath.section
                    cell.globalButton.isUserInteractionEnabled = true
                    cell.globalButton.addGestureRecognizer(noneTap)
                    
                    if(self.currentManager.locationFilter == "none"){
                        cell.globalCover.alpha = 1
                    } else {
                        cell.globalCover.alpha = 0
                    }
                    
                    let delegate = UIApplication.shared.delegate as! AppDelegate
                    if(delegate.currentUser!.userLat != 0.0){
                        cell.cover.alpha = 0
                        cell.howFar.alpha = 1
                    } else {
                        cell.cover.alpha = 1
                        cell.howFar.alpha = 0
                        
                        if self.traitCollection.userInterfaceStyle == .dark {
                            cell.lottie.animation = Animation.named("search_location_light")
                            cell.lottie.contentMode = .scaleAspectFit
                            cell.lottie.loopMode = .playOnce
                            cell.lottie.play()
                        } else {
                            cell.lottie.animation = Animation.named("search_location_dark")
                            cell.lottie.contentMode = .scaleAspectFit
                            cell.lottie.loopMode = .playOnce
                            cell.lottie.play()
                        }
                    }
                    
                    return cell
                } else {
                    let cell = tableView.dequeueReusableCell(withIdentifier: "empty", for: indexPath) as! EmptyCell
                    return cell
                }
            }
            else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "option", for: indexPath) as! FilterOption
                let current = self.basicFilterList[indexPath.section].options[indexPath.row - 1] as? [String: String]
                let key = Array(current!.keys)[0]
                
                let currentFilter = self.basicFilterList[indexPath.section]
                if(currentFilter.type != "advanced"){
                    cell.option.text = key
                    cell.coverLabel.text = key
                    
                    if(self.currentManager.ageFilters.contains(current![key] ?? "") || self.currentManager.langaugeFilters.contains(current![key] ?? "")){
                        cell.cover.alpha = 1
                    } else {
                        cell.cover.alpha = 0
                    }
                } else {
                    cell.option.text = current![key]
                    cell.coverLabel.text = current![key]
                    
                    var contained = false
                    for option in self.currentManager.advancedFilters {
                        let thisKey = Array(option.keys)[0]
                        let thisValue = option[thisKey]
                        if(key == thisKey && thisValue == current![key]){
                            contained = true
                            break
                        }
                    }
                    if(contained){
                        cell.cover.alpha = 1
                    } else {
                        cell.cover.alpha = 0
                    }
                }
                return cell
            }
        }
    }
    
    @objc private func locationButtonTriggered(){
        let delegate = UIApplication.shared.delegate as! AppDelegate
        if(delegate.currentUser!.userLat != 0.0){
            self.currentLocationActivationCell?.switch.setOn(false, animated: true)
            delegate.currentUser!.userLat = 0.0
            delegate.currentUser!.userLong = 0.0
            self.sendLocationInfo()
            self.searchTable.reloadData()
        } else {
            self.currentLocationActivationCell?.switch.setOn(true, animated: true)
            locationManager = CLLocationManager()
            locationManager?.delegate = self
            if #available(iOS 14.0, *) {
                locationManager?.desiredAccuracy = kCLLocationAccuracyReduced
            } else {
                locationManager?.desiredAccuracy = 5000
            }
            locationManager?.requestWhenInUseAuthorization()
        }
    }
    
    @objc private func distanceChosen(sender: DistanceGesture){
        self.currentManager.locationFilter = sender.tag
        self.searchTable.reloadData()
    }
    
    @objc private func quickSearch(){
        UIView.animate(withDuration: 0.5, animations: {
            self.searchTable.alpha = 0
        }, completion: { (finished: Bool) in
            let delegate = UIApplication.shared.delegate as! AppDelegate
            delegate.searchManager.searchWithFilters(callbacks: self)
        })
    }
    
    @objc private func filterSearch(){
        UIView.animate(withDuration: 0.5, animations: {
            self.searchTable.alpha = 0
        }, completion: { (finished: Bool) in
            let delegate = UIApplication.shared.delegate as! AppDelegate
            if(delegate.currentUser!.userLat != 0.0){
                delegate.searchManager.searchWithLocation(callbacks: self)
            } else {
                delegate.searchManager.searchWithFilters(callbacks: self)
            }
        })
    }
    
    @objc private func headerTriggered(sender: HeaderGesture) {
        let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "filterOptionDrawer") as! FilterOptionDrawer
        currentViewController.questionText = sender.question
        currentViewController.payload = sender.payload
        let transitionDelegate = SPStorkTransitioningDelegate()
        currentViewController.transitioningDelegate = transitionDelegate
        currentViewController.modalPresentationStyle = .custom
        currentViewController.modalPresentationCapturesStatusBarAppearance = true
        transitionDelegate.showIndicator = true
        transitionDelegate.swipeToDismissEnabled = true
        transitionDelegate.customHeight = 500
        transitionDelegate.hapticMoments = [.willPresent, .willDismiss]
        transitionDelegate.storkDelegate = self
        self.present(currentViewController, animated: true, completion: nil)
    }
    
    @objc private func locationSwitchTriggered(sender: UISwitch) {
        let delegate = UIApplication.shared.delegate as! AppDelegate
        if(delegate.currentUser!.userLat != 0.0){
            delegate.currentUser!.userLat = 0.0
            delegate.currentUser!.userLong = 0.0
            self.sendLocationInfo()
            self.searchTable.reloadData()
        } else {
            locationManager = CLLocationManager()
            locationManager?.delegate = self
            if #available(iOS 14.0, *) {
                locationManager?.desiredAccuracy = kCLLocationAccuracyReduced
            } else {
                locationManager?.desiredAccuracy = 5000
            }
            locationManager?.requestWhenInUseAuthorization()
        }
    }
    
    private func updateLocation(){
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        if #available(iOS 14.0, *) {
            locationManager?.desiredAccuracy = kCLLocationAccuracyReduced
        } else {
            locationManager?.desiredAccuracy = 5000
        }
        locationManager?.requestWhenInUseAuthorization()
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
            //manager.startUpdatingLocation()
            self.req = LocationManager.shared.locateFromGPS(.continous, accuracy: .city) { result in
              switch result {
                case .failure(let error):
                  debugPrint("Received error: \(error)")
                    self.popup?.dismiss()
                    self.searchTable.reloadData()
                case .success(let location):
                    let delegate = UIApplication.shared.delegate as! AppDelegate
                    delegate.currentUser!.userLat = location.coordinate.latitude
                    delegate.currentUser!.userLong = location.coordinate.longitude
                    
                    var localTimeZoneAbbreviation: String { return TimeZone.current.abbreviation() ?? "" }
                    delegate.currentUser!.timezone = localTimeZoneAbbreviation
                    
                    self.sendLocationInfo()
                    self.popup?.dismiss()
                    
                    if(self.locationCell != nil){
                        self.locationCell?.opened = true
                        self.searchTable.reloadData()
                    } else {
                        self.buildFilterList()
                    }
                    //self.searchTable.reloadData()
              }
            }
            self.req?.start()
        } else if(status == .denied){
            showLocationDialog()
        } else if(status == .notDetermined){
            //if(self.currentSelectedSender != nil){
                //locationSwitchTriggered(sender: 0)
            //}
        }
    }
    
    private func sendLocationInfo(){
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let ref = Database.database().reference().child("Users").child(delegate.currentUser!.uId)
        ref.child("userLat").setValue(delegate.currentUser!.userLat)
        ref.child("userLong").setValue(delegate.currentUser!.userLong)
        ref.child("timezone").setValue(delegate.currentUser!.timezone)
        
        if(delegate.currentUser!.userLat != 0.0){
            let geofireRef = Database.database().reference().child("geofire")
            let geoFire = GeoFire(firebaseRef: geofireRef)
            geoFire.setLocation(CLLocation(latitude: delegate.currentUser!.userLat, longitude: delegate.currentUser!.userLong), forKey: delegate.currentUser!.uId)
            self.req?.stop()
        }
    }
    
    private func showLocationDialog(){
        let title = "DoubleXP needs your permission."
        let message = "we only use your location to find users near you."

        popup = PopupDialog(title: title, message: message)
        let buttonOne = CancelButton(title: "cancel.") {
            print("dang it.")
            self.searchTable.reloadData()
        }

        // This button will not the dismiss the dialog
        let buttonTwo = DefaultButton(title: "go to settings.", dismissOnTap: false) {
            guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                        return
            }
            if UIApplication.shared.canOpenURL(settingsUrl) {
                UIApplication.shared.open(settingsUrl, completionHandler: { (success) in })
            }
        }
        popup!.addButtons([buttonOne, buttonTwo])//, buttonTwo, buttonThree])
        self.present(popup!, animated: true, completion: nil)
    }
    
    private func buildFilterList(){
        self.basicFilterList = [filterCell]()
        
        var mainHeader = filterCell()
        mainHeader.header = true
        mainHeader.mainHeader = true
        mainHeader.opened = false
        mainHeader.options = [["": ""]]
        self.basicFilterList.append(mainHeader)
        
        var advancedHeader = filterCell()
        advancedHeader.header = true
        advancedHeader.title = "apply filters"
        advancedHeader.opened = false
        advancedHeader.options = [["": ""]]
        self.basicFilterList.append(advancedHeader)
        
        locationCell = filterCell()
        locationCell?.header = true
        locationCell?.title = "location"
        locationCell?.type = "activate"
        locationCell?.opened = true
        locationCell?.options = [["": ""]]
        self.basicFilterList.append(locationCell!)
        
        /*var empty = filterCell()
        empty.header = true
        empty.title = ""
        empty.options = [["": ""]]
        self.basicFilterList.append(empty)*/
        /*let english = ["english": "english"]
        let spanish = ["spanish": "spanish"]
        let french = ["french": "french"]
        let chinese = ["chinese": "chinese"]
        let languageChoices = [english, spanish, french, chinese]
        opened = !self.currentManager.langaugeFilters.isEmpty
        let language = filterCell(opened: opened, title: "language", options: languageChoices, type: "language")
        self.basicFilterList.append(language)*/
        
        if(!self.game!.filterQuestions.isEmpty){
            let baby = ["12 - 16": "12_16"]
            let young = ["17 - 24": "17_24"]
            let mid = ["25 - 31": "25_31"]
            let grown = ["32 +": "32_over"]
            let ageChoices = [baby, young, mid, grown]
            var opened = !self.currentManager.ageFilters.isEmpty
            var age = filterCell(opened: opened, title: "age range", options: ageChoices, type: "age")
            age.choices = [String]()
            age.choices.append("12 - 16")
            age.choices.append("17 - 24")
            age.choices.append("25 - 31")
            age.choices.append("32 +")
            self.basicFilterList.append(age)
            
            var lookingHeader = filterCell()
            lookingHeader.header = true
            lookingHeader.type = "lookingFor"
            lookingHeader.opened = false
            lookingHeader.options = [["": ""]]
            self.basicFilterList.append(lookingHeader)
            /*/for question in self.game!.filterQuestions {
                let key = Array(question.keys)[0]
                var options = [[String: String]]()
                let answers = question[key] as? [[String: String]]
                for answer in answers! {
                    let answerKey = Array(answer.keys)[0]
                    let option = [key: answer[answerKey]!]
                    options.append(option)
                }
                let filter = filterCell(opened: false, title: key, options: options, type: "advanced")
                self.basicFilterList.append(filter)
            }*/
        }
        
        self.searchTable.dataSource = self
        self.searchTable.delegate = self
        self.searchTable.reloadData()
    }
    
    func addRemoveChoice(selected: String){
        let delegate = UIApplication.shared.delegate as! AppDelegate
        if(delegate.searchManager.searchLookingFor.contains(selected)){
            delegate.searchManager.searchLookingFor.remove(at: delegate.searchManager.searchLookingFor.index(of: selected)!)
            self.searchTable.reloadData()
        } else {
            delegate.searchManager.searchLookingFor.append(selected)
            self.searchTable.reloadData()
        }
    }
    
    /*func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if(indexPath.row == 0){
            let type = self.basicFilterList[indexPath.section].type
            if(self.basicFilterList[indexPath.section].header != true){
                if(self.basicFilterList[indexPath.section].opened == true){
                    self.basicFilterList[indexPath.section].opened = false
                    let sections = IndexSet.init(integer: indexPath.section)
                    tableView.reloadSections(sections, with: .none)
                } else {
                    self.basicFilterList[indexPath.section].opened = true
                    let sections = IndexSet.init(integer: indexPath.section)
                    tableView.reloadSections(sections, with: .none)
                }
            }
        } else {
            let currentFilter = self.basicFilterList[indexPath.section]
            if(currentFilter.type != "advanced"){
                let current = self.basicFilterList[indexPath.section].options[indexPath.row - 1] as? [String: String]
                let key = Array(current!.keys)[0]
                if(currentFilter.type == "age"){
                    let value = current![key]!
                    if(self.currentManager.ageFilters.contains(value)){
                        self.currentManager.ageFilters.remove(at: self.currentManager.ageFilters.index(of: value)!)
                    } else {
                        self.currentManager.ageFilters.append(value)
                    }
                } else {
                    let value = current![key] ?? ""
                    if(self.currentManager.langaugeFilters.contains(value)){
                        self.currentManager.langaugeFilters.remove(at: self.currentManager.langaugeFilters.index(of:value)!)
                    } else {
                        if(!value.isEmpty){
                            self.currentManager.langaugeFilters.append(value)
                        }
                    }
                }
                //checkClearButton()
                self.searchTable.reloadData()
            } else {
                let current = self.basicFilterList[indexPath.section].options[indexPath.row - 1] as? [String: String]
                let selectedKey = Array(current!.keys)[0]
                var contained = false
                
                for array in self.currentManager.advancedFilters {
                    let arrayKey = Array(array.keys)[0]
                    let value = array[arrayKey]
                    if(arrayKey == selectedKey && value == current![selectedKey]){
                        self.currentManager.advancedFilters.remove(at: self.currentManager.advancedFilters.index(of: array)!)
                        contained = true
                        break
                    }
                }
                
                if(!contained){
                    self.currentManager.advancedFilters.append(current!)
                }
                
                //checkClearButton()
                self.searchTable.reloadData()
            }
        }
    }*/
}

extension Int {
    func dateFromMilliseconds() -> Date {
        return Date(timeIntervalSince1970: TimeInterval(self)/1000)
    }
}

