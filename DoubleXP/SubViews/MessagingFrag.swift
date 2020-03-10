//
//  MessagingFrag.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 12/7/19.
//  Copyright © 2019 Peterson, Toussaint. All rights reserved.
//

import UIKit
import Firebase
import ImageLoader
import moa
import MSPeekCollectionViewDelegateImplementation
import SendBirdSDK
import MessageKit
import SwiftNotificationCenter

class MessagingFrag: ParentVC, MessagingCallbacks, SearchCallbacks, UITableViewDelegate, UITableViewDataSource {
    var currentUser: User?
    var groupChannelUrl: String?
    var manager: MessagingManager?
    var otherUserId: String?
    var chatMessages = [Any]()
    var mentionedUsers = [String]()

    @IBOutlet weak var messagingView: UITableView!
    //@IBOutlet weak var sendButton: UIButton!
    
    var estimatedHeight: CGFloat?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        manager = MessagingManager()
        navDictionary = ["state": "messaging", "searchHint": "Message this user.", "sendButton": "Send"]
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let currentUser = delegate.currentUser
        
        delegate.currentLanding?.updateNavigation(currentFrag: self)
        if(!delegate.navStack.contains(self)){
            delegate.navStack.append(self)
        }
        
        manager!.setup(sendBirdId: currentUser!.sendBirdId, currentUser: currentUser!, messagingCallbacks: self)
        
        self.pageName = "Messaging"
        
