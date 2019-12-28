//
//  CreateTeamFrag.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 11/24/19.
//  Copyright © 2019 Peterson, Toussaint. All rights reserved.
//

import UIKit
import Firebase
import ImageLoader
import moa
import MSPeekCollectionViewDelegateImplementation

class CreateTeamFrag: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, MSPeekImplementationDelegate, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet weak var gcGameScroll: UICollectionView!
    @IBOutlet weak var psSwitch: UISwitch!
    @IBOutlet weak var xboxSwitch: UISwitch!
    @IBOutlet weak var pcSwitch: UISwitch!
    @IBOutlet weak var nintendoSwitch: UISwitch!
    @IBOutlet weak var teamCreateNext: UIImageView!
    @IBOutlet weak var teamName: UITextField!
    
    var switches = [UISwitch]()
    var consoleChecked = false
    var gamerTagChosen = false
    var chosenGame = ""
    var chosenConsole = ""
    
    var gcGames = [GamerConnectGame]()
    override func viewDidLoad() {
        super.viewDidLoad()
        
        gcGameScroll.delegate = self
        gcGameScroll.dataSource = self
        gcGameScroll.configureForPeekingDelegate()
        
        switches.append(psSwitch)
        switches.append(xboxSwitch)
        switches.append(pcSwitch)
        switches.append(nintendoSwitch)
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate!
        gcGames = appDelegate!.gcGames
        
        psSwitch.addTarget(self, action: #selector(psSwitchChanged), for: UIControl.Event.valueChanged)
        xboxSwitch.addTarget(self, action: #selector(xboxSwitchChanged), for: UIControl.Event.valueChanged)
        pcSwitch.addTarget(self, action: #selector(pcSwitchChanged), for: UIControl.Event.valueChanged)
        nintendoSwitch.addTarget(self, action: #selector(nintendoSwitchChanged), for: UIControl.Event.valueChanged)
        
        teamName.addTarget(self, action: #selector(self.textFieldDidChange(_:)), for: UIControl.Event.editingChanged)
        
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(createButtonClicked(_:)))
        singleTap.numberOfTapsRequired = 1
        teamCreateNext.isUserInteractionEnabled = true
        teamCreateNext.addGestureRecognizer(singleTap)
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        if(textField.text != nil){
            if textField.text!.count >= 5 {
                gamerTagChosen = true
                checkNextActivation()
            }
            else{
                gamerTagChosen = false
                checkNextActivation()
            }
        }
    }
    
    @objc func psSwitchChanged(psSwitch: UISwitch) {
        cycleSwitches(selectedSwitch:psSwitch)
    }
    
    @objc func xboxSwitchChanged(xboxSwitch: UISwitch) {
        cycleSwitches(selectedSwitch:xboxSwitch)
    }
    
    @objc func pcSwitchChanged(pcSwitch: UISwitch) {
        cycleSwitches(selectedSwitch:pcSwitch)
    }
    
    @objc func nintendoSwitchChanged(nintendoSwitch: UISwitch) {
        cycleSwitches(selectedSwitch:nintendoSwitch)
    }
    
    private func cycleSwitches(selectedSwitch: UISwitch){
        var console = ""
        for uiSwitch in self.switches{
            if(uiSwitch == selectedSwitch){
                if(!uiSwitch.isOn){
                    uiSwitch.isOn = false
                }
                else{
                    uiSwitch.isOn = true
                    
                    if(uiSwitch == self.nintendoSwitch){
                        console = "Switch"
                    }
                    if(uiSwitch == self.xboxSwitch){
                        console = "XBox"
                    }
                    if(uiSwitch == self.psSwitch){
                        console = "Playstation"
                    }
                    if(uiSwitch == self.pcSwitch){
                        console = "PC"
                    }
                    
                    consoleChecked = true
                }
            }
            else{
                uiSwitch.isOn = false
            }
        }
        
        if(console == ""){
            consoleChecked = false
        }
        self.chosenConsole = console
        
        checkNextActivation()
    }
    
    
    private func checkNextActivation(){
        if(consoleChecked && gamerTagChosen){
            teamCreateNext.alpha = 1
            
            teamCreateNext.isUserInteractionEnabled = true
        }
        else{
            teamCreateNext.alpha = 0.33
           
            teamCreateNext.isUserInteractionEnabled = false
        }
    }
    
    @objc func createButtonClicked(_ sender: AnyObject?) {
       var selected = [String]()
        selected.append(self.chosenGame)
        
        var consoles = [String]()
        consoles.append(self.chosenConsole)
        
        let delegate = UIApplication.shared.delegate as! AppDelegate!
        let manager = GamerProfileManager()
        let user = delegate?.currentUser
        
        var teammateTags = [String]()
        teammateTags.append(manager.getGamerTagForGame(gameName: chosenGame))
        
        var teammateIds = [String]()
        teammateIds.append(user?.uId ?? "")
        
        let currentGame = getGameInfo(selectedGame: chosenGame)
        
        let newTeam = TeamObject(teamName: teamName.text!, teamId: randomAlphaNumericString(length: 12), games: selected, consoles: consoles, teammateTags: teammateTags, teammateIds: teammateIds, teamCaptain: manager.getGamerTagForGame(gameName: chosenGame), teamInvites: [TeamInviteObject](), teamChat: "", teamInviteTags: [String](), teamNeeds: currentGame?.teamNeeds ?? [String](), selectedTeamNeeds: [String](), imageUrl: currentGame?.imageUrl ?? "")
        
        createTeam(team: newTeam)
    }
    
    private func createTeam(team: TeamObject){
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let user = delegate.currentUser
        
        let ref = Database.database().reference().child("Teams")

        let current = ["teamName": team.teamName, "teamId": team.teamId, "games": team.games, "consoles": team.consoles, "teammateTags": team.teammateTags, "teammateIds": team.teammateIds, "teamCaptain": team.teamCaptain, "teamInvites": team.teamInvites, "teamChat": team.teamChat, "teamInviteTags": team.teamInviteTags, "teamNeeds": team.teamNeeds, "selectedTeamNeeds": team.selectedTeamNeeds, "imageUrl": team.imageUrl] as [String : Any]
        
        ref.child(team.teamName).setValue(current)
        
        user?.teams.append(team)
        
        if (!team.teamNeeds.isEmpty){
            LandingActivity().navigateToTeamNeeds(team: team)
        }
        else{
            LandingActivity().navigateToTeamDashboard(team: team, newTeam: true)
        }
    }
    
    private func randomAlphaNumericString(length: Int) -> String {
        let allowedChars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        var randomString = ""

        for _ in 0..<length {
            let randomNum = Int(arc4random_uniform(UInt32(allowedChars.characters.count)))
            let randomIndex = allowedChars.index(allowedChars.startIndex, offsetBy: randomNum)
            let newCharacter = allowedChars[randomIndex]
            randomString += String(newCharacter)
        }

        return randomString
    }
    
    private func getGameInfo(selectedGame: String) -> GamerConnectGame?{
        for game in gcGames{
            if(game.gameName == selectedGame){
                return game
            }
        }
        return nil
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return gcGames.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! homeGCCell
        
        let game = gcGames[indexPath.item]
        cell.backgroundImage.moa.url = game.imageUrl
        cell.backgroundImage.contentMode = .scaleAspectFill
        cell.backgroundImage.clipsToBounds = true
        
        cell.hook.text = game.gameName
        cell.hook.isHidden = true
        
        cell.cover.clipsToBounds = true
        cell.cover.bounds.size.height = cell.bounds.size.height
        cell.cover.bounds.size.width = cell.bounds.size.width
        
        cell.contentView.layer.cornerRadius = 2.0
        cell.contentView.layer.borderWidth = 1.0
        cell.contentView.layer.borderColor = UIColor.clear.cgColor
        cell.contentView.layer.masksToBounds = true
        
        cell.layer.shadowColor = UIColor.black.cgColor
        cell.layer.shadowOffset = CGSize(width: 0, height: 2.0)
        cell.layer.shadowRadius = 2.0
        cell.layer.shadowOpacity = 0.5
        cell.layer.masksToBounds = false
        cell.layer.shadowPath = UIBezierPath(roundedRect: cell.bounds, cornerRadius: cell.contentView.layer.cornerRadius).cgPath
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let kWhateverHeightYouWant = 150
        
        return CGSize(width: collectionView.bounds.size.width - 40, height: CGFloat(kWhateverHeightYouWant))
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        for cell in collectionView.visibleCells as! [homeGCCell] {
            if cell == collectionView.cellForItem(at: indexPath as IndexPath) as! homeGCCell{
                if(cell.cover.isHidden == false){
                    cell.cover.isHidden = true
                    cell.hook.isHidden = true
                    
                    self.chosenGame = ""
                }
                else{
                    self.chosenGame = cell.hook.text!
                    cell.cover.isHidden = false
                    cell.hook.isHidden = false
                }
            }
            else{
                cell.cover.isHidden = true
                cell.hook.isHidden = true
            }
        }
    }

}
