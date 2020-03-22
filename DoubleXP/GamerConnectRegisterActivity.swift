//
//  GamerConnectRegisterActivity.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 10/13/19.
//  Copyright © 2019 Peterson, Toussaint. All rights reserved.
//

import UIKit
import Firebase
import SwiftHTTP
import ImageLoader
import moa
import FBSDKCoreKit

class GamerConnectRegisterActivity: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    var availableGames = [GamerConnectGame]()
    var selectedGames = [String]()
    var pgNo = 0
    var count = 0
    var x = 0
    var gamerTag = ""
    var tagSaved = false
    var indexPaths = [IndexPath]()
    @IBOutlet weak var gcCollection: UICollectionView!
    @IBOutlet weak var gcRegisterNext: UIImageView!
    @IBOutlet weak var gcRegisterBack: UIImageView!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
       
        let delegate = UIApplication.shared.delegate as! AppDelegate
        availableGames = delegate.gcGames
        
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical //.horizontal
        layout.minimumLineSpacing = 5
        layout.minimumInteritemSpacing = 5
        gcCollection.setCollectionViewLayout(layout, animated: true)
        
        
        //gcCollection.isPagingEnabled = true
        gcCollection.dataSource = self
        gcCollection.delegate = self
        //if let layout = gcCollection.collectionViewLayout as? UICollectionViewFlowLayout {
        //    layout.scrollDirection = .horizontal
        //}
        
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(nextButtonClicked))
        singleTap.numberOfTapsRequired = 1
        gcRegisterNext.isUserInteractionEnabled = true
        gcRegisterNext.addGestureRecognizer(singleTap)
        
        let singleTapBack = UITapGestureRecognizer(target: self, action: #selector(backButtonClicked))
        singleTapBack.numberOfTapsRequired = 1
        gcRegisterBack.isUserInteractionEnabled = true
        gcRegisterBack.addGestureRecognizer(singleTapBack)
        gcRegisterBack.transform = CGAffineTransform(scaleX: -1, y: 1)
        
        AppEvents.logEvent(AppEvents.Name(rawValue: "GC Register"))
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if(pgNo > 0){
            return selectedGames.count
        }
        else{
            return availableGames.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        //cell.backgroundImage.load.request(with: availableGames[indexPath.item]._imageUrl!)
        if(pgNo > 0){
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "gameInfoCell", for: indexPath) as! GCInfoCell
            
            cell.gameName.text = selectedGames[indexPath.item]
            
            for game in availableGames {
                if(game.gameName == selectedGames[indexPath.item]){
                    if(!game.statsAvailable){
                        cell.importLayout.isHidden = true
                    }
                }
            }
            
            let delegate = UIApplication.shared.delegate as! AppDelegate!
            let user = delegate!.currentUser
            if(user != nil){
                //add code to say if only one check is available, check it for them.
                if(!user!.ps){
                    cell.psSwitch.isHidden = true
                }
                
                if(!user!.xbox){
                    cell.xboxSwitch.isHidden = true
                }
                
                if(!user!.nintendo){
                    cell.nintendoSwitch.isHidden = true
                }
                
                if(!user!.pc){
                    cell.pcSwitch.isHidden = true
                }
            }
            
            if(indexPath.item == 0){
                cell.gamerTagAll.isHidden = false
                cell.gamerTagAll.addTarget(self, action:
                    #selector(self.switchValueDidChange), for: .valueChanged)
            }
            else{
                cell.gamerTagAll.isHidden = true
                cell.gamerTagAllTag.isHidden = true
            }
            
            if(tagSaved && indexPath.item > 0){
                cell.gamerTagCover.isHidden = false
            }
            else{
                cell.gamerTagCover.isHidden = true
                
                if(indexPath.item > 0 && !self.indexPaths.contains(indexPath)){
                    self.indexPaths.append(indexPath)
                }
            }
            
            cell.isHidden = false
            return cell
        }
        else{
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "gcCell", for: indexPath) as! GCGameCellTall
            
            cell.gameName.text = availableGames[indexPath.item].gameName
            cell.gameDev.text = availableGames[indexPath.item].developer
            cell.backgroundImage.moa.url = availableGames[indexPath.item].imageUrl
            cell.backgroundImage.contentMode = .scaleAspectFill
            cell.backgroundImage.clipsToBounds = true
            
            if(selectedGames.contains(availableGames[indexPath.item].gameName)){
                cell.cover.isHidden = false
            }
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        if(pgNo == 0){
            let cell = collectionView.cellForItem(at: indexPath as IndexPath) as! GCGameCellTall
            
            let game = availableGames[indexPath.item]
            if(!selectedGames.contains(game.gameName)){
                selectedGames.append(game.gameName)
                
                UIView.animate(withDuration: 0.7, animations: {
                    cell.cover.backgroundColor = #colorLiteral(red: 0.2202792764, green: 0.2189762592, blue: 0.2212850749, alpha: 0.598833476)
                } )
            }
            else{
                if let index = selectedGames.firstIndex(of: game.gameName) {
                    selectedGames.remove(at: index)
                    
                    UIView.animate(withDuration: 0.7, animations: {
                        cell.cover.backgroundColor = #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 0.5997699058)
                    } )
                }
            }
        }
    }
    
    /*func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let flowayout = collectionViewLayout as? UICollectionViewFlowLayout
        let space: CGFloat = (flowayout?.minimumInteritemSpacing ?? 0.0) + (flowayout?.sectionInset.left ?? 0.0) + (flowayout?.sectionInset.right ?? 0.0)
        let size:CGFloat = (gcCollection.frame.size.width - space) / 2.0
        return CGSize(width: size, height: size)
    }*/

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 0, bottom: 0.0, right: 0.0)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
       return 0.0
    }
    
    /*func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let screenSize: CGRect = UIScreen.main.bounds
        let screenWidth = screenSize.width
        return CGSize(width: (screenWidth/2), height: (screenWidth/2));
    }*/
    
     func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
               return CGSize(width: collectionView.bounds.size.width, height: CGFloat(100))
       }
    
    /*func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        
        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
       /* if(pgNo == 0){
            let totalCellWidth = 80 * collectionView.numberOfItems(inSection: 0)
            let totalSpacingWidth = 10 * (collectionView.numberOfItems(inSection: 0) - 1)
            
            let leftInset = ((collectionView.layer.frame.size.width - CGFloat(totalCellWidth + totalSpacingWidth)) / 4) - 15
            let rightInset = leftInset + 15
            
            return UIEdgeInsets(top: 0, left: leftInset, bottom: 0, right: rightInset)
        }
        else{
            return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        }*/
    }*/
    
    @objc func backButtonClicked(_ sender: AnyObject?) {
        if(pgNo > 0 && self.x > 0){
            scrollToPastCell()
        }
        else if(pgNo == 1){
            pgNo = 0
            gcCollection.isScrollEnabled = true
            gcCollection.reloadData()
        }
        else{
            let message = "Are you sure you want to skip this part of registration?"
            let alertController = UIAlertController(title: "GamerConnect Registration Incomplete", message: message, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "I'm Good", style: .destructive, handler: { action in
                self.performSegue(withIdentifier: "gcSkip", sender: nil)
            }))
            alertController.addAction(UIAlertAction(title: "Continue", style: .default, handler: nil))
            self.display(alertController: alertController)
        }
    }
    
    @objc func nextButtonClicked(_ sender: AnyObject?) {
         if(pgNo == 0 && selectedGames.count > 0){
            pgNo += 1
            gcCollection.isScrollEnabled = false
            gcCollection.reloadData()
            
            let indexPath = IndexPath(item: 0, section: 0)
            gcCollection.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
         }
         else if(pgNo > 0){
            let visibleCells = gcCollection.visibleCells
            let currentCell = visibleCells[0] as! GCInfoCell
            
            if(self.gamerTag == ""){
                self.gamerTag = currentCell.gamertagField.text!
            }
            
            if(currentCell.consoleSwitchIsOn() && (currentCell.gamerTagEntered() || tagSaved)){
                if(!currentCell.importLayout.isHidden && currentCell.importSwitch.isOn){
                    if(!tagSaved){
                        registerGame(importStats: true, gameName: currentCell.gameName.text!,
                                 gamerTag: currentCell.gamertagField.text!, console: currentCell.getChosenConsole())
                    }
                    else{
                        registerGame(importStats: true, gameName: currentCell.gameName.text!,
                                     gamerTag: self.gamerTag, console: currentCell.getChosenConsole())
                    }
                }
                else{
                    if(!tagSaved){
                        registerGame(importStats: false, gameName: currentCell.gameName.text!,
                                     gamerTag: currentCell.gamertagField.text!, console: currentCell.getChosenConsole())
                    }
                    else{
                        registerGame(importStats: false, gameName: currentCell.gameName.text!,
                                     gamerTag: self.gamerTag, console: currentCell.getChosenConsole())
                    }
                }
            }
            else{
                if(!currentCell.consoleSwitchIsOn()){
                    let message = "You must choose which console you play this game on."
                    let alertController = UIAlertController(title: "No Console Chosen", message: message, preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: "Got It.", style: .default, handler: nil))
                    self.display(alertController: alertController)
                }
                else{
                    let message = "You must enter the gamertag you use when playing this game."
                    let alertController = UIAlertController(title: "No GamerTag Entered", message: message, preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: "Got It.", style: .default, handler: nil))
                    self.display(alertController: alertController)
                }
            }
            
         }
         else{
             let message = "Are you sure you want to skip this part of registration?"
             let alertController = UIAlertController(title: "GamerConnect Registration Incomplete", message: message, preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "I'm Good", style: .destructive, handler: { action in
                    self.performSegue(withIdentifier: "gcSkip", sender: nil)
                }))
                alertController.addAction(UIAlertAction(title: "Continue", style: .default, handler: nil))
             self.display(alertController: alertController)
        }
    }
    
    private func display(alertController: UIAlertController){
        self.present(alertController, animated: true, completion: nil)
    }
    
    func scrollToNextCell(){
        if self.x + 1 < selectedGames.count {
            let indexPath = IndexPath(item: self.x + 1, section: 0)
            gcCollection.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
            self.x = self.x + 1
        }
        else if(self.x + 1 >= selectedGames.count){
            zipItUp()
        }
    }
    
    func scrollToPastCell(){
        if self.x - 1 > -1 {
            let indexPath = IndexPath(item: self.x - 1, section: 0)
            gcCollection.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
            self.x = self.x - 1
        }
    }
    
    @objc func switchValueDidChange(sender:UISwitch!, tag: String) {
        if(sender.isOn){
            self.gamerTag = tag
            tagSaved = true
            
            if let collectionView = gcCollection {
                collectionView.reloadItems(at: indexPaths)
            }
        }
        else{
            self.gamerTag = ""
            tagSaved = false
            
            if let collectionView = gcCollection {
                collectionView.reloadItems(at: indexPaths)
            }
        }
    }
    
    private func registerGame(importStats: Bool, gameName: String, gamerTag: String, console: String){
        if(importStats){
            if(gameName == "The Division 2"){
                saveGamerProfile(gamerTag: gamerTag, gameName: gameName, console: console)
                getDivisionStats(gamerTag: gamerTag, console: console)
            }
            else if(gameName == "Rainbow Six Siege"){
                saveGamerProfile(gamerTag: gamerTag, gameName: gameName, console: console)
                getRainbowSixStats(gamerTag: gamerTag, console: console)
            }
            else{
                saveGamerProfile(gamerTag: gamerTag, gameName: gameName, console: console)
                self.scrollToNextCell()
            }
        }
        else{
            saveGamerProfile(gamerTag: gamerTag, gameName: gameName, console: console)
            self.scrollToNextCell()
        }
    }
    
    private func saveGamerProfile(gamerTag: String, gameName: String, console: String){
        let delegate = UIApplication.shared.delegate as! AppDelegate!
        let user = delegate?.currentUser
        
        let gamerProfile = GamerProfile(gamerTag: gamerTag, game: gameName, console: console)
        user?.gamerTags.append(gamerProfile)
        
        let ref = Database.database().reference().child("Users").child((user?.uId)!)
        
        let sendUp = ["gamerTag": gamerTag, "gameName": gameName, "console": console]
        ref.child("gamerTags").childByAutoId().setValue(sendUp)
        
        AppEvents.logEvent(AppEvents.Name(rawValue: "GC Register - Profile Saved - " + gameName))
        
        count += 1
    }
    
    private func getDivisionStats(gamerTag: String, console: String){
        var userConsole = ""
        if(console == "ps"){
            userConsole = "psn"
        }
        if(console == "xbox"){
            userConsole = "xbl"
        }
        if(console == "pc"){
            userConsole = "uplay"
        }
        
        if(gamerTag.isEmpty){
            self.gamerTag = ""
            tagSaved = false
            
            if let collectionView = gcCollection {
                collectionView.reloadItems(at: indexPaths)
            }
            
            let message = "There was an error with your gamertag. Please re-enter it below and try again."
            let alertController = UIAlertController(title: "GamerTag Error", message: message, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "Gotcha.", style: .default, handler: nil))
            self.display(alertController: alertController)
            
            return
        }
        
        if(!userConsole.isEmpty){
            let url = "https://thedivisiontab.com/api/search.php?name="+gamerTag+"&platform="+userConsole
            getDivisionPlayerId(url: url)
        }
    }
    
    private func getRainbowSixStats(gamerTag: String, console: String){
        var userConsole = ""
        if(console == "ps"){
            userConsole = "psn"
        }
        if(console == "xbox"){
            userConsole = "xbl"
        }
        if(console == "pc"){
            userConsole = "uplay"
        }
        
        if(gamerTag.isEmpty){
            self.gamerTag = ""
            tagSaved = false
            
            if let collectionView = gcCollection {
                collectionView.reloadItems(at: indexPaths)
            }
            
            let message = "There was an error with your gamertag. Please re-enter it below and try again."
            let alertController = UIAlertController(title: "GamerTag Error", message: message, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "Gotcha.", style: .default, handler: nil))
            self.display(alertController: alertController)
            
            return
        }
        
        if(!userConsole.isEmpty){
            let url =
                "https://r6tab.com/api/search.php?platform="+userConsole+"&search="+gamerTag
            getSiegePlayerId(url: url)
        }
    }
    
    private func getDivisionPlayerId(url: String){
        HTTP.GET(url) { response in
            if let err = response.error {
                print("error: \(err.localizedDescription)")
                self.scrollToNextCell()
                return //also notify app of failure as needed
            }
            else{
                if let jsonObj = try? JSONSerialization.jsonObject(with: response.data, options: .allowFragments) as? NSDictionary {
                    
                    if let resultArray = jsonObj!.value(forKey: "results") as? NSArray {
                        
                        if let resultObj = resultArray[0] as? NSObject{
                            let statObj = StatObject(gameName: "The Division 2")
                            statObj._killsPVP = "\((resultObj.value(forKey: "kills_pvp") as? Int) ?? 0)"
                            statObj._killsPVE = "\((resultObj.value(forKey: "kills_npc") as? Int) ?? 0)"
                            statObj._playerLevelGame = "\((resultObj.value(forKey: "level_pve") as? Int) ?? 0)"
                            statObj._playerLevelPVP = "\((resultObj.value(forKey: "level_dz") as? Int) ?? 0)"
                            statObj._statUrl = url
                            statObj._setPublic = "true"
                            statObj._authorized = "true"
                            
                            let pid = (resultObj.value(forKey: "pid") as? String)!
                            if(!pid.isEmpty){
                                self.getDivisionExtendedStats(pid: pid, statObj: statObj)
                            }
                            else{
                                let delegate = UIApplication.shared.delegate as! AppDelegate!
                                let user = delegate?.currentUser
                                
                                let ref = Database.database().reference().child("Users").child((user?.uId)!)
                                ref.child("stats").setValue(statObj)
                                
                                user?.stats.append(statObj)
                                self.scrollToNextCell()
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func getSiegePlayerId(url: String){
        HTTP.GET(url) { response in
            if let err = response.error {
                print("error: \(err.localizedDescription)")
                self.scrollToNextCell()
                return //also notify app of failure as needed
            }
            else{
                if let jsonObj = try? JSONSerialization.jsonObject(with: response.data, options: .allowFragments) as? NSDictionary {
                    
                    if let resultArray = jsonObj!.value(forKey: "results") as? NSArray {
                        
                        if let resultObj = resultArray[0] as? NSObject{
                            let statObj = StatObject(gameName: "Rainbow Six Siege")
                            statObj._currentRank = "\((resultObj.value(forKey: "p_currentrank") as? Int) ?? 0)"
                            statObj._playerLevelPVP = "\((resultObj.value(forKey: "p_level") as? Int) ?? 0)"
                            statObj._statUrl = url
                            statObj._setPublic = "true"
                            statObj._authorized = "true"
                            
                            let pid = (resultObj.value(forKey: "p_id") as? String)!
                            if(!pid.isEmpty){
                                self.getSiegeExtendedStats(pid: pid, statObj: statObj)
                            }
                            else{
                                let delegate = UIApplication.shared.delegate as! AppDelegate!
                                let user = delegate?.currentUser
                                
                                let ref = Database.database().reference().child("Users").child((user?.uId)!)
                                ref.child("stats").setValue(statObj)
                                
                                user?.stats.append(statObj)
                                self.scrollToNextCell()
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func getDivisionExtendedStats(pid: String, statObj: StatObject){
        let url = "https://thedivisiontab.com/api/player.php?pid="+pid
        
        HTTP.GET(url) { response in
            if let err = response.error {
                print("error: \(err.localizedDescription)")
                AppEvents.logEvent(AppEvents.Name(rawValue: "GC Register - Division Extended Stats Failed"))

                self.scrollToNextCell()
                return //also notify app of failure as needed
            }
            else{
                if let jsonObj = try? JSONSerialization.jsonObject(with: response.data, options: .allowFragments) as? NSDictionary {
                    
                    let playerFound = jsonObj!.value(forKey: "playerfound") as? Bool ?? false
                    if(!playerFound){
                        self.saveAndProceed(statObj: statObj)
                    }
                    else{
                        statObj._authorized = "true"
                        statObj._setPublic = "true"
                        statObj._killsPVP = "\((jsonObj!.value(forKey: "kills_pvp") as? Int) ?? 0)"
                        statObj._killsPVE = "\((jsonObj!.value(forKey: "kills_npc") as? Int) ?? 0)"
                        statObj._playerLevelGame = "\((jsonObj!.value(forKey: "level_pve") as? Int) ?? 0)"
                        statObj._playerLevelPVP = "\((jsonObj!.value(forKey: "level_dz") as? Int) ?? 0)"
                        statObj._gearScore = "\((jsonObj!.value(forKey: "gearscore") as? Int) ?? 0)"
                        statObj._statUrl = url
                        
                        self.saveAndProceed(statObj: statObj)
                        AppEvents.logEvent(AppEvents.Name(rawValue: "GC Register - Division Extended Stats Received"))
                    }
                }
            }
        }
    }
    
    private func getSiegeExtendedStats(pid: String, statObj: StatObject){
        let url = "https://r6tab.com/api/player.php?p_id="+pid
        
        HTTP.GET(url) { response in
            if let err = response.error {
                print("error: \(err.localizedDescription)")
                AppEvents.logEvent(AppEvents.Name(rawValue: "GC Register - Siege Extended Stats Failed"))

                self.scrollToNextCell()
                return //also notify app of failure as needed
            }
            else{
                if let jsonObj = try? JSONSerialization.jsonObject(with: response.data, options: .allowFragments) as? NSDictionary {
                    
                    let playerFound = jsonObj!.value(forKey: "playerfound") as? Bool ?? false
                    if(!playerFound){
                        self.saveAndProceed(statObj: statObj)
                    }
                    else{
                        statObj._authorized = "true"
                        statObj._setPublic = "true"
                        statObj._currentRank = "\((jsonObj!.value(forKey: "p_currentrank") as? Int) ?? 0)"
                        statObj._killsPVP = "\((jsonObj!.value(forKey: "p_level") as? Int) ?? 0)"
                        statObj._mostUsedAttacker = (jsonObj!.value(forKey: "favattacker") as? String)!
                        statObj._mostUsedDefender = (jsonObj!.value(forKey: "favdefender") as? String)!
                        statObj._statUrl = url
                        
                        self.saveAndProceed(statObj: statObj)
                        AppEvents.logEvent(AppEvents.Name(rawValue: "GC Register - Siege Extended Stats Received"))
                    }
                }
            }
        }
    }
    
    private func saveAndProceed(statObj: StatObject){
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let user = delegate.currentUser
        
        let ref = Database.database().reference().child("Users").child((user?.uId)!)

        let current = ["gameName": statObj.gameName, "killsPVE": statObj.killsPVE, "killsPVP": statObj.killsPVP, "playerLevelGame": statObj.playerLevelGame, "playerLevelPVP": statObj.playerLevelPVP, "statUrl": statObj.statUrl, "setPublic": statObj.setPublic, "authorized": statObj.authorized, "currentRank": statObj.currentRank, "totalRankedWins": statObj.totalRankedWins, "totalRankedLosses": statObj.totalRankedLosses, "totalRankedKills": statObj.totalRankedKills, "totalRankedDeaths": statObj.totalRankedLosses, "mostUsedAttacker": statObj.mostUsedAttacker, "mostUsedDefender": statObj.mostUsedDefender, "gearScore": statObj.gearScore]
        ref.child("stats").child(statObj.gameName).setValue(current)
        
        user?.stats.append(statObj)
        
        self.scrollToNextCell()
    }
    
    private func zipItUp(){
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let user = delegate.currentUser
        
        let ref = Database.database().reference().child("Users").child((user?.uId)!)
        ref.child("games").setValue(selectedGames)
        ref.child("gamerTag").setValue(self.gamerTag)
        
        user?.games = self.selectedGames
        
        self.performSegue(withIdentifier: "gcSkip", sender: nil)
        
        AppEvents.logEvent(AppEvents.Name(rawValue: "GC Register - Successful Registration"))
    }
}
