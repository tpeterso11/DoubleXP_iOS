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
import UnderLineTextField
import SendBirdSDK

class CreateTeamFrag: ParentVC, UICollectionViewDataSource, UICollectionViewDelegate, MSPeekImplementationDelegate, UICollectionViewDelegateFlowLayout, UITextFieldDelegate, MessagingCallbacks {
    
    @IBOutlet weak var gcGameScroll: UICollectionView!
    @IBOutlet weak var psSwitch: UISwitch!
    @IBOutlet weak var xboxSwitch: UISwitch!
    @IBOutlet weak var pcSwitch: UISwitch!
    @IBOutlet weak var nintendoSwitch: UISwitch!
    //@IBOutlet weak var teamCreateNext: UIImageView!
    @IBOutlet weak var bottomView: UIView!
    @IBOutlet weak var createButton: UIButton!
    @IBOutlet weak var teamName: UnderLineTextField!
    private var tempPayload = [String: Any]()
    private var setupTeamObj: TeamObject?
    private var selectedCells = [String]()
    
    var switches = [UISwitch]()
    var consoleChecked = false
    var gamerTagChosen = false
    var chosenGame = ""
    var chosenConsole = ""
    
    var gcGames = [GamerConnectGame]()
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //animateView()
        gcGameScroll.configureForPeekingDelegate()
        self.gcGameScroll.delegate = self
        self.gcGameScroll.dataSource = self
        
        switches.append(psSwitch)
        switches.append(xboxSwitch)
        switches.append(pcSwitch)
        switches.append(nintendoSwitch)
        
        navDictionary = ["state": "backOnly"]
        let delegate = UIApplication.shared.delegate as! AppDelegate
    
        delegate.currentLanding?.updateNavigation(currentFrag: self)
        self.pageName = "Create Team"
        
        delegate.addToNavStack(vc: self)
        gcGames = delegate.gcGames
        
