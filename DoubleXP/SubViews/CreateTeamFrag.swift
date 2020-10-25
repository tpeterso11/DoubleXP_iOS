//
//  CreateTeamFrag.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 11/24/19.
//  Copyright © 2019 Peterson, Toussaint. All rights reserved.
//

import UIKit
import Firebase
import moa
import MSPeekCollectionViewDelegateImplementation
import UnderLineTextField
import SendBirdSDK
import NotificationCenter
import FBSDKCoreKit
import MSPeekCollectionViewDelegateImplementation

class CreateTeamFrag: ParentVC, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UITextFieldDelegate, MessagingCallbacks {
    
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var drawerBack: UIView!
    @IBOutlet weak var gcEnterDone: UIButton!
    @IBOutlet weak var gcGamertagEntry: UnderLineTextField!
    @IBOutlet weak var gcEnterDrawer: UIView!
    @IBOutlet weak var gcGameScroll: UICollectionView!
    @IBOutlet weak var psSwitch: UISwitch!
    @IBOutlet weak var xboxSwitch: UISwitch!
    @IBOutlet weak var pcSwitch: UISwitch!
    @IBOutlet weak var nintendoSwitch: UISwitch!
    //@IBOutlet weak var teamCreateNext: UIImageView!
    @IBOutlet weak var bottomView: UIView!
    @IBOutlet weak var createButton: UIButton!
    @IBOutlet weak var teamName: UnderLineTextField!
    @IBOutlet weak var loadingView: UIView!
    private var tempPayload = [String: Any]()
    private var tempUserPayload = [String: String]()
    private var setupTeamObj: TeamObject?
    private var selectedCells = [String]()
    var gcHeight: CGFloat?
    
    var switches = [UISwitch]()
    var consoleChecked = false
    var teamNameChosen = false
    var gamertagEntered = false
    var chosenGame = ""
    var chosenConsole = ""
    var enteredTag = ""
    var startHeight: CGFloat = 240
    private var drawerOpen = false
    private var clicked = false
    
    var behavior: MSCollectionViewPeekingBehavior!
    
    var gcGames = [GamerConnectGame]()
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //animateView()
        self.gcGameScroll.delegate = self
        self.gcGameScroll.dataSource = self
        
        behavior = MSCollectionViewPeekingBehavior()
        self.gcGameScroll.configureForPeekingBehavior(behavior: behavior)
        
        switches.append(psSwitch)
        switches.append(xboxSwitch)
        switches.append(pcSwitch)
        switches.append(nintendoSwitch)
        
        let delegate = UIApplication.shared.delegate as! AppDelegate
        var list = [GamerConnectGame]()
        for game in delegate.gcGames {
            if(game.available == "true"){
                list.append(game)
            }
        }
        
        gcGames = list
        
