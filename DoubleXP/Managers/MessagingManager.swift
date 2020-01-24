//
//  MessagingManager.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 11/22/19.
//  Copyright © 2019 Peterson, Toussaint. All rights reserved.
//

import Foundation
import UIKit
import Firebase
import SendBirdSDK

class MessagingManager: UIViewController, SBDConnectionDelegate, SBDUserEventDelegate, SBDChannelDelegate {
    private var sendbirdId: String?
    private var currentUser: User?
    private var currentChannel: SBDGroupChannel?
    var messagingCallbacks: MessagingCallbacks?
    
    func setup(sendBirdId: String?, currentUser: User){
        self.sendbirdId = sendBirdId
        self.currentUser = currentUser
        
        SBDMain.initWithApplicationId("B1CA477B-83D6-40D9-A8BB-10C959689426")
        SBDMain.connect(withUserId: currentUser.uId, completionHandler: { (user, error) in
            guard error == nil else {   // Error.
                return
            }
            
            if(sendBirdId != nil){
                if((user?.metaData?["accepted"]) == "false" || ((user?.metaData?["accepted"]) != nil)){
                    self.updateMeta(user: user, key: "accepted", value: "true")
                }
                else{
                    self.messagingCallbacks!.connectionSuccessful()
                }
            }
            else{
                let ref = Database.database().reference().child("Users").child(currentUser.uId)
                ref.observeSingleEvent(of: .value, with: { (snapshot) in
                    if(snapshot.exists()){
                        ref.child("sendBirdId").setValue(currentUser.uId)
                        self.setupUserMeta(user: user)
                    }
                    
                }) { (error) in
                    print(error.localizedDescription)
                }
            }
        })
    }
    
    private func setupUserMeta(user: SBDUser?){
        let manager = GamerProfileManager()
        
        let data = [
            "gamerTag": manager.getGamerTag(user: currentUser!),
            "accepted": "true"
        ]
        
        user!.createMetaData(data) { (metaData, error) in
            guard error == nil else {   // Error.
                return
            }
            
            self.currentUser?.sendBirdId = user!.userId
            self.messagingCallbacks!.connectionSuccessful()
        }
    }
    
    
    private func updateMeta(user: SBDUser?, key: String, value: String){
        let data = [
            key: value
        ]
        
        user!.updateMetaData(data) { (metaData, error) in
            guard error == nil else {   // Error.
                return
            }
            
            self.currentUser?.sendBirdId = user!.userId
            self.messagingCallbacks!.connectionSuccessful()
        }
    }
    
    func createTeamChannel(userId: String, callbacks: MessagingCallbacks){
        let params = SBDGroupChannelParams()
        params.addUserId(userId)
        params.isDistinct = false
        params.isPublic = true
        
        SBDGroupChannel.createChannel(with: params) { (groupChannel, error) in
            guard error == nil else {   // Error.
                return
            }
            
            self.currentChannel = groupChannel
            callbacks.createTeamChannelSuccessful(groupChannel: self.currentChannel!)
        }
    }
    
    func loadGroupChannel(channelUrl: String, team: Bool){
        SBDGroupChannel.getWithUrl(channelUrl) { (groupChannel, error) in
            guard error == nil else {   // Error.
                return
            }

            self.currentChannel = groupChannel
            SBDMain.add(self as SBDChannelDelegate, identifier: "CHANNEL_HANDLER")
            
            if(team){
                //register push notifications
            }
            
            self.loadGroupMessages(groupChannel: self.currentChannel!)
        }
    }
    
    private func loadGroupMessages(groupChannel: SBDGroupChannel){
        let previousMessageQuery = groupChannel.createPreviousMessageListQuery()
        
        previousMessageQuery?.loadPreviousMessages(withLimit: 50, reverse: false, completionHandler: { (messages, error) in
            guard error == nil else {   // Error.
                return
            }
            
            self.messagingCallbacks!.onMessagesLoaded(messages: messages as! [SBDUserMessage])
        })
    }
    
    func leaveGroupChannelPermanent(){
        currentChannel?.leave { (error) in
            guard error == nil else {   // Error.
                return
            }
            
            self.messagingCallbacks?.successfulLeaveChannel()
        }
    }
    
    func sendMessage(chatMessage: ChatMessage, list: [String]?){
        var params = SBDUserMessageParams(message: chatMessage.message)
        params!.message = chatMessage.message
        params!.data = chatMessage.data
        
        if(list != nil){
            params!.mentionedUserIds = list
        }
        
        currentChannel?.sendUserMessage(with: params!) { (userMessage, error) in
            guard error == nil else {   // Error.
                return
            }
            
            self.messagingCallbacks!.messageSentSuccessfully(chatMessage: chatMessage, sender: userMessage!.sender!)
        }
        
    }
    
    func channel(_ sender: SBDBaseChannel, didReceive message: SBDBaseMessage) {
        self.messagingCallbacks!.messageSuccessfullyReceived(message: message as! SBDUserMessage)
    }
    
    func channel(_ channel: SBDBaseChannel, didReceiveMention message: SBDBaseMessage) {
    }
    
