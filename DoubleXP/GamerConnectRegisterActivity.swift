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
import moa
import FBSDKCoreKit
import UnderLineTextField
import Lottie
import MSPeekCollectionViewDelegateImplementation
import AIFlatSwitch


class GamerConnectRegisterActivity: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UITextFieldDelegate {
    
    var availableGames = [GamerConnectGame]()
    var selectedGames = [GCRegisterTemp]()
    var gamesList = [String]()
    var pgNo = 0
    var count = 0
    var x = 0
    var gamerTag = ""
    var tagSaved = false
    var indexPaths = [IndexPath]()
    @IBOutlet weak var gcRegisterNext: UIImageView!
    @IBOutlet weak var gcRegisterBack: UIImageView!
    @IBOutlet weak var introBlur: UIVisualEffectView!
    @IBOutlet weak var introDialog: UIView!
    @IBOutlet weak var gotItButton: UIButton!
    @IBOutlet weak var gcDrawer: UIView!
    @IBOutlet weak var drawerBlur: UIVisualEffectView!
    @IBOutlet weak var importButtonImage: UIImageView!
    @IBOutlet weak var allConsolesButton: UIButton!
    @IBOutlet weak var allConsolesCover: UIImageView!
    @IBOutlet weak var gcDrawerGamertag: UnderLineTextField!
    @IBOutlet weak var allConsolesLabel: UILabel!
    @IBOutlet weak var psSwitch: UISwitch!
    @IBOutlet weak var xboxSwitch: UISwitch!
    @IBOutlet weak var nintendoSwitch: UISwitch!
    @IBOutlet weak var pcSwitch: UISwitch!
    @IBOutlet weak var gameCollection: UICollectionView!
    @IBOutlet weak var statsLayout: UIView!
    @IBOutlet weak var skipButton: UIButton!
    @IBOutlet weak var continueButton: UIButton!
    @IBOutlet weak var clickArea: UIView!
    @IBOutlet weak var gcDrawerGamenam: UILabel!
    @IBOutlet weak var statsSwitch: AIFlatSwitch!
    @IBOutlet weak var buildingAnimation: AnimationView!
    @IBOutlet weak var buildingHeader: UIView!
    @IBOutlet weak var creationView: UIView!
    @IBOutlet weak var finishButton: UIButton!
    @IBOutlet weak var welcomeText: UILabel!
    @IBOutlet weak var creationThumb: UIImageView!
    
    var importToggled = false
    var allGamesChecked = false
    var savedTag = ""
    var selectedConsole = ""
    var highlightCount = 4
    var switches = [UISwitch]()
    var items = [Int]()
    var currentIndexPath: IndexPath?
    var gamerTagValid = false
    var sendUpArray = [[String: String]]()
    var stats = [[String: String]]()
    
    var behavior: MSCollectionViewPeekingBehavior!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
       
        let delegate = UIApplication.shared.delegate as! AppDelegate
        availableGames = delegate.gcGames
        
        switches.append(psSwitch)
        switches.append(xboxSwitch)
        switches.append(pcSwitch)
        switches.append(nintendoSwitch)
        
        introDialog.layer.shadowColor = UIColor.black.cgColor
        introDialog.layer.shadowOffset = CGSize(width: 0, height: 2.0)
        introDialog.layer.shadowRadius = 3.0
        introDialog.layer.shadowOpacity = 0.5
        introDialog.layer.masksToBounds = false
        introDialog.layer.shadowPath = UIBezierPath(roundedRect: introDialog.bounds, cornerRadius:
            introDialog.layer.cornerRadius).cgPath
        
        let currentUser = delegate.currentUser
        if(!currentUser!.ps){
            psSwitch.alpha = 0.2
            psSwitch.isUserInteractionEnabled = false
            psSwitch.isHighlighted = false
            highlightCount -= 1
        }
        if(!currentUser!.xbox){
            xboxSwitch.alpha = 0.2
            xboxSwitch.isUserInteractionEnabled = false
            xboxSwitch.isHighlighted = false
            highlightCount -= 1
        }
        if(!currentUser!.pc){
            pcSwitch.alpha = 0.2
            pcSwitch.isUserInteractionEnabled = false
            pcSwitch.isHighlighted = false
            highlightCount -= 1
        }
        if(!currentUser!.nintendo){
            nintendoSwitch.alpha = 0.2
            nintendoSwitch.isUserInteractionEnabled = false
            nintendoSwitch.isHighlighted = false
            highlightCount -= 1
        }
        
