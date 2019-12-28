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

class MessagingFrag: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, MessagingCallbacks {
    var currentUser: User?
    var groupChannelUrl: String?
    var manager: MessagingManager?
    var otherUserId: String?
    var chatMessages = [ChatMessage]()
    var mentionedUsers = [String]()

    @IBOutlet weak var messagingView: UICollectionView!
    @IBOutlet weak var textEntry: UITextField!
    @IBOutlet weak var sendButton: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        manager = MessagingManager()
        manager!.setup(sendBirdId: currentUser!.sendBirdId, currentUser: currentUser!)
        
        sendButton.addTarget(self, action: #selector(sendButtonClicked), for: .touchUpInside)
    }
    
    @objc func sendButtonClicked(_ sender: AnyObject?) {
        if(!textEntry.text!.isEmpty){
            let date = Date()
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM.dd.yyyy"
            let result = formatter.string(from: date)
            
            let chatMessage = ChatMessage(message: textEntry.text!, timeStamp: result)
            chatMessage.data = currentUser?.uId ?? ""
           
            manager!.sendMessage(chatMessage: chatMessage, list: self.mentionedUsers)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return chatMessages.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let currentMessage = chatMessages[indexPath.item]
        
        if(currentMessage.sender.userId == currentUser!.uId){
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "userCell", for: indexPath) as! UserChatBubble
            cell.message.text = currentMessage.message
            cell.timestamp.text = currentMessage.timeStamp
            
            return cell
        }
        else{
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "otherCell", for: indexPath) as! OtherChatBubble
            cell.message.text = currentMessage.message
            cell.timestamp.text = currentMessage.timeStamp
            
            return cell
        }
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
        let ref = Database.database().reference().child("Users").child(currentUser!.uId)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            if(snapshot.exists()){
                var array = [ChatObject]()
                let messagingArray = snapshot.childSnapshot(forPath: "sent_requests")
                for channel in messagingArray.children{
                    let currentObj = channel as! DataSnapshot
                    let dict = currentObj.value as! [String: Any]
                    let channelUrl = dict["channelUrl"] as? String ?? ""
                    let otherUser = dict["otherUser"] as? String ?? ""
                    
                    let chatObj = ChatObject(chatUrl: channelUrl, otherUser: otherUser)
                    array.append(chatObj)
                }
                
                if(!array.isEmpty){
                    var contained = false
                    for object in array{
                        if(object.otherUser == self.otherUserId){
                            self.manager?.loadGroupChannel(channelUrl: object.chatUrl, team: false)
                            contained = true
                            break
                        }
                    }
                    
                    if(!contained){
                        self.manager?.createTeamChannel(userId: self.currentUser!.uId, callbacks: self)
                    }
                }
                else{
                    self.manager?.createTeamChannel(userId: self.currentUser!.uId, callbacks: self)
                }
            }
            
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
    private func convertMessages(messages: [SBDUserMessage]){
        chatMessages = [ChatMessage]()
        for message in messages{
            let date = NSDate(timeIntervalSince1970: TimeInterval(message.createdAt))
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM.dd.yyyy"
            let result = formatter.string(from: date as Date)
            
            let chatMessage = ChatMessage(message: message.message!, timeStamp: result)
            chatMessage.data = message.data ?? ""
            
            //if(message.mentionedUsers != nil){
            //    chatMessage.mentionedUsers = message.mentionedUsers!
            //}
            
            chatMessages.append(chatMessage)
        }
        
        messagingView.delegate = self
        messagingView.dataSource = self
    }
    
    func createTeamChannelSuccessful(groupChannel: SBDGroupChannel) {
    }
    
    func messageSuccessfullyReceived(message: SBDUserMessage) {
        let date = NSDate(timeIntervalSince1970: TimeInterval(message.createdAt))
                   let formatter = DateFormatter()
                   formatter.dateFormat = "MMMM.dd.yyyy"
                   let result = formatter.string(from: date as Date)
        
        let chatMessage = ChatMessage(message: message.message!, timeStamp: result)
        chatMessage.data = message.data ?? ""
        
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
    }
}