    /*
     fun leaveGroupChannel(){
         OpenChannel.getChannel(currentGroupChannel.url, OpenChannel.OpenChannelGetHandler { openChannel, e ->
             if (e != null) {    // Error.
                 return@OpenChannelGetHandler
             }

             openChannel.exit(OpenChannel.OpenChannelExitHandler { e ->
                 if (e != null) {    // Error.
                     return@OpenChannelExitHandler
                 }
                 else{
                     SendBird.disconnect {
                         //disconnect
                     }
                 }
             })
         })
     }

     fun sendMessageGroup(chatMessage: ChatMessage, list: ArrayList<String>?){
         val params = UserMessageParams()
         params.setMessage(chatMessage.message)
         params.setData(chatMessage.data)
         list?.let { params.setMentionedUserIds(it) }
         currentGroupChannel.sendUserMessage(params, object: BaseChannel.SendUserMessageHandler{
             override fun onSent(userMessage: UserMessage?, e: SendBirdException?) {
                 if(e != null)
                 {
                     callbacks.alertMessageSendError(e.message!!)
                 }
                 else {
                     if (userMessage != null)
                     {
                         callbacks.messageSentSuccessfully(chatMessage, userMessage.sender)
                     }
                 }
             }

         })
     }
     
     fun loadGroupChannel(channelUrl: String, team: Boolean){
         GroupChannel.getChannel(channelUrl) { groupChannel, e ->
             if (e != null)
             {
                 callbacks.alertErrorEnteringChannel(e.message!!)
             }
             else
             {
                 currentGroupChannel = groupChannel

                 SendBird.addChannelHandler(CHANNEL_HANDLER_ID, object: SendBird.ChannelHandler()
                 {
                     override fun onTypingStatusUpdated(channel: GroupChannel?)
                     {
                         super.onTypingStatusUpdated(channel)
                     }



                     override fun onMessageReceived(p0: BaseChannel?, message: BaseMessage?) {
                         callbacks.messageSuccessfullyReceived(message as UserMessage)
                     }

                 })

                 if(team) {
                     SendBird.setPushTriggerOption(SendBird.PushTriggerOption.MENTION_ONLY, object : SendBird.SetPushTriggerOptionHandler {
                         override fun onResult(e: SendBirdException?) {
                             e?.let {
                                 return
                             }
                         }
                     })
                 }
                 else{
                     SendBird.setPushTriggerOption(SendBird.PushTriggerOption.ALL, object: SendBird.SetPushTriggerOptionHandler{
                         override fun onResult(e: SendBirdException?) {
                             e?.let {
                                 return
                             }
                         }
                     })
                 }

                 loadGroupMessages(currentGroupChannel)
                 callbacks.onGroupChannelLoaded(currentGroupChannel)
                 var channelMember = false
                 for(member: Member in groupChannel.members){
                     if(currentUser.uid == member.userId){
                         channelMember = true
                     }
                 }
                 if(!channelMember) {
                     currentGroupChannel.join(GroupChannel.GroupChannelJoinHandler { e ->
                         if (e != null) {    // Error.
                             callbacks.alertErrorEnteringChannel(e.message!!)
                         }
                         else{
                             loadGroupMessages(currentGroupChannel)
                             callbacks.onGroupChannelLoaded(currentGroupChannel)
                         }
                     })
                 }
                 else{
                     loadGroupMessages(currentGroupChannel)
                     callbacks.onGroupChannelLoaded(currentGroupChannel)
                 }
             }
         }
     }

     private fun loadGroupMessages(groupChannel: GroupChannel){
         val prevMessageListQuery = groupChannel.createPreviousMessageListQuery()
         prevMessageListQuery.load(50, false, PreviousMessageListQuery.MessageListQueryResult { messages, e ->
             if (e != null) {    // Error.
                 callbacks.alertErrorLoadingMessages(e.message!!)
             }
             else{
                 val count = groupChannel.memberCount
                 callbacks.messagesLoaded(messages)
             }
         })
     }

     fun registerTokenWithSendbird(){
         FirebaseInstanceId.getInstance().instanceId.addOnSuccessListener(activity, OnSuccessListener<InstanceIdResult> { instanceIdResult ->
             SendBird.registerPushTokenForCurrentUser(instanceIdResult.token, SendBird.RegisterPushTokenWithStatusHandler { status, e ->
                 if (e != null) {        // Error.
                     activity.gameTerminalApplication.logger.logEvent("FAILED SENDBIRD TOKEN")
                     callbacks.onMessagingNotificationsOff()
                 }
                 else{
                     Log.d("tpt","TOKEN SENT TO SENDBIRD")
                     activity.gameTerminalApplication.logger.logEvent("SENDBIRD TOKEN SENT")
                     callbacks.onMessagingNotificationsOn()
                 }
             })
         })
     }

     fun unregisterToken(){
         FirebaseInstanceId.getInstance().instanceId.addOnSuccessListener(activity, OnSuccessListener<InstanceIdResult> { instanceIdResult ->
             SendBird.unregisterPushTokenForCurrentUser(instanceIdResult.token, SendBird.UnregisterPushTokenHandler { e ->
                     if (e != null) {    // Error.
                         return@UnregisterPushTokenHandler
                     }
                     else{
                         callbacks.onMessagingNotificationsOff()
                     }
                 }
             )
         })
     }
     */
}