        psSwitch.addTarget(self, action: #selector(psSwitchChanged), for: UIControl.Event.valueChanged)
        xboxSwitch.addTarget(self, action: #selector(xboxSwitchChanged), for: UIControl.Event.valueChanged)
        pcSwitch.addTarget(self, action: #selector(pcSwitchChanged), for: UIControl.Event.valueChanged)
        nintendoSwitch.addTarget(self, action: #selector(nintendoSwitchChanged), for: UIControl.Event.valueChanged)
        
        teamName.addTarget(self, action: #selector(self.textFieldDidChange(_:)), for: UIControl.Event.editingChanged)
        
        checkNextActivation()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillDisappear),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
        
        teamName.delegate = self
        teamName.returnKeyType = UIReturnKeyType.done
        textFieldShouldReturn(teamName)
    }
    
    func textFieldShouldReturn(_ textField: UITextField!) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    @objc func keyboardWillDisappear() {
        if(drawerOpen){
            let top = CGAffineTransform(translationX: 0, y: -240)
            UIView.animate(withDuration: 0.5, animations: {
                self.gcEnterDrawer.transform = top
            }, completion: nil)
        }
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
        if(textField.text != nil && textField == teamName){
            if textField.text!.count >= 3 {
                teamNameChosen = true
                checkNextActivation()
            }
            else{
                teamNameChosen = false
                checkNextActivation()
            }
        }
        else if(textField.text != nil && textField == gcGamertagEntry){
            if textField.text!.count >= 3 {
                gamertagEntered = true
                gcEnterDone.alpha = 1
                gcEnterDone.isUserInteractionEnabled = true
            }
            else{
                gamertagEntered = false
                gcEnterDone.alpha = 0.3
                gcEnterDone.isUserInteractionEnabled = false
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
                        console = "nintendo"
                    }
                    if(uiSwitch == self.xboxSwitch){
                        console = "xbox"
                    }
                    if(uiSwitch == self.psSwitch){
                        console = "ps"
                    }
                    if(uiSwitch == self.pcSwitch){
                        console = "pc"
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
        if(consoleChecked && teamNameChosen){
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
        let delegate = UIApplication.shared.delegate as! AppDelegate
        if(delegate.currentUser!.games.contains(self.chosenGame)){
            showLoading(tag: true)
        }
        else{
            showDrawer()
        }
    }
    
    @objc private func handleClick(){
        self.enteredTag = self.gcGamertagEntry.text!
        
        dismissDrawer()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            if(!self.enteredTag.isEmpty){
                self.showLoading(tag: false)
            }
        }
    }
    
    private func showLoading(tag: Bool){
        UIView.animate(withDuration: 0.8, animations: {
            self.loadingView.alpha = 1
        }, completion: { (finished: Bool) in
            if(tag){
                self.createTeamTag()
            }
            else{
                self.saveNewProfile()
                self.createTeamNoTag()
            }
        })
    }
    
    private func saveNewProfile(){
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let user = delegate.currentUser
        let userRef = Database.database().reference().child("Users").child(user!.uId)
        userRef.observeSingleEvent(of: .value, with: { (snapshot) in
            if(snapshot.exists()){
                var gamerTags = [GamerProfile]()
                let gamerTagsArray = snapshot.childSnapshot(forPath: "gamerTags")
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
                
                var profilesUp = [[String: String]]()
                for profile in gamerTags{
                    let current = ["gamerTag": profile.gamerTag, "game": profile.game, "console": profile.console]
                    profilesUp.append(current)
                }
                
                let sendUp = ["gamerTag": self.enteredTag, "game": self.chosenGame, "console": self.chosenConsole]
                profilesUp.append(sendUp)
                
                userRef.child("gamerTags").setValue(profilesUp)
    
                AppEvents.logEvent(AppEvents.Name(rawValue: "Create Frag - New Profile Created"))
            }
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
    private func createTeamNoTag(){
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let user = delegate.currentUser
        
        var selected = [String]()
        selected.append(self.chosenGame)
        
        var consoles = [String]()
        consoles.append(self.chosenConsole)
        
        var teammateTags = [String]()
        teammateTags.append(self.enteredTag)
        
        var teammateIds = [String]()
        teammateIds.append(user?.uId ?? "")
        
        let currentGame = getGameInfo(selectedGame: chosenGame)
        
        let formatter = DateFormatter()
        //2016-12-08 03:37:22 +0000
        //formatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
        formatter.dateFormat = "MM-dd-yyyy"
        let now = Date()
        let dateString = formatter.string(from:now)
        
        var teammates = [TeammateObject]()
        let captain = TeammateObject(gamerTag: self.enteredTag, date: dateString, uid: user!.uId)
        teammates.append(captain)
        
        let newTeam = TeamObject(teamName: teamName.text!, teamId: randomAlphaNumericString(length: 12), games: selected, consoles: consoles, teammateTags: teammateTags, teammateIds: teammateIds, teamCaptain: self.enteredTag, teamInvites: [TeamInviteObject](), teamChat: "", teamInviteTags: [String](), teamNeeds: currentGame?.teamNeeds ?? [String](), selectedTeamNeeds: [String](), imageUrl: currentGame?.imageUrl ?? "", teamCaptainId: delegate.currentUser!.uId, isRequest: "false")
        newTeam.teammates = teammates
        
        createTeam(team: newTeam)
    }
    
    private func createTeamTag(){
        let delegate = UIApplication.shared.delegate as! AppDelegate
        var selected = [String]()
        selected.append(self.chosenGame)
        
        var consoles = [String]()
        consoles.append(self.chosenConsole)
        
        let manager = GamerProfileManager()
        let user = delegate.currentUser
        
        var teammateTags = [String]()
        teammateTags.append(manager.getGamerTagForGame(gameName: chosenGame))
        
        var teammateIds = [String]()
        teammateIds.append(user?.uId ?? "")
        
        let currentGame = getGameInfo(selectedGame: chosenGame)
        
        let formatter = DateFormatter()
        //2016-12-08 03:37:22 +0000
        //formatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
        formatter.dateFormat = "MM-dd-yyyy"
        let now = Date()
        let dateString = formatter.string(from:now)
        
        var teammates = [TeammateObject]()
        let captain = TeammateObject(gamerTag: manager.getGamerTagForGame(gameName: currentGame!.gameName), date: dateString, uid: user!.uId)
        teammates.append(captain)
        
        if(!self.chosenGame.isEmpty){
            let newTeam = TeamObject(teamName: teamName.text!, teamId: randomAlphaNumericString(length: 12), games: selected, consoles: consoles, teammateTags: teammateTags, teammateIds: teammateIds, teamCaptain: manager.getGamerTagForGame(gameName: chosenGame), teamInvites: [TeamInviteObject](), teamChat: "", teamInviteTags: [String](), teamNeeds: currentGame?.teamNeeds ?? [String](), selectedTeamNeeds: [String](), imageUrl: currentGame?.imageUrl ?? "", teamCaptainId: delegate.currentUser!.uId, isRequest: "false")
            newTeam.teammates = teammates
            
            createTeam(team: newTeam)
        }
    }
    
    private func showDrawer(){
        UIView.animate(withDuration: 0.5, animations: {
            self.drawerBack.alpha = 1
        }, completion: { (finished: Bool) in
            let top = CGAffineTransform(translationX: 0, y: -240)
            
            UIView.animate(withDuration: 0.5, animations: {
                self.gcEnterDrawer.transform = top
            }, completion: nil)
        })
        
        self.drawerOpen = true
        gcGamertagEntry.returnKeyType = .done
        gcGamertagEntry.delegate = self
        gcGamertagEntry.addTarget(self, action: #selector(textFieldDidChange), for: UIControl.Event.editingChanged)
        gcEnterDone.addTarget(self, action: #selector(handleClick), for: .touchUpInside)
        gcEnterDone.alpha = 0.3
        gcEnterDone.isUserInteractionEnabled = false
        
        cancelButton.addTarget(self, action: #selector(dismissDrawer), for: .touchUpInside)
        
        checkNextActivation()
        
        AppEvents.logEvent(AppEvents.Name(rawValue: "Create Frag - Drawer Open"))
    }
    
    @objc func keyboardWillShow(_ notification: Notification) {
        if(drawerOpen){
            if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
                let keyboardRectangle = keyboardFrame.cgRectValue
                let keyboardHeight = keyboardRectangle.height
                
                self.gcHeight = keyboardHeight
                
                extendBottom(height: self.gcHeight!)
            }
        }
    }
    
    private func extendBottom(height: CGFloat){
        let top = CGAffineTransform(translationX: 0, y: -self.gcHeight! - 100)
        UIView.animate(withDuration: 0.8, animations: {
            self.gcEnterDrawer.transform = top
        }, completion: nil)
    }
    
    @objc private func dismissDrawer(){
        let top = CGAffineTransform(translationX: 0, y: 0)
        UIView.animate(withDuration: 0.5, delay: 0.2, options: [], animations: {
            self.gcEnterDrawer.transform = top
        }, completion: { (finished: Bool) in
                UIView.animate(withDuration: 0.5) {
                self.drawerBack.alpha = 0
            }
        })
    }
    
    // work on if channel creation fails
    // make sure on settings, if game is added, new profile is made.
    // test sending and receving requests.
    // and then a little more logging and we're DONE!
    
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
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let cache = appDelegate.imageCache
        if(cache.object(forKey: game.imageUrl as NSString) != nil){
            cell.backgroundImage.image = cache.object(forKey: game.imageUrl as NSString)
        } else {
            cell.backgroundImage.image = Utility.Image.placeholder
            cell.backgroundImage.moa.onSuccess = { image in
                cell.backgroundImage.image = image
                appDelegate.imageCache.setObject(image, forKey: game.imageUrl as NSString)
                return image
            }
            cell.backgroundImage.moa.url = game.imageUrl
        }
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
        
        if(self.selectedCells.contains(self.gcGames[indexPath.item].gameName)){
            self.selectedCells.remove(at: self.selectedCells.index(of: self.gcGames[indexPath.item].gameName)!)
            currentCell.cover.isHidden = true
            currentCell.hook.isHidden = true
            
            self.chosenGame = ""
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
        DispatchQueue.main.async {
            let manager = MessagingManager()
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let user = appDelegate.currentUser
            manager.createTeamChannel(userId: user!.uId, callbacks: self)
        }
    }
    
    func connectionFailed() {
        DispatchQueue.main.async {
            let manager = MessagingManager()
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let user = appDelegate.currentUser
            manager.createTeamChannel(userId: user!.uId, callbacks: self)
        }
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
        
        tempPayload = ["teamName": team.teamName, "teamId": team.teamId, "games": team.games, "consoles": team.consoles, "teammateTags": team.teammateTags, "teammateIds": team.teammateIds, "teamCaptain": team.teamCaptain, "teamInvites": team.teamInvites, "teamChat": groupChannel.channelUrl, "teamInviteTags": team.teamInviteTags, "teamNeeds": team.teamNeeds, "selectedTeamNeeds": team.selectedTeamNeeds, "imageUrl": team.imageUrl, "teammates": teammates, "teamCaptainId": delegate.currentUser!.uId] as [String : Any]
        
        tempUserPayload = ["teamName": team.teamName, "teamId": team.teamId, "gameName": team.games[0], "teamCaptainId": team.teamCaptainId, "newTeam": "false"]
    
        let easyTeam = EasyTeamObj(teamName: team.teamName, teamId: team.teamId, gameName: team.games[0], teamCaptainId: team.teamCaptainId, newTeam: "false")
        
        team.teamChat = groupChannel.channelUrl
        user?.teams.append(easyTeam)
        
        //send to teams
        ref.child(team.teamName).setValue(tempPayload)
        updateUser(userRef: userRef)
    }
    
    private func updateUser(userRef: DatabaseReference){
        userRef.observeSingleEvent(of: .value, with: { (snapshot) in
            if(snapshot.exists()){
                let teams = [EasyTeamObj]()
                if(snapshot.hasChild("teams")){
                    var teams = [EasyTeamObj]()
                    let teamsArray = snapshot.childSnapshot(forPath: "teams")
                    for teamObj in teamsArray.children {
                        let currentObj = teamObj as! DataSnapshot
                        let dict = currentObj.value as? [String: Any]
                        let teamName = dict?["teamName"] as? String ?? ""
                        let teamId = dict?["teamId"] as? String ?? ""
                        let game = dict?["gameName"] as? String ?? ""
                        let teamCaptainId = dict?["teamCaptainId"] as? String ?? ""
                        let newTeam = dict?["newTeam"] as? String ?? ""
                        
                        teams.append(EasyTeamObj(teamName: teamName, teamId: teamId, gameName: game, teamCaptainId: teamCaptainId, newTeam: newTeam))
                    }
                }
                
                
                var sendUpArray = [[String: Any]]()
                
                for team in teams {
                    let current = ["teamName": team.teamName, "teamId": team.teamId, "gameName": team.gameName, "newTeam": team.newTeam] as [String : String]
                    
                    sendUpArray.append(current)
                }
                sendUpArray.append(self.tempUserPayload)
                userRef.child("teams").setValue(sendUpArray)
                
                let delegate = UIApplication.shared.delegate as! AppDelegate
                let currentLanding = delegate.currentLanding
                if (!self.setupTeamObj!.teamNeeds.isEmpty){
                    currentLanding?.navigateToTeamNeeds(team: self.setupTeamObj!)
                }
                else{
                    currentLanding?.startDashNavigation(teamName: self.setupTeamObj!.teamName, teamInvite: nil, newTeam: true)
                }
                
                AppEvents.logEvent(AppEvents.Name(rawValue: "Create Frag - Team Created With Chat"))
            }
            
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
    func createTeamChannelFail() {
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
        
        tempPayload = ["teamName": team.teamName, "teamId": team.teamId, "games": team.games, "consoles": team.consoles, "teammateTags": team.teammateTags, "teammateIds": team.teammateIds, "teamCaptain": team.teamCaptain, "teamInvites": team.teamInvites, "teamChat": "", "teamInviteTags": team.teamInviteTags, "teamNeeds": team.teamNeeds, "selectedTeamNeeds": team.selectedTeamNeeds, "imageUrl": team.imageUrl, "teammates": teammates] as [String : Any]
        
        tempUserPayload = ["teamName": team.teamName, "teamId": team.teamId, "gameName": team.games[0], "newTeam": "false"]
        
        let easyTeam = EasyTeamObj(teamName: team.teamName, teamId: team.teamId, gameName: team.games[0], teamCaptainId: team.teamCaptainId, newTeam: "false")
        user?.teams.append(easyTeam)
        
        //send to teams
        ref.child(team.teamName).setValue(tempPayload)
        updateUser(userRef: userRef)
    }
    
    
    func errorLoadingMessages() {
    }
    
    func createTeamChannelFailed(){
        createTeamChannelFail()
    }
    
    func errorLoadingChannel() {
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
