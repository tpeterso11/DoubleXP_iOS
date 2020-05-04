//
//  NavigationPageController.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 11/5/19.
//  Copyright © 2019 Peterson, Toussaint. All rights reserved.
//

import UIKit
import EMPageViewController
import SwiftNotificationCenter

class NavigationPageController: EMPageViewController, EMPageViewControllerDataSource, NavigateToProfile {
    
    
    func em_pageViewController(_ pageViewController: EMPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
        return nil
    }
    
    func em_pageViewController(_ pageViewController: EMPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        return nil
    }
    
    fileprivate var items: [UIViewController] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        dataSource = self
        
        let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "gamerConnectFrag") as! GamerConnectFrag

        selectViewController(currentViewController, direction: .forward, animated: false, completion: nil)
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        currentViewController.pageName = "Home"
        currentViewController.navDictionary = ["state": "original"]
        appDelegate.clearAndAddToNavStack(vc: currentViewController)
        appDelegate.currentFrag = currentViewController.pageName ?? "Home"
        
        Broadcaster.register(NavigateToProfile.self, observer: self)
    }
    
    fileprivate func populateItems() {
         let c = GamerConnectFrag()
    
        items.append(c)
    }
    
    func programmaticallyLoad(vc: ParentVC, fragName: String){
        let delegate = UIApplication.shared.delegate as! AppDelegate
        delegate.currentFrag = fragName
        
        delegate.currentLanding?.updateNavigation(currentFrag: vc)
        selectViewController(vc, direction: .reverse, animated: true, completion: nil)
        
        vc.reloadView()
    }
    
    func navigateToProfile(uid: String){
        let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "playerProfile") as! PlayerProfile
        currentViewController.pageName = "Profile"
        currentViewController.navDictionary = ["state": "backOnly"]
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.addToNavStack(vc: currentViewController)
        appDelegate.currentLanding?.stackDepth = appDelegate.navStack.count
        appDelegate.currentLanding?.updateNavigation(currentFrag: currentViewController)
        appDelegate.currentFrag = currentViewController.pageName ?? "Profile"
        appDelegate.currentMediaFrag = nil
        currentViewController.uid = uid
        
        selectViewController(currentViewController, direction: .forward, animated: true, completion: nil)
    }
    
    func navigateToCompetition(competition: CompetitionObj) {
        let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "competition") as! CompetitionFrag
        currentViewController.pageName = "Competition"
        currentViewController.navDictionary = ["state": "backOnly"]
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.addToNavStack(vc: currentViewController)
        appDelegate.currentLanding?.stackDepth = appDelegate.navStack.count
        appDelegate.currentLanding?.updateNavigation(currentFrag: currentViewController)
        appDelegate.currentFrag = currentViewController.pageName ?? "Competition"
        appDelegate.currentMediaFrag = nil
        currentViewController.competition = competition
        
        selectViewController(currentViewController, direction: .forward, animated: true, completion: nil)
    }
    
    func navigateToSponsor() {
        let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "basicSponsor") as! BasicSponsorPage
        currentViewController.pageName = "Basic Sponsor"
        currentViewController.navDictionary = ["state": "backOnly"]
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.addToNavStack(vc: currentViewController)
        appDelegate.currentLanding?.stackDepth = appDelegate.navStack.count
        appDelegate.currentLanding?.updateNavigation(currentFrag: currentViewController)
        appDelegate.currentFrag = currentViewController.pageName ?? "Basic Sponsor"
        appDelegate.currentMediaFrag = nil
        
        selectViewController(currentViewController, direction: .forward, animated: true, completion: nil)
    }
    
    func navigateToSearch(game: GamerConnectGame){
        let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "gamerConnectSearch") as! GamerConnectSearch
        currentViewController.pageName = "GC Search"
        currentViewController.navDictionary = ["state": "search", "searchHint": "Search for player", "searchButton": "Search"]
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.addToNavStack(vc: currentViewController)
        appDelegate.currentLanding?.stackDepth = appDelegate.navStack.count
        appDelegate.currentLanding?.updateNavigation(currentFrag: currentViewController)
        appDelegate.currentFrag = currentViewController.pageName ?? "GC Search"
        currentViewController.game = game
        
        selectViewController(currentViewController, direction: .forward, animated: true, completion: nil)
    }
    
    func navigateToCurrentUserProfile(){
        let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "profile") as! ProfileFrag
        currentViewController.pageName = "Edit Profile"
        currentViewController.navDictionary = ["state": "backOnly"]
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.addToNavStack(vc: currentViewController)
        appDelegate.currentLanding?.stackDepth = appDelegate.navStack.count
        appDelegate.currentLanding?.updateNavigation(currentFrag: currentViewController)
        appDelegate.currentFrag = currentViewController.pageName ?? "Edit Profile"
        
        selectViewController(currentViewController, direction: .forward, animated: true, completion: nil)
    }
    
    func navigateToSettings(){
        let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "settings") as! SettingsFrag
        currentViewController.pageName = "Settings"
        currentViewController.navDictionary = ["state": "backOnly"]
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.addToNavStack(vc: currentViewController)
        appDelegate.currentLanding?.stackDepth = appDelegate.navStack.count
        appDelegate.currentLanding?.updateNavigation(currentFrag: currentViewController)
        appDelegate.currentFrag = currentViewController.pageName ?? "Settings"
        appDelegate.currentMediaFrag = nil
        
        selectViewController(currentViewController, direction: .forward, animated: true, completion: nil)
    }
    
    func navigateToInvite(){
        let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "invite") as! InviteFrag
        currentViewController.pageName = "Invite"
        currentViewController.navDictionary = ["state": "backOnly"]
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.addToNavStack(vc: currentViewController)
        appDelegate.currentLanding?.stackDepth = appDelegate.navStack.count
        appDelegate.currentLanding?.updateNavigation(currentFrag: currentViewController)
        appDelegate.currentFrag = currentViewController.pageName ?? "Invite"
        
        selectViewController(currentViewController, direction: .forward, animated: true, completion: nil)
    }
    
    func navigateToRequests(){
        let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "requests") as! Requests
        currentViewController.pageName = "Requests"
        currentViewController.navDictionary = ["state": "backOnly"]
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.addToNavStack(vc: currentViewController)
        appDelegate.currentLanding?.stackDepth = appDelegate.navStack.count
        appDelegate.currentLanding?.updateNavigation(currentFrag: currentViewController)
        appDelegate.currentFrag = currentViewController.pageName ?? "Requests"
        appDelegate.currentMediaFrag = nil
        
        selectViewController(currentViewController, direction: .forward, animated: true, completion: nil)
    }
    
    func navigateToMedia(){
        let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "mediaFrag") as! MediaFrag
        currentViewController.pageName = "Media"
        currentViewController.navDictionary = ["state": "backOnly"]
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.addToNavStack(vc: currentViewController)
        appDelegate.currentLanding?.stackDepth = appDelegate.navStack.count
        appDelegate.currentLanding?.updateNavigation(currentFrag: currentViewController)
        appDelegate.currentFrag = currentViewController.pageName ?? "Media"
        
        selectViewController(currentViewController, direction: .forward, animated: true, completion: nil)
    }
    
    func navigateToTeams(){
        let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "teamFrag") as! TeamFrag
        currentViewController.pageName = "Teams"
        currentViewController.navDictionary = ["state": "backOnly"]
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.addToNavStack(vc: currentViewController)
        appDelegate.currentLanding?.stackDepth = appDelegate.navStack.count
        appDelegate.currentLanding?.updateNavigation(currentFrag: currentViewController)
        appDelegate.currentFrag = currentViewController.pageName ?? "Teams"
        appDelegate.currentMediaFrag = nil
        
        selectViewController(currentViewController, direction: .forward, animated: true, completion: nil)
    }
    
    func navigateToHome(){
        let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "gamerConnectFrag") as! GamerConnectFrag
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.currentLanding!.checkRivals()
        currentViewController.pageName = "Home"
        currentViewController.navDictionary = ["state": "original"]
        appDelegate.clearAndAddToNavStack(vc: currentViewController)
        appDelegate.currentFrag = currentViewController.pageName ?? "Home"
        appDelegate.currentMediaFrag = nil
        appDelegate.currentLanding!.restoreBottomNav()
        
        selectViewController(currentViewController, direction: .reverse, animated: true, completion: nil)
    }
    
    func navigateToTeamDashboard(team: TeamObject?, newTeam: Bool){
        //change this to go to team needs selection later.
        let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "teamDashboard") as! TeamDashboard
        currentViewController.team = team
        currentViewController.pageName = "Teams Dashboard"
        currentViewController.navDictionary = ["state": "backOnly"]
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.addToNavStack(vc: currentViewController)
        appDelegate.currentLanding?.stackDepth = appDelegate.navStack.count
        appDelegate.currentLanding?.updateNavigation(currentFrag: currentViewController)
        appDelegate.currentFrag = currentViewController.pageName ?? "Team Dashboard"
        
        selectViewController(currentViewController, direction: .forward, animated: true, completion: nil)
    }
    
    func navigateToTeamNeeds(team: TeamObject) {
        let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "teamNeeds") as! TeamNeedsSelection
        currentViewController.team = team
        currentViewController.pageName = "Team Needs"
        currentViewController.navDictionary = ["state": "backOnly"]
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.currentLanding?.updateNavigation(currentFrag: currentViewController)
        appDelegate.currentFrag = currentViewController.pageName ?? "Team Needs"
        appDelegate.currentLanding?.stackDepth += 1
        
        selectViewController(currentViewController, direction: .forward, animated: true, completion: nil)
    }
    
    func navigateToCreateFrag(){
        let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "createFrag") as! CreateTeamFrag
        currentViewController.pageName = "Create"
        currentViewController.navDictionary = ["state": "backOnly"]
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.currentLanding?.updateNavigation(currentFrag: currentViewController)
        appDelegate.currentFrag = currentViewController.pageName ?? "Create"
        appDelegate.currentLanding?.stackDepth += 1
        
        selectViewController(currentViewController, direction: .forward, animated: true, completion: nil)
    }
    
    func navigateToTeamBuild(team: TeamObject){
        let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "teamBuild") as! TeamBuildFrag
        currentViewController.pageName = "Team Build"
        currentViewController.navDictionary = ["state": "backOnly"]
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.addToNavStack(vc: currentViewController)
        appDelegate.currentLanding?.stackDepth = appDelegate.navStack.count
        appDelegate.currentLanding?.updateNavigation(currentFrag: currentViewController)
        appDelegate.currentFrag = currentViewController.pageName ?? "Team Build"
        
        currentViewController.team = team
        
        selectViewController(currentViewController, direction: .forward, animated: true, completion: nil)
    }
    
    func navigateToTeamFreeAgentSearch(team: TeamObject){
        let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "teamFreeAgentSearch") as! TeamBuildFA
        
        currentViewController.pageName = "Team FA Search"
        currentViewController.navDictionary = ["state": "backOnly"]
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.addToNavStack(vc: currentViewController)
        appDelegate.currentLanding?.stackDepth = appDelegate.navStack.count
        appDelegate.currentLanding?.updateNavigation(currentFrag: currentViewController)
        appDelegate.currentFrag = currentViewController.pageName ?? "Team FA Search"
        currentViewController.team = team
        
        selectViewController(currentViewController, direction: .forward, animated: true, completion: nil)
    }
    
    func navigateToTeamFreeAgentResults(team: TeamObject){
        let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "teamFreeAgentResults") as! TeamBuildFAResults
       
        currentViewController.pageName = "Team FA Results"
        currentViewController.navDictionary = ["state": "backOnly"]
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.addToNavStack(vc: currentViewController)
        appDelegate.currentLanding?.stackDepth = appDelegate.navStack.count
        appDelegate.currentLanding?.updateNavigation(currentFrag: currentViewController)
        appDelegate.currentFrag = currentViewController.pageName ?? "Team FA Results"
        currentViewController.team = team
        
        selectViewController(currentViewController, direction: .forward, animated: true, completion: nil)
    }
    
    func navigateToFreeAgentDash(){
        let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "faDash") as! FADash
        currentViewController.pageName = "FA Dash"
        currentViewController.navDictionary = ["state": "backOnly"]
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.addToNavStack(vc: currentViewController)
        appDelegate.currentLanding?.stackDepth = appDelegate.navStack.count
        appDelegate.currentLanding?.updateNavigation(currentFrag: currentViewController)
        appDelegate.currentFrag = currentViewController.pageName ?? "FA Dash"
        
        selectViewController(currentViewController, direction: .forward, animated: true, completion: nil)
    }
    
    func navigateToTeamFreeAgentDash() {
        let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "faDash") as! FADash
        currentViewController.pageName = "FA Dash"
        currentViewController.navDictionary = ["state": "backOnly"]
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.addToNavStack(vc: currentViewController)
        appDelegate.currentLanding?.stackDepth = appDelegate.navStack.count
        appDelegate.currentLanding?.updateNavigation(currentFrag: currentViewController)
        appDelegate.currentFrag = currentViewController.pageName ?? "FA Dash"
        
        selectViewController(currentViewController, direction: .forward, animated: true, completion: nil)
    }
    
    func navigateToViewTeams() {
        let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "viewTeams") as! ViewTeams
        currentViewController.pageName = "View Teams"
        currentViewController.navDictionary = ["state": "search", "searchHint": "Find A Team", "searchButton": "Search"]
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.addToNavStack(vc: currentViewController)
        appDelegate.currentLanding?.stackDepth = appDelegate.navStack.count
        appDelegate.currentLanding?.updateNavigation(currentFrag: currentViewController)
        appDelegate.currentFrag = currentViewController.pageName ?? "View Teams"
        
        selectViewController(currentViewController, direction: .forward, animated: true, completion: nil)
    }
    
    func navigateToTeamFreeAgentFront(){
        let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "faFront") as! FreeAgentFront
        currentViewController.pageName = "FA Front"
        currentViewController.navDictionary = ["state": "backOnly"]
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.currentLanding?.updateNavigation(currentFrag: currentViewController)
        appDelegate.currentFrag = currentViewController.pageName ?? "FA Front"
        
        selectViewController(currentViewController, direction: .forward, animated: true, completion: nil)
    }
    
    func navigateToTeamFreeAgentFront(team: TeamObject?, currentUser: User) {
        let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "faFront") as! FreeAgentFront
        currentViewController.pageName = "FA Front"
        currentViewController.navDictionary = ["state": "backOnly"]
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.addToNavStack(vc: currentViewController)
        appDelegate.currentLanding?.stackDepth = appDelegate.navStack.count
        appDelegate.currentLanding?.updateNavigation(currentFrag: currentViewController)
        appDelegate.currentFrag = currentViewController.pageName ?? "FA Front"
        
        if(team != nil){
            currentViewController.team = team
        }
        currentViewController.user = currentUser
        
        selectViewController(currentViewController, direction: .forward, animated: true, completion: nil)
    }
    
    func navigateToFreeAgentQuiz(team: TeamObject?, gcGame: GamerConnectGame, currentUser: User) {
        let delegate = UIApplication.shared.delegate as! AppDelegate
        delegate.selectedGCGame = gcGame
        
        let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "faQuiz") as! FAQuiz
        currentViewController.pageName = "FA Quiz"
        currentViewController.navDictionary = ["state": "backOnly"]
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.addToNavStack(vc: currentViewController)
        appDelegate.currentLanding?.stackDepth = appDelegate.navStack.count
        appDelegate.currentLanding?.updateNavigation(currentFrag: currentViewController)
        appDelegate.currentFrag = currentViewController.pageName ?? "FA Quiz"
        
        currentViewController.gcGame = gcGame
        currentViewController.user = currentUser
        if(team != nil){
            currentViewController.team = team
        }
        
        selectViewController(currentViewController, direction: .forward, animated: true, completion: nil)
    }
    
    func navigateToTeamFreeAgentQuiz(team: TeamObject?, gcGame: GamerConnectGame, currentUser: User) {
        let delegate = UIApplication.shared.delegate as! AppDelegate
        delegate.selectedGCGame = gcGame
        
        let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "faQuiz") as! FAQuiz
        currentViewController.pageName = "FA Quiz"
        currentViewController.navDictionary = ["state": "backOnly"]
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.addToNavStack(vc: currentViewController)
        appDelegate.currentLanding?.stackDepth = appDelegate.navStack.count
        appDelegate.currentLanding?.updateNavigation(currentFrag: currentViewController)
        appDelegate.currentFrag = currentViewController.pageName ?? "FA Quiz"
        
        currentViewController.gcGame = gcGame
        currentViewController.user = currentUser
        if(team != nil){
            currentViewController.team = team
        }
        
        selectViewController(currentViewController, direction: .forward, animated: true, completion: nil)
    }
    
    func navigateToMessaging(groupChannelUrl: String?, otherUserId: String?){
        let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "messaging") as! MessagingFrag
        let delegate = UIApplication.shared.delegate as! AppDelegate
        
        guard delegate.currentUser != nil else{
            return
        }
        
        currentViewController.pageName = "Messaging"
        currentViewController.navDictionary = ["state": "messaging", "searchHint": "Message this user.", "sendButton": "Send"]
        
        delegate.addToNavStack(vc: currentViewController)
        delegate.currentLanding?.stackDepth = delegate.navStack.count
        delegate.currentLanding?.updateNavigation(currentFrag: currentViewController)
        delegate.currentFrag = currentViewController.pageName ?? "Messaging"
        delegate.currentMediaFrag = nil
        
        currentViewController.currentUser = delegate.currentUser!
        
        if(groupChannelUrl != nil){
            currentViewController.groupChannelUrl = groupChannelUrl
        }
        
        if(otherUserId != nil){
            currentViewController.otherUserId = otherUserId
        }
    
        selectViewController(currentViewController, direction: .forward, animated: true, completion: nil)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = items.index(of: viewController) else {
            return nil
        }
        
        let previousIndex = viewControllerIndex - 1
        
        guard previousIndex >= 0 else {
            return items.last
        }
        
        guard items.count > previousIndex else {
            return nil
        }
        
        return items[previousIndex]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = items.index(of: viewController) else {
            return nil
        }
        
        let nextIndex = viewControllerIndex + 1
        guard items.count != nextIndex else {
            return items.first
        }
        
        guard items.count > nextIndex else {
            return nil
        }
        
        return items[nextIndex]
    }
    
    func goBack() {
        self.scrollReverse(animated: true, completion: nil)
    }
    
     func removeBottomNav(showNewNav: Bool, hideSearch: Bool, searchHint: String?, searchButtonText: String?, isMessaging: Bool) {
    }
    
    func updateNavigation(currentFrag: ParentVC) {
    }
    
    
    
}