        psSwitch.addTarget(self, action: #selector(psSwitchChanged), for: UIControl.Event.valueChanged)
        xboxSwitch.addTarget(self, action: #selector(xboxSwitchChanged), for: UIControl.Event.valueChanged)
        pcSwitch.addTarget(self, action: #selector(pcSwitchChanged), for: UIControl.Event.valueChanged)
        nintendoSwitch.addTarget(self, action: #selector(nintendoSwitchChanged), for: UIControl.Event.valueChanged)
        
        teamName.addTarget(self, action: #selector(self.textFieldDidChange(_:)), for: UIControl.Event.editingChanged)
        
        checkNextActivation()
        
        teamName.delegate = self
        teamName.returnKeyType = UIReturnKeyType.done
        textFieldShouldReturn(teamName)
    }
    
    func textFieldShouldReturn(_ textField: UITextField!) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    private func animateView(){
        /*DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
        self.gcGameScroll.delegate = self
        self.gcGameScroll.dataSource = self
        
            let top = CGAffineTransform(translationX: 0, y: -20)
            UIView.animate(withDuration: 0.8, animations: {
                self.gcGameScroll.alpha = 1
                self.gcGameScroll.transform = top
            }, completion: nil)
        }*/
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        if(textField.text != nil){
            if textField.text!.count >= 3 {
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
            createButton.alpha = 1
            
            createButton.isUserInteractionEnabled = true
             createButton.addTarget(self, action: #selector(createButtonClicked), for: .touchUpInside)
        }
        else{
            createButton.alpha = 0.33
           
            createButton.isUserInteractionEnabled = false
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
        
        var teammates = [TeammateObject]()
        let captain = TeammateObject(gamerTag: manager.getGamerTagForGame(gameName: currentGame!.gameName), date: "", uid: user!.uId)
        teammates.append(captain)
        
        let newTeam = TeamObject(teamName: teamName.text!, teamId: randomAlphaNumericString(length: 12), games: selected, consoles: consoles, teammateTags: teammateTags, teammateIds: teammateIds, teamCaptain: manager.getGamerTagForGame(gameName: chosenGame), teamInvites: [TeamInviteObject](), teamChat: "", teamInviteTags: [String](), teamNeeds: currentGame?.teamNeeds ?? [String](), selectedTeamNeeds: [String](), imageUrl: currentGame?.imageUrl ?? "")
        newTeam.teammates = teammates
        
        createTeam(team: newTeam)
    }
    
    private func createTeam(team: TeamObject){
        self.setupTeamObj = team
        
        let manager = MessagingManager()
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let user = appDelegate.currentUser
        
        manager.setup(sendBirdId: nil, currentUser: user!, messagingCallbacks: self)
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
        
        cell.hook.text = game.secondaryName.uppercased()
        
        if(self.selectedCells.contains(game.gameName)){
            cell.hook.isHidden = false
            cell.cover.isHidden = false
        }
        else{
            cell.hook.isHidden = true
            cell.cover.isHidden = true
        }
        
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
        
        return CGSize(width: collectionView.bounds.size.width - 20, height: CGFloat(kWhateverHeightYouWant))
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let currentCell = collectionView.cellForItem(at: indexPath as IndexPath) as! homeGCCell
        
        self.chosenGame = ""
        
        if(self.selectedCells.contains(self.gcGames[indexPath.item].gameName)){
            self.selectedCells.remove(at: self.selectedCells.index(of: self.gcGames[indexPath.item].gameName)!)
            currentCell.cover.isHidden = true
            currentCell.hook.isHidden = true
        }
        else{
            self.selectedCells = [String]()
            self.selectedCells.append(currentCell.hook.text!)
            currentCell.cover.isHidden = false
            currentCell.hook.isHidden = false
            
            self.chosenGame = self.gcGames[indexPath.item].gameName
        }
        
        
        for cell in collectionView.visibleCells as! [homeGCCell] {
            if cell == collectionView.cellForItem(at: indexPath as IndexPath) as! homeGCCell{
                if(cell != currentCell && cell.cover.isHidden == false){
                    cell.cover.isHidden = true
                    cell.hook.isHidden = true
                }
            }
            else{
                cell.cover.isHidden = true
                cell.hook.isHidden = true
            }
        }
    }

    func connectionSuccessful() {
        let manager = MessagingManager()
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let user = appDelegate.currentUser
        manager.createTeamChannel(userId: user!.uId, callbacks: self)
    }
    
    func createTeamChannelSuccessful(groupChannel: SBDGroupChannel) {
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let user = delegate.currentUser
        let ref = Database.database().reference().child("Teams")
        let userRef = Database.database().reference().child("Users").child(user!.uId)
        let team = self.setupTeamObj!
        
        var teammates = [Dictionary<String, String>]()
        for teammate in team.teammates{
            let current = ["gamerTag": teammate.gamerTag, "date": teammate.date, "uid": teammate.uid]
            teammates.append(current)
        }
        
        tempPayload = ["teamName": team.teamName, "teamId": team.teamId, "games": team.games, "consoles": team.consoles, "teammateTags": team.teammateTags, "teammateIds": team.teammateIds, "teamCaptain": team.teamCaptain, "teamInvites": team.teamInvites, "teamChat": groupChannel.channelUrl, "teamInviteTags": team.teamInviteTags, "teamNeeds": team.teamNeeds, "selectedTeamNeeds": team.selectedTeamNeeds, "imageUrl": team.imageUrl, "teammates": teammates] as [String : Any]
        
        user?.teams.append(team)
        ref.child(team.teamName).setValue(tempPayload)
        userRef.child("teams").child(team.teamName).setValue(tempPayload)
        
        let currentLanding = delegate.currentLanding
        if (!self.setupTeamObj!.teamNeeds.isEmpty){
            currentLanding?.navigateToTeamNeeds(team: self.setupTeamObj!)
        }
        else{
            currentLanding?.navigateToTeamDashboard(team: self.setupTeamObj!, newTeam: true)
        }
    }
    
    func messageSuccessfullyReceived(message: SBDUserMessage) {
    }
    
    func onMessagesLoaded(messages: [SBDUserMessage]) {
    }
    
    func successfulLeaveChannel() {
    }
    
    func messageSentSuccessfully(chatMessage: ChatMessage, sender: SBDSender) {
    }
}
