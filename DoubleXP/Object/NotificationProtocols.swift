//
//  NotificationProtocols.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 11/8/19.
//  Copyright © 2019 Peterson, Toussaint. All rights reserved.
//


import UIKit

protocol NavigateToProfile: class {
    
    func navigateToProfile(uid: String)
    
    func navigateToSearch(game: GamerConnectGame)
    
    func navigateToHome()
    
    func navigateToRequests()
    
    func navigateToMedia()
    
    func navigateToCurrentUserProfile()
    
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
    func updateCell()
    func rivalRequestAlready()
    func rivalRequestSuccess()
    func rivalRequestFail()
    func rivalResponseAccepted()
    func rivalResponseRejected()
    func rivalResponseFailed()
    func friendRemoved()
    func friendRemoveFail()
    func onlineAnnounceSent()
    func onlineAnnounceFail()
    func onFollowSuccess()
    func onFollowBackSuccess()
}

protocol TeamCallbacks: class{
    func updateCell(indexPath: IndexPath)
}

protocol FACallbacks: class{
    func updateCell(indexPath: IndexPath)
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
    func onYoutubeSuccessful(videos: [YoutubeVideoObj])
    func onYoutubeFail()
    func onMutliYoutube(channels: [YoutubeMultiChannelSelection])
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