        Broadcaster.register(SearchCallbacks.self, observer: self)
    }
    
    func connectionSuccessful() {
        if(groupChannelUrl != nil){
            manager?.loadGroupChannel(channelUrl: groupChannelUrl!, team: true)
        }
        else{
            seeIfChannelExists()
        }
    }
    
    func seeIfChannelExists(){
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let currentUser = appDelegate.currentUser
        let ref = Database.database().reference().child("Users").child(currentUser!.uId)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            if(snapshot.exists()){
                var legacy = false
                var array = [ChatObject]()
                let messagingArray = snapshot.childSnapshot(forPath: "messaging")
                for channel in messagingArray.children{
                    let currentObj = channel as! DataSnapshot
                    let dict = currentObj.value as! [String: Any]
                    let channelUrl = dict["channelUrl"] as? String ?? ""
                    let otherUser = dict["otherUser"] as? String ?? ""
                    let legacyUser = dict["legacy"] as? String ?? ""
                    let otherUserId = dict["otherUserId"] as? String ?? ""
                    if(legacyUser == "true"){
                        legacy = true
                        break
                    }
                    
                    let chatObj = ChatObject(chatUrl: channelUrl, otherUser: otherUser)
                    chatObj.otherUserId = otherUserId
                    array.append(chatObj)
                }
                
                if(legacy){
                    self.convertChatObjects()
                    return
                }
                
                if(!array.isEmpty){
                    var contained = false
                    for object in array{
                        if(object.otherUserId == self.otherUserId){
                            self.manager?.loadGroupChannel(channelUrl: object.chatUrl, team: false)
                            contained = true
                            break
                        }
                    }
                    
                    if(!contained){
                        let appDelegate = UIApplication.shared.delegate as! AppDelegate
                        let currentUser = appDelegate.currentUser
                        self.manager?.createTeamChannel(userId: currentUser!.uId, callbacks: self)
                    }
                }
                else{
                    let appDelegate = UIApplication.shared.delegate as! AppDelegate
                    let currentUser = appDelegate.currentUser
                    self.manager?.createTeamChannel(userId: currentUser!.uId, callbacks: self)
                }
            }
            
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
    private func convertChatObjects(){
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let currentUser = appDelegate.currentUser
        let ref = Database.database().reference().child("Users").child(currentUser!.uId)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            if(snapshot.exists()){
                var array = [ChatObject]()
                let messagingArray = snapshot.childSnapshot(forPath: "messaging")
                for channel in messagingArray.children{
                    let currentObj = channel as! DataSnapshot
                    let dict = currentObj.value as! [String: Any]
                    let channelUrl = dict["channelUrl"] as? String ?? ""
                    let otherUser = dict["otherUser"] as? String ?? ""
                    
                    let chatObj = ChatObject(chatUrl: channelUrl, otherUser: otherUser)
                    chatObj.otherUserId = self.otherUserId!
                    
                    array.append(chatObj)
                }
                
                if(!array.isEmpty){
                    ref.child("messaging").removeValue()
                    
                    var newArray = [[String: Any]]()
                    for chatObj in array{
                        let newOject = ["channelUrl": chatObj.chatUrl, "otherUser": chatObj.otherUser, "otherUserId": chatObj.otherUserId, "legacy": "false"] as [String : Any]
                        newArray.append(newOject)
                    }
                    ref.child("messaging").setValue(newArray)
                    
                    self.seeIfChannelExists()
                }
                else{
                    //show error
                }
            }
            
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
    private func convertMessages(messages: [SBDUserMessage]){
        let count = messages.count
        
        if(count == 0){
            //show empty, show first message
        }
        else{
            chatMessages = [ChatMessage]()
            chatMessages.append(0)
            for message in messages{
                let date = NSDate(timeIntervalSince1970: TimeInterval(message.createdAt))
                let formatter = DateFormatter()
                formatter.dateFormat = "MMMM.dd.yyyy"
                let result = formatter.string(from: date as Date)
                
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                let currentUser = appDelegate.currentUser
                
                let chatMessage = ChatMessage(message: message.message!, timeStamp: result)
                chatMessage.data = message.data ?? ""
                chatMessage.senderString = chatMessage.data
                
                //if(message.mentionedUsers != nil){
                //    chatMessage.mentionedUsers = message.mentionedUsers!
                //}
                
                chatMessages.append(chatMessage)
            }
            
            let testOne = ChatMessage(message: "Boolgkakmkfaknfdalfndljfnd dnafljdnfdljnfl adnfldfnadljf nadfljdanf", timeStamp: "dfadf")
            testOne.senderString = currentUser!.uId
            
            let testTwo = ChatMessage(message: "Boolgkakmkfaknfdalfndljfnd dnafljdnfdljnfl adnfldfnadljf nadfljdanfalkfnadlngdlgndlgndlkgndalkgndalgndalgndngdalkngdalkngldakndalkgndlkgndlknglakgnanglshgshfgksdhfgksdfhg ljnljnjfsndlfjndgngnfla", timeStamp: "dfadf")
            testTwo.senderString = currentUser!.uId
            
            let testThree = ChatMessage(message: "Boolgkakmkfaknfdalfndljfnd dnafljdnfdljnfl adnfldfnadljf nadfljdanfalkfnadlngdlgndlgndlkgndalkgndalgndalgndngdalkngdalkngldakndalkgndlkgndlknglakgnanglshgshfgksdhfgksdfhg ljnljnjfsndlfjndgngnfla", timeStamp: "dfadf")
            testThree.senderString = ""
            
            //chatMessages.append(testOne)
            chatMessages.append(testTwo)
            chatMessages.append(testThree)
            
            chatMessages.append(0)
            
            messagingView.delegate = self
            messagingView.dataSource = self
            
            messagingView.reloadData()
            messagingView.layoutIfNeeded()
            messagingView.heightAnchor.constraint(equalToConstant: messagingView.contentSize.height).isActive = true
            scrollToBottom()
        }
    }
    
    func createTeamChannelSuccessful(groupChannel: SBDGroupChannel) {
    }
    
    func messageSuccessfullyReceived(message: SBDUserMessage) {
        let date = NSDate(timeIntervalSince1970: TimeInterval(message.createdAt))
                   let formatter = DateFormatter()
                   formatter.dateFormat = "MMMM.dd.yyyy"
                   let result = formatter.string(from: date as Date)
        
        let chatMessage = ChatMessage(message: message.message!, timeStamp: result)
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        //let currentUser = appDelegate.currentUser
        //let chatMessage1 = MockMessage(text: message.message!, user: currentUser!, messageId: "", date: Date.init())
        //chatMessage.data = message.data ?? ""
        
        self.addMessage(chatMessage: chatMessage)
    }
    
    func onMessagesLoaded(messages: [SBDUserMessage]) {
        convertMessages(messages: messages)
    }
    
    func successfulLeaveChannel() {
    }
    
    func messageSentSuccessfully(chatMessage: ChatMessage, sender: SBDSender) {
        self.addMessage(chatMessage: chatMessage)
    }
    
    private func addMessage(chatMessage: ChatMessage){
        self.chatMessages.append(chatMessage)
        self.messagingView.reloadData()
        scrollToBottom()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
       return self.chatMessages.count
    }

    // There is just one row in every section
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = UIColor.clear
        return headerView
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let current = self.chatMessages[indexPath.section]
        if(current is Int){
            if(current as! Int == 0){
                let cell = tableView.dequeueReusableCell(withIdentifier: "empty", for: indexPath) as! TestCell
                return cell
            }
            else{
                let cell = tableView.dequeueReusableCell(withIdentifier: "empty", for: indexPath) as! TestCell
                return cell
            }
        }
        else{
            let message = current as! ChatMessage
            if(message.senderString == self.currentUser!.uId){
                let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! TestCell
                cell.message.text = message.message
                
                cell.message.layer.masksToBounds = true
                cell.message.layer.cornerRadius = 15
                
                /*cell.message.layer.masksToBounds = false
                cell.message.layer.shadowRadius = 2.0
                cell.message.layer.shadowOpacity = 0.2
                cell.message.layer.shadowOffset = CGSize(width: 1, height: 2)*/
                return cell
            }
            else{
                let cell = tableView.dequeueReusableCell(withIdentifier: "otherCell", for: indexPath) as! TestCell
                cell.message.text = message.message
                
                cell.message.layer.masksToBounds = true
                cell.message.layer.cornerRadius = 15
                
                for friend in currentUser!.friends{
                    if(friend.uid == self.otherUserId){
                        cell.tagLabel.text = "@" + friend.gamerTag
                    }
                }
                
                /*cell.message.layer.masksToBounds = false
                cell.message.layer.shadowRadius = 2.0
                cell.message.layer.shadowOpacity = 0.2
                cell.message.layer.shadowOffset = CGSize(width: 1, height: 2)*/
                return cell
            }
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if self.messagingView.layer.mask == nil {

            //If you are using auto layout
            //self.view.layoutIfNeeded()

            let maskLayer: CAGradientLayer = CAGradientLayer()

            maskLayer.locations = [0.0, 0.2, 0.8, 1.0]
            let width = self.messagingView.frame.size.width
            let height = self.messagingView.frame.size.height
            maskLayer.bounds = CGRect(x: 0.0, y: 0.0, width: width, height: height)
            maskLayer.anchorPoint = CGPoint.zero

            self.messagingView.layer.mask = maskLayer
        }

        scrollViewDidScroll(self.messagingView)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {

        let outerColor = UIColor(white: 1.0, alpha: 0.0).cgColor
        let innerColor = UIColor(white: 1.0, alpha: 1.0).cgColor

        var colors = [CGColor]()

        if scrollView.contentOffset.y + scrollView.contentInset.top <= 0 {
            colors = [innerColor, innerColor, innerColor, outerColor]
        } else if scrollView.contentOffset.y + scrollView.frame.size.height >= scrollView.contentSize.height {
            colors = [outerColor, innerColor, innerColor, innerColor]
        } else {
            colors = [outerColor, innerColor, innerColor, outerColor]
        }

        if let mask = scrollView.layer.mask as? CAGradientLayer {
            mask.colors = colors

            CATransaction.begin()
            CATransaction.setDisableActions(true)
            mask.position = CGPoint(x: 0.0, y: scrollView.contentOffset.y)
            CATransaction.commit()
        }

    }
    
    func scrollToBottom(){
        DispatchQueue.main.async {
            self.messagingView.scrollToRow(at: NSIndexPath(row: 0, section: self.chatMessages.count - 1) as IndexPath, at: .bottom, animated: true)
        }
    }
    
    func searchSubmitted(searchString: String) {
    }
    
    func messageTextSubmitted(string: String, list: [String]?) {
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM.dd.yyyy"
        let result = formatter.string(from: date)
        
        let message = ChatMessage(message: string, timeStamp: result)
        message.senderString = currentUser!.uId
        message.data = currentUser!.uId
        
        manager?.sendMessage(chatMessage: message, list: list)
    }
}
