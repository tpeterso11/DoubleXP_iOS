//
//  NotificationProtocols.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 11/8/19.
//  Copyright © 2019 Peterson, Toussaint. All rights reserved.
//

import UIKit
import SendBirdSDK

protocol NavigateToProfile: class {
    
    func navigateToProfile(uid: String)
    
    func navigateToSearch(game: GamerConnectGame)
    
    func navigateToHome()
    
    func navigateToTeams()
    
    func navigateToRequests()
    
    func navigateToCreateFrag()
    
    func navigateToTeamDashboard(team: TeamObject, newTeam: Bool)
    
    func navigateToTeamNeeds(team: TeamObject)
    
    func navigateToTeamBuild(team: TeamObject)
    
    func navigateToTeamFreeAgentSearch(team: TeamObject)
    
    func navigateToTeamFreeAgentResults(team: TeamObject)
    
    func navigateToTeamFreeAgentDash()
    
    func navigateToTeamFreeAgentFront()
    
    func navigateToViewTeams()
    
    func navigateToMedia()
    
    func navigateToCurrentUserProfile()
    
    func navigateToMessaging(groupChannelUrl: String?, otherUserId: String?)
    
    func navigateToFreeAgentQuiz(team: TeamObject?, gcGame: GamerConnectGame, currentUser: User)
    
    func removeBottomNav(showNewNav: Bool, hideSearch: Bool, searchHint: String?, searchButtonText: String?, isMessaging: Bool)
    
    func goBack()
    
    func programmaticallyLoad(vc: ParentVC, fragName: String)
    
    func updateNavigation(currentFrag: ParentVC)
}

protocol RequestsUpdate: class{
    func updateCell(indexPath: IndexPath)
}

protocol TeamCallbacks: class{
    func updateCell(indexPath: IndexPath)
}

protocol FACallbacks: class{
    func updateCell(indexPath: IndexPath)
}

protocol MessagingCallbacks: class {
    func connectionSuccessful()
    func createTeamChannelSuccessful(groupChannel: SBDGroupChannel)
    func messageSuccessfullyReceived(message: SBDUserMessage)
    func onMessagesLoaded(messages: [SBDUserMessage])
    func successfulLeaveChannel()
    func messageSentSuccessfully(chatMessage: ChatMessage, sender: SBDSender)
}

protocol TeamInteractionCallbacks: class{
    func successfulRequest(indexPath: IndexPath)
    func failedRequest(indexPath: IndexPath)
}

protocol FreeAgentQuizNav: class {
    func addQuestion(question: FAQuestion)
    
    func updateAnswer(answer: String, question: FAQuestion)
    
    func onInitialQuizLoaded()
    
    func showConsoles()
    
    func showComplete()
    
    func showSubmitted()
    
    func showEmpty()
}

protocol BackHandler: class{
    func backPressed(previousVH: String)
}

protocol SearchCallbacks: class{
    func searchSubmitted(searchString: String)
    
    func messageTextSubmitted(string: String, list: [String]?)
}

protocol ProfileCallbacks: class{
    func onFriendAdded()
    
    func onFriendDeclined()
}

protocol SocialMediaManagerCallback: class {
    func onTweetsLoaded(tweets: [TweetObject])
    func onStreamsLoaded(streams: [TwitchStreamObject])
}

protocol LandingMenuCallbacks: class{
    func menuNavigateToMessaging(uId: String)
    func menuNavigateToProfile(uId: String)
}

protocol MediaCallbacks: class{
    func onReviewsReceived(payload: [NewsObject])
    func onMediaReceived(category: String)
    
    func onVideoLoaded(url: String)
}

protocol LandingUICallbacks: class{
    func updateNavColor(color: UIColor)
}

protocol CurrentProfileCallbacks: class{
    func checkChanges(updatedList: [GamerConnectGame]?)
    func changesComplete()
}