        if(highlightCount == 1){
            for consoleSwitch in switches{
                if(consoleSwitch.isHighlighted){
                    consoleSwitch.setOn(true, animated: true)
                }
            }
        }

        gcDrawerGamertag.returnKeyType = .done
        gcDrawerGamertag.delegate = self
        
        psSwitch.addTarget(self, action: #selector(psSwitchChanged), for: UIControl.Event.valueChanged)
        xboxSwitch.addTarget(self, action: #selector(xboxSwitchChanged), for: UIControl.Event.valueChanged)
        pcSwitch.addTarget(self, action: #selector(pcSwitchChanged), for: UIControl.Event.valueChanged)
        nintendoSwitch.addTarget(self, action: #selector(nintendoSwitchChanged), for: UIControl.Event.valueChanged)
        
        
        let skip = UITapGestureRecognizer(target: self, action: #selector(skipPressed))
        clickArea.isUserInteractionEnabled = true
        clickArea.addGestureRecognizer(skip)
        
        allConsolesButton.titleLabel?.textAlignment = .center
        allConsolesButton.addTarget(self, action: #selector(allConsolesClicked), for: .touchUpInside)
        
        skipButton.addTarget(self, action: #selector(skipPressed), for: .touchUpInside)
        continueButton.addTarget(self, action: #selector(continuePressed), for: .touchUpInside)
        finishButton.addTarget(self, action: #selector(finishPressed), for: .touchUpInside)
        gotItButton.addTarget(self, action: #selector(gotItPressed), for: .touchUpInside)
        AppEvents.logEvent(AppEvents.Name(rawValue: "GC Register"))

        //put disabling stats and deleting stats in settings
        //gameCollection.configureForPeekingDelegate()
        gameCollection.delegate = self
        gameCollection.dataSource = self
        
        behavior = MSCollectionViewPeekingBehavior()
        gameCollection.configureForPeekingBehavior(behavior: behavior)
    }
    
    private func showCreationView(){
        for game in self.selectedGames{
            self.gamesList.append(game.gameName)
        }
        
        let top = CGAffineTransform(translationX: 0, y: -20)
        UIView.animate(withDuration: 0.4, animations: {
            self.creationView.alpha = 1
        }, completion: { (finished: Bool) in
            UIView.animate(withDuration: 0.5, delay: 0.2, options: [], animations: {
                self.buildingHeader.alpha = 1
                self.buildingHeader.transform = top
                
                self.buildingAnimation.transform = top
                self.buildingAnimation.alpha = 1
                
                self.buildingAnimation.loopMode = .loop
                self.buildingAnimation.play()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.processAndSend()
                }
            }, completion: nil)
        })
    }
    
    @objc func gotItPressed(){
        UIView.animate(withDuration: 0.3, animations: {
            self.introDialog.layer.shadowOpacity = 0
        }, completion: { (finished: Bool) in
            UIView.animate(withDuration: 0.3, delay: 0.3, options: [], animations: {
                self.introDialog.alpha = 0
            }, completion: { (finished: Bool) in
                UIView.animate(withDuration: 0.5, delay: 0.2, options: [], animations: {
                    self.introBlur.alpha = 0
                }, completion: nil)
            })
        })
    }
    
    @objc func finishPressed(){
        showCreationView()
    }
    
    @objc func skipPressed(){
        dismissDrawer(add: false)
    }
    
    @objc func continuePressed(){
        dismissDrawer(add: true)
    }
    
    @objc func psSwitchChanged(stationSwitch: UISwitch) {
        if(stationSwitch.isOn){
            selectedConsole = "ps"
            checkSwitches(selected: "ps")
        }
        else{
            selectedConsole = ""
            checkSwitches(selected: "")
        }
    }
    
    @objc func xboxSwitchChanged(xSwitch: UISwitch) {
        if(xSwitch.isOn){
            selectedConsole = "xbox"
            checkSwitches(selected: "xbox")
        }
        else{
            selectedConsole = ""
            checkSwitches(selected: "")
        }
    }
    
    @objc func nintendoSwitchChanged(switchSwitch: UISwitch) {
        if(switchSwitch.isOn){
            selectedConsole = "nintendo"
            checkSwitches(selected: "nintendo")
        }
        else{
            selectedConsole = ""
            checkSwitches(selected: "")
        }
    }
    @objc func pcSwitchChanged(compSwitch: UISwitch) {
        if(compSwitch.isOn){
            selectedConsole = "pc"
            checkSwitches(selected: "pc")
        }
        else{
            selectedConsole = ""
            checkSwitches(selected: "")
        }
    }
    
    private func checkSwitches(selected: String){
        if(selectedConsole == "ps"){
            psSwitch.isOn = true
            pcSwitch.isOn = false
            xboxSwitch.isOn = false
            nintendoSwitch.isOn = false
        }
        else if(selectedConsole == "xbox"){
            psSwitch.isOn = false
            pcSwitch.isOn = false
            xboxSwitch.isOn = true
            nintendoSwitch.isOn = false
        }
        else if(selectedConsole == "nintendo"){
            psSwitch.isOn = false
            pcSwitch.isOn = false
            xboxSwitch.isOn = false
            nintendoSwitch.isOn = true
        }
        else if(selectedConsole == "pc"){
            psSwitch.isOn = false
            pcSwitch.isOn = true
            xboxSwitch.isOn = false
            nintendoSwitch.isOn = false
        }
        else{
            psSwitch.isOn = false
            pcSwitch.isOn = false
            xboxSwitch.isOn = false
            nintendoSwitch.isOn = false
        }
    }
    
    @objc func allConsolesClicked(){
        if(!(gcDrawerGamertag.text!.isEmpty) && self.savedTag.isEmpty){
            self.allGamesChecked = true
            //save
            self.savedTag = gcDrawerGamertag.text!
            
            let top = CGAffineTransform(translationX: 0, y: 36)
            UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 5, animations: {
                self.allConsolesCover.alpha = 1
                self.allConsolesCover.transform = top
                
                UIView.transition(with: self.allConsolesButton, duration: 0.3, options: .curveEaseInOut, animations: {
                    self.allConsolesButton.backgroundColor = UIColor(named: "redToDark")
                }, completion: { (finished: Bool) in
                    UIView.transition(with: self.allConsolesButton,
                         duration: 0.3,
                         options: .transitionCrossDissolve,
                       animations: { [weak self] in
                        self?.allConsolesButton.titleLabel?.text = "undo"
                    }, completion: nil)
                })
                
                UIView.transition(with: self.allConsolesLabel,
                     duration: 0.3,
                     options: .transitionCrossDissolve,
                   animations: { [weak self] in
                    self?.allConsolesLabel.text = "actually..."
                }, completion: nil)
                
                UIView.animate(withDuration: 0.3, animations: {
                    self.gcDrawerGamertag.alpha = 0.3
                    self.gcDrawerGamertag.isUserInteractionEnabled = false
                }, completion: nil)
            }, completion: nil)
        }
        else if(!self.savedTag.isEmpty){
            self.allGamesChecked = false
            //undo
            self.savedTag = ""
            self.gcDrawerGamertag.text = ""
            
            let top = CGAffineTransform(translationX: 0, y: 0)
            UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 5, animations: {
                self.allConsolesCover.alpha = 0
                self.allConsolesCover.transform = top
                
                UIView.transition(with: self.allConsolesButton, duration: 0.3, options: .curveEaseInOut, animations: {
                    self.allConsolesButton.backgroundColor = UIColor(named: "greenToDarker")
                }, completion: { (finished: Bool) in
                    UIView.transition(with: self.allConsolesButton,
                         duration: 0.3,
                         options: .transitionCrossDissolve,
                       animations: { [weak self] in
                        self?.allConsolesButton.titleLabel?.text = "all games"
                    }, completion: nil)
                })
                
                UIView.transition(with: self.allConsolesLabel,
                     duration: 0.3,
                     options: .transitionCrossDissolve,
                   animations: { [weak self] in
                    self?.allConsolesLabel.text = "use for"
                }, completion: nil)
                
                UIView.animate(withDuration: 0.3, animations: {
                    self.gcDrawerGamertag.alpha = 1
                    self.gcDrawerGamertag.isUserInteractionEnabled = true
                }, completion: nil)
            }, completion: nil)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.availableGames.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! GCElongCell
        let current = self.availableGames[indexPath.item]
        
        cell.backgroundImage.image = Utility.Image.placeholder
        cell.backgroundImage.moa.url = current.imageUrl
        cell.backgroundImage.contentMode = .scaleAspectFill
        cell.backgroundImage.clipsToBounds = true
        
        cell.gameName.text = current.gameName
        cell.developer.text = current.developer
        
        cell.contentView.layer.cornerRadius = 20.0
        cell.contentView.layer.borderWidth = 1.0
        cell.contentView.layer.borderColor = UIColor.clear.cgColor
        cell.contentView.layer.masksToBounds = true
        
        cell.layer.shadowColor = UIColor.black.cgColor
        cell.layer.shadowOffset = CGSize(width: 0, height: 2.0)
        cell.layer.shadowRadius = 2.0
        cell.layer.shadowOpacity = 0.5
        cell.layer.masksToBounds = false
        cell.layer.shadowPath = UIBezierPath(roundedRect: cell.bounds, cornerRadius: cell.contentView.layer.cornerRadius).cgPath
        
        cell.lottie.contentMode = .scaleAspectFit
        
        if(self.items.contains(indexPath.item)){
            let top = CGAffineTransform(translationX: 0, y: -62)
            cell.addedCover.alpha = 1
            cell.lottie.transform = top
            cell.lottie.currentFrame = cell.lottie.animation!.endFrame
        }
        else{
            cell.addedCover.alpha = 0
            cell.lottie.currentFrame = cell.lottie.animation!.startFrame
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if(self.items.contains(indexPath.item)){
            let current = availableGames[indexPath.item]
            self.currentIndexPath = indexPath
            self.items.remove(at: self.items.index(of: indexPath.item)!)
            
            for selectedGame in self.selectedGames{
                if(selectedGame.gameName == current.gameName){
                    self.selectedGames.remove(at: self.selectedGames.index(of: selectedGame)!)
                }
            }
            
            let cell = self.gameCollection!.cellForItem(at: self.currentIndexPath!) as! GCElongCell
            let top = CGAffineTransform(translationX: 0, y: 0)
            
            UIView.transition(with: self.allConsolesButton, duration: 0.3, options: .curveEaseInOut, animations: {
                cell.lottie.transform = top
            }, completion: { (finished: Bool) in
                UIView.animate(withDuration: 0.5, animations: {
                    cell.addedCover.alpha = 0
                }, completion: nil)
            })
        }
        else{
            let current = availableGames[indexPath.item]
            self.currentIndexPath = indexPath
            
            if(!self.savedTag.isEmpty){
                self.gcDrawerGamertag.text = self.savedTag
                
                self.allConsolesButton.backgroundColor = UIColor(named: "redToDark")
                self.allConsolesButton.titleLabel?.text = "undo"
                self.gcDrawerGamertag.alpha = 0.3
                self.gcDrawerGamertag.isUserInteractionEnabled = false
                
                self.allConsolesCover.topAnchor.constraint(equalTo: self.gcDrawerGamertag.topAnchor, constant:40)
                self.allConsolesCover.alpha = 1
            }
            else{
                self.allConsolesButton.backgroundColor = UIColor(named: "greenToDarker")
                self.allConsolesButton.titleLabel?.text = "all games"
                self.allConsolesLabel.text = "use for"
                self.gcDrawerGamertag.alpha = 1
                self.gcDrawerGamertag.text = ""
            }
            
            if(highlightCount > 1){
                for consoleSwitch in switches{
                    consoleSwitch.setOn(false, animated: false)
                }
            }
            
            self.statsSwitch.setSelected(false, animated: false)
            
            self.gcDrawerGamertag.addTarget(self, action: #selector(self.textFieldDidChange(_:)), for: UIControl.Event.editingChanged)
            self.gcDrawerGamenam.text = current.gameName
            self.statsSwitch.setSelected(false, animated: false)
            
            
            if(!current.statsAvailable){
                self.statsLayout.alpha = 0.1
                self.statsLayout.isUserInteractionEnabled = false
            }
            else{
                self.statsLayout.alpha = 1
                self.statsLayout.isUserInteractionEnabled = true
            }
            
            checkNextActivation()
            
            let top = CGAffineTransform(translationX: 0, y: -515)
            UIView.transition(with: self.allConsolesButton, duration: 0.3, options: .curveEaseInOut, animations: {
                self.drawerBlur.alpha = 1
            }, completion: { (finished: Bool) in
                UIView.animate(withDuration: 0.5, animations: {
                    self.gcDrawer.transform = top
                }, completion: nil)
            })
        }
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        if(textField.text != nil){
            if textField.text!.count >= 3 {
                gamerTagValid = true
                checkNextActivation()
            }
            else{
                gamerTagValid = false
                checkNextActivation()
            }
        }
    }
    
    private func checkNextActivation(){
        var consoleChosen = false
        
        for uiSwitch in self.switches{
            if(uiSwitch.isOn){
                consoleChosen = true
                break
            }
        }
        
        if(consoleChosen && self.gamerTagValid){
            self.continueButton.alpha = 1
            self.continueButton.isUserInteractionEnabled = true
        }
        else{
            self.continueButton.alpha = 0.3
            self.continueButton.isUserInteractionEnabled = false
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        return CGSize(width: 250, height: 300)
    }
    
    @objc func backButtonClicked(_ sender: AnyObject?) {
        let message = "Are you sure you want to skip this part of registration?"
        let alertController = UIAlertController(title: "GamerConnect Registration Incomplete", message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "I'm Good", style: .destructive, handler: { action in
            self.performSegue(withIdentifier: "gcSkip", sender: nil)
        }))
        alertController.addAction(UIAlertAction(title: "Continue", style: .default, handler: nil))
        self.display(alertController: alertController)
    }
    
    @objc func nextButtonClicked(_ sender: AnyObject?) {
         
    }
    
    private func display(alertController: UIAlertController){
        self.present(alertController, animated: true, completion: nil)
    }
    
    private func getConsole() -> String{
        var console = ""
        if(self.psSwitch.isOn){
            console = "ps"
        }
        if(self.xboxSwitch.isOn){
            console = "xbox"
        }
        if(self.pcSwitch.isOn){
            console = "pc"
        }
        if(self.nintendoSwitch.isOn){
            console = "nintendo"
        }
        return console
    }
    
    private func dismissDrawer(add: Bool){
        let top = CGAffineTransform(translationX: 0, y: 0)
        UIView.transition(with: self.allConsolesButton, duration: 0.3, options: .curveEaseInOut, animations: {
            self.gcDrawer.transform = top
        }, completion: { (finished: Bool) in
            UIView.animate(withDuration: 0.5, animations: {
                self.drawerBlur.alpha = 0
                
                if(add){
                    let currentGame = self.availableGames[self.currentIndexPath!.item]
                    guard currentGame != nil else {
                        return
                    }
                    self.items.append(self.currentIndexPath!.item)
                    
                    var gamerTag = ""
                    if(!self.savedTag.isEmpty){
                        gamerTag = self.savedTag
                    }
                    else{
                        gamerTag = self.gcDrawerGamertag.text!
                    }
                    
                    if(!gamerTag.isEmpty && !self.getConsole().isEmpty){
                        let currentTemp = GCRegisterTemp(gameName: currentGame.gameName, gamerTag: gamerTag, console: self.getConsole(), importStats: self.statsSwitch.isSelected)
                        
                        self.selectedGames.append(currentTemp)
                        
                        let cell = self.gameCollection!.cellForItem(at: self.currentIndexPath!) as! GCElongCell
                        
                        let top = CGAffineTransform(translationX: 0, y: -61)
                        UIView.transition(with: self.allConsolesButton, duration: 0.3, options: .curveEaseInOut, animations: {
                            cell.addedCover.alpha = 1
                        }, completion: { (finished: Bool) in
                            UIView.animate(withDuration: 0.5, animations: {
                                cell.lottie.transform = top
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    cell.lottie.play()
                                }
                            }, completion: nil)
                        })
                    }
                }
            }, completion: nil)
        })
    }
    
    private func processAndSend(){
        self.selectedGames = self.selectedGames.sorted(by: { !$0.importStats && $1.importStats })
        if(self.selectedGames.isEmpty){
            zipItUp()
        }
        else{
            let current = self.selectedGames[0]
            registerGame(importStats: current.importStats, gameName: current.gameName, gamerTag: current.gamerTag, console: current.console)
        }
    }
    
    private func finishAndMoveToNext(){
        self.selectedGames.remove(at: 0)
        self.processAndSend()
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
            else if(gameName == "Call Of Duty Modern Warfare"){
                saveGamerProfile(gamerTag: gamerTag, gameName: gameName, console: console)
                getCODStats(gamerTag: gamerTag, console: console)
            }
            else{
                saveGamerProfile(gamerTag: gamerTag, gameName: gameName, console: console)
                finishAndMoveToNext()
            }
        }
        else{
            saveGamerProfile(gamerTag: gamerTag, gameName: gameName, console: console)
            finishAndMoveToNext()
        }
    }
    
    private func saveGamerProfile(gamerTag: String, gameName: String, console: String){
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let user = delegate.currentUser
        
        let gamerProfile = GamerProfile(gamerTag: gamerTag, game: gameName, console: console)
        user?.gamerTags.append(gamerProfile)
        
        let sendUp = ["gamerTag": gamerTag, "game": gameName, "console": console]
        if(!self.allGamesChecked && self.savedTag.isEmpty){
            self.savedTag = gamerTag
        }
        
        self.sendUpArray.append(sendUp)
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
                AppEvents.logEvent(AppEvents.Name(rawValue: "GC Register - Division PlayerID Error" + url))
                self.finishAndMoveToNext()
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
                                let delegate = UIApplication.shared.delegate as! AppDelegate
                                let user = delegate.currentUser
                                
                                let ref = Database.database().reference().child("Users").child((user?.uId)!)
                                ref.child("stats").setValue(statObj)
                                
                                user?.stats.append(statObj)
                                self.finishAndMoveToNext()
                            }
                        }
                        else{
                            AppEvents.logEvent(AppEvents.Name(rawValue: "GC Register - Division PlayerID Empty Payload" + url))
                            self.finishAndMoveToNext()
                        }
                    }
                    else{
                        AppEvents.logEvent(AppEvents.Name(rawValue: "GC Register - Division PlayerID No Payload" + url))
                        self.finishAndMoveToNext()
                    }
                }
                else{
                    AppEvents.logEvent(AppEvents.Name(rawValue: "GC Register - Division PlayerID No Response" + url))
                    self.finishAndMoveToNext()
                }
            }
        }
    }
    
    private func getSiegePlayerId(url: String){
        HTTP.GET(url) { response in
            if let err = response.error {
                print("error: \(err.localizedDescription)")
                self.finishAndMoveToNext()
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
                                let delegate = UIApplication.shared.delegate as! AppDelegate
                                let user = delegate.currentUser
                                
                                let ref = Database.database().reference().child("Users").child((user?.uId)!)
                                ref.child("stats").setValue(statObj)
                                
                                user?.stats.append(statObj)
                                self.finishAndMoveToNext()
                            }
                        }
                    }
                    else{
                        AppEvents.logEvent(AppEvents.Name(rawValue: "GC Register - Division PlayerID Empty Payload" + url))
                        self.finishAndMoveToNext()
                    }
                }
                else{
                    AppEvents.logEvent(AppEvents.Name(rawValue: "GC Register - Division PlayerID Failed " + url))
                    self.finishAndMoveToNext()
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

                self.finishAndMoveToNext()
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
                else{
                    AppEvents.logEvent(AppEvents.Name(rawValue: "GC Register - Division Extended Stats No Payload" + url))
                    self.finishAndMoveToNext()
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

                self.finishAndMoveToNext()
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
                else{
                    AppEvents.logEvent(AppEvents.Name(rawValue: "GC Register - Seige Extended Stats No Response" + url))
                    self.finishAndMoveToNext()
                }
            }
        }
    }
    
    private func getCODStats(gamerTag: String, console: String){
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
        HTTP.GET("https://my.callofduty.com/api/papi-client/stats/cod/v1/title/mw/platform/" + userConsole + "/gamer/" + gamerTag + "/profile/type/mp") { response in
            if let err = response.error {
                print("error: \(err.localizedDescription)")
                self.finishAndMoveToNext()
                return //also notify app of failure as needed
            }
            else{
                if let jsonObj = try! JSONSerialization.jsonObject(with: response.data, options: JSONSerialization.ReadingOptions()) as? [String: Any] {
                    print(jsonObj.count)
                    
                    //we need to find a way to let users see their own stats. maybe in the menu.
                    var kd = 0.0
                    var wins = 0.0
                    var wlRatio = 0.0
                    var kills = 0.0
                    var bestKills = 0.0
                    
                    if let layerOne = jsonObj["data"] as? [String: Any] {
                        let level = layerOne["level"] as? Float ?? 0.0
                        if let lifetime = layerOne["lifetime"] as? [String: Any]{
                            if let any = lifetime["all"] as? [String: Any]{
                                if let properties = any["properties"] as? [String: Any]{
                                    kd = properties["kdRatio"] as? Double ?? 0.0
                                    wins = properties["wins"] as? Double ?? 0.0
                                    wlRatio = properties["wlRatio"] as? Double ?? 0.0
                                    kills = properties["kills"] as? Double ?? 0.0
                                    bestKills = properties["bestKills"] as? Double ?? 0.0
                                }
                            }
                        }
                        let statObject = StatObject(gameName: "Call Of Duty Modern Warfare")
                        statObject.codKd = String(kd)
                        statObject.codWins = String(wins)
                        statObject.codWlRatio = String(wlRatio)
                        statObject.codKills = String(kills)
                        statObject.codBestKills = String(bestKills)
                        statObject.codLevel = String(level)
                        
                        self.saveAndProceed(statObj: statObject)
                        AppEvents.logEvent(AppEvents.Name(rawValue: "GC Register - COD Stats Received"))
                    }
                    else{
                        AppEvents.logEvent(AppEvents.Name(rawValue: "GC Register - COD Stats No Payload"))
                        self.finishAndMoveToNext()
                    }
                }
                else{
                    AppEvents.logEvent(AppEvents.Name(rawValue: "GC Register - COD No Response"))
                    self.finishAndMoveToNext()
                }
            }
        }
    }
    
    
    private func saveAndProceed(statObj: StatObject){
        DispatchQueue.main.async {
            let delegate = UIApplication.shared.delegate as! AppDelegate
            let user = delegate.currentUser

            let current = ["gameName": statObj.gameName, "killsPVE": statObj.killsPVE, "killsPVP": statObj.killsPVP, "playerLevelGame": statObj.playerLevelGame, "playerLevelPVP": statObj.playerLevelPVP, "statUrl": statObj.statUrl, "setPublic": statObj.setPublic, "authorized": statObj.authorized, "currentRank": statObj.currentRank, "totalRankedWins": statObj.totalRankedWins, "totalRankedLosses": statObj.totalRankedLosses, "totalRankedKills": statObj.totalRankedKills, "totalRankedDeaths": statObj.totalRankedLosses, "mostUsedAttacker": statObj.mostUsedAttacker, "mostUsedDefender": statObj.mostUsedDefender, "gearScore": statObj.gearScore,
                "codLevel": statObj.codLevel, "codBestKills": statObj.codBestKills, "codKills": statObj.codKills,
                "codWlRatio": statObj.codWlRatio, "codWins": statObj.codWins, "codKd": statObj.codKd]
            
            self.stats.append(current)
            user?.stats.append(statObj)
            
            self.finishAndMoveToNext()
        }
    }
    
    private func zipItUp(){
        DispatchQueue.main.async {
            let delegate = UIApplication.shared.delegate as! AppDelegate
            let user = delegate.currentUser
            
            let ref = Database.database().reference().child("Users").child((user?.uId)!)
            ref.child("games").setValue(self.gamesList)
            
            if(!self.savedTag.isEmpty){
                ref.child("gamerTag").setValue(self.savedTag)
            }
            else{
                if(!self.sendUpArray.isEmpty){
                    ref.child("gamerTag").setValue(self.sendUpArray[0]["gamerTag"])
                }
                else{
                    ref.child("gamerTag").setValue("undefined")
                }
            }
            
            var count = 0
            for array in self.sendUpArray{
                ref.child("gamerTags").child(String(count)).setValue(array)
                count += 1
            }
            
            ref.child("stats").setValue(self.stats)
        
            user?.games = self.gamesList
            
             let top = CGAffineTransform(translationX: 0, y: -40)
            UIView.animate(withDuration: 0.3, animations: {
                self.buildingAnimation.alpha = 0
                self.buildingHeader.alpha = 0
            }, completion: { (finished: Bool) in
                UIView.animate(withDuration: 0.8, delay: 0.5, options: [], animations: {
                    self.welcomeText.transform = top
                    self.welcomeText.alpha = 1
                    self.creationThumb.alpha = 0.4
                }, completion: { (finished: Bool) in
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        self.performSegue(withIdentifier: "gcSkip", sender: nil)
                    }
                    
                    AppEvents.logEvent(AppEvents.Name(rawValue: "GC Register - Successful Registration"))
                })
            })
        }
    }
}
