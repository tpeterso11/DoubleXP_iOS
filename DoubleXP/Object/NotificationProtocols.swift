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
    
    func navigateToTeamDashboard(team: TeamObject?, teamInvite: TeamInviteObject?, newTeam: Bool)
    
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
    
    func navigateToInvite()
    
    func navigateToSettings()
    
    func navigateToCompetition(competition: CompetitionObj)
    
    func navigateToSponsor()
    
    func startDashNavigation(teamName: String?, teamInvite: TeamInviteObject?, newTeam: Bool)
}

protocol RequestsUpdate: class{
    func updateCell(indexPath: IndexPath)
    func showQuizClicked(questions: [[String]])
    func rivalRequestAlready()
    func rivalRequestSuccess()
    func rivalRequestFail()
    func rivalResponseAccepted(indexPath: IndexPath)
    func rivalResponseRejected(indexPath: IndexPath)
    func rivalResponseFailed()
    func friendRemoved()
    func friendRemoveFail()
    func onlineAnnounceSent()
    func onlineAnnounceFail()
}

protocol TeamCallbacks: class{
    func updateCell(indexPath: IndexPath)
}

protocol FACallbacks: class{
    func updateCell(indexPath: IndexPath)
}

protocol MessagingCallbacks: class {
    func connectionSuccessful()
    func connectionFailed()
    func createTeamChannelSuccessful(groupChannel: SBDGroupChannel)
    func messageSuccessfullyReceived(message: SBDUserMessage)
    func onMessagesLoaded(messages: [SBDUserMessage])
    func successfulLeaveChannel()
    func messageSentSuccessfully(chatMessage: ChatMessage, sender: SBDSender)
    func createTeamChannelFailed()
    func errorLoadingMessages()
    func errorLoadingChannel()
}

protocol TeamInteractionCallbacks: class{
    func successfulRequest(indexPath: IndexPath)
    func failedRequest(indexPath: IndexPath)
}

protocol FreeAgentQuizNav: class {
    func addQuestion(question: FAQuestion, interviewManager: InterviewManager)
    
    func updateAnswer(answer: String, question: FAQuestion)
    
    func updateAnswerArray(answerArray: [String], question: FAQuestion)
    
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
    
    func onFriendRequested()
}

protocol SocialMediaManagerCallback: class {
    func onTweetsLoaded(tweets: [TweetObject])
    func onStreamsLoaded(streams: [TwitchStreamObject])
    func onChannelsLoaded(channels: [Any])
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
    func changesComplete()
}

protocol StatsManagerCallbacks: class{
    func onSuccess(gameName: String)
    func onFailure(gameName: String)
}

protocol SearchManagerCallbacks: class{
    func onSuccess(returnedUsers: [User])
    func onFailure()
}

protocol DiscoverCallbacks: class{
    func onSuccess(discoverPayload: [Int: Any])
    func onFailure()
}

protocol TodayCallbacks: class{
    func onSuccess()
    func onSuccessShort()
    func onRecommendedUsersLoaded()
}
