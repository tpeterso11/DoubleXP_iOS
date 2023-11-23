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
    
    func navigateToMessaging(groupChannelUrl: String?, otherUserId: String?) {
        
    }
    
    
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
        
        let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "gamerConnectFrag") as! Feed

        selectViewController(currentViewController, direction: .forward, animated: false, completion: nil)
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        currentViewController.pageName = "Home"
        currentViewController.navDictionary = ["state": "original"]
        appDelegate.clearAndAddToNavStack(vc: currentViewController)
        appDelegate.currentFrag = currentViewController.pageName ?? "Home"
        
        Broadcaster.register(NavigateToProfile.self, observer: self)
    }
    
    fileprivate func populateItems() {
         let c = Feed()
    
        items.append(c)
    }
    
    func programmaticallyLoad(vc: ParentVC, fragName: String){
        let delegate = UIApplication.shared.delegate as! AppDelegate
        delegate.currentFrag = fragName
        
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
        appDelegate.currentFrag = currentViewController.pageName ?? "Profile"
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
        appDelegate.currentFrag = currentViewController.pageName ?? "Competition"
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
        appDelegate.currentFrag = currentViewController.pageName ?? "Basic Sponsor"
        
        selectViewController(currentViewController, direction: .forward, animated: true, completion: nil)
    }
    
    func navigateToSearch(game: GamerConnectGame){
        let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "gamerConnectSearch") as! GamerConnectSearch
        currentViewController.pageName = "GC Search"
        currentViewController.navDictionary = ["state": "search", "searchHint": "search for player", "searchButton": "search"]
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.addToNavStack(vc: currentViewController)
        appDelegate.currentLanding?.stackDepth = appDelegate.navStack.count
        appDelegate.currentFrag = currentViewController.pageName ?? "GC Search"
        currentViewController.game = game
        
        selectViewController(currentViewController, direction: .forward, animated: true, completion: nil)
    }
    
    func navigateToCurrentUserProfile(){
        let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "profile") as! ProfileFrag
        currentViewController.pageName = "Edit Profile"
        currentViewController.navDictionary = ["state": "none"]
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.addToNavStack(vc: currentViewController)
        appDelegate.currentLanding?.stackDepth = appDelegate.navStack.count
        appDelegate.currentFrag = currentViewController.pageName ?? "Edit Profile"
        
        selectViewController(currentViewController, direction: .forward, animated: true, completion: nil)
    }
    
    func navigateToSettings(){
        let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "settings") as! SettingsFrag
        currentViewController.pageName = "Settings"
        currentViewController.navDictionary = ["state": "none"]
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.addToNavStack(vc: currentViewController)
        appDelegate.currentLanding?.stackDepth = appDelegate.navStack.count
        appDelegate.currentFrag = currentViewController.pageName ?? "Settings"
        
        selectViewController(currentViewController, direction: .forward, animated: true, completion: nil)
    }
    
    func navigateToInvite(){
        let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "invite") as! InviteFrag
        currentViewController.pageName = "Invite"
        currentViewController.navDictionary = ["state": "backOnly"]
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.addToNavStack(vc: currentViewController)
        appDelegate.currentLanding?.stackDepth = appDelegate.navStack.count
        appDelegate.currentFrag = currentViewController.pageName ?? "Invite"
        
        selectViewController(currentViewController, direction: .forward, animated: true, completion: nil)
    }
    
    func navigateToRequests(){
        let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "requests") as! Requests
        currentViewController.pageName = "Requests"
        currentViewController.navDictionary = ["state": "none"]
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.addToNavStack(vc: currentViewController)
        appDelegate.currentLanding?.stackDepth = appDelegate.navStack.count
        appDelegate.currentFrag = currentViewController.pageName ?? "Requests"
        
        selectViewController(currentViewController, direction: .forward, animated: true, completion: nil)
    }
    
    func navigateToMedia(){
        /*let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "mediaFrag") as! MediaFrag
        currentViewController.pageName = "Media"
        currentViewController.navDictionary = ["state": "none"]
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.addToNavStack(vc: currentViewController)
        appDelegate.currentLanding?.stackDepth = appDelegate.navStack.count
        appDelegate.currentFrag = currentViewController.pageName ?? "Media"
        
        selectViewController(currentViewController, direction: .forward, animated: true, completion: nil)*/
    }
    
    func navigateToHome(){
        let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "gamerConnectFrag") as! Feed
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.currentLanding!.checkRivals()
        currentViewController.pageName = "Home"
        currentViewController.navDictionary = ["state": "none"]
        appDelegate.clearAndAddToNavStack(vc: currentViewController)
        appDelegate.currentFrag = currentViewController.pageName ?? "Home"
        
        selectViewController(currentViewController, direction: .reverse, animated: true, completion: nil)
    }
    
    func navigateToFreeAgentQuiz(team: TeamObject?, gcGame: GamerConnectGame, currentUser: User) {
        let delegate = UIApplication.shared.delegate as! AppDelegate
        delegate.selectedGCGame = gcGame
        
        let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "faQuiz") as! FAQuiz
        currentViewController.pageName = "FA Quiz"
        currentViewController.navDictionary = ["state": "none"]
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.currentFrag = currentViewController.pageName ?? "FA Quiz"
        appDelegate.currentLanding?.stackDepth += 1
        
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
        currentViewController.navDictionary = ["state": "none"]
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.currentFrag = currentViewController.pageName ?? "FA Quiz"
        appDelegate.currentLanding?.stackDepth += 1
        
        currentViewController.gcGame = gcGame
        currentViewController.user = currentUser
        if(team != nil){
            currentViewController.team = team
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
    
    func startDashNavigation(teamName: String?, teamInvite: TeamInviteObject?, newTeam: Bool) {
    }
    
}
