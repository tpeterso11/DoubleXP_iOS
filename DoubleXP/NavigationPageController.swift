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
import MessageKit

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
        
        Broadcaster.register(NavigateToProfile.self, observer: self)
        
        
    }
    
    fileprivate func populateItems() {
         let c = GamerConnectFrag()
    
        items.append(c)
    }
    
    func programmaticallyLoad(vc: UIViewController, fragName: String){
        let delegate = UIApplication.shared.delegate as! AppDelegate
        delegate.currentFrag = fragName
        
        selectViewController(vc, direction: .forward, animated: true, completion: nil)
    }
    
    func navigateToProfile(uid: String){
        let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "playerProfile") as! PlayerProfile
        
        currentViewController.uid = uid
        
        selectViewController(currentViewController, direction: .forward, animated: true, completion: nil)
    }
    
    func navigateToSearch(game: GamerConnectGame){
        let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "gamerConnectSearch") as! GamerConnectSearch
        
        currentViewController.game = game
        
        selectViewController(currentViewController, direction: .forward, animated: true, completion: nil)
    }
    
    func navigateToCurrentUserProfile(){
        let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "profile") as! ProfileFrag
        
        selectViewController(currentViewController, direction: .forward, animated: true, completion: nil)
    }
    
    func navigateToRequests(){
        let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "requests") as! Requests
        
        selectViewController(currentViewController, direction: .forward, animated: true, completion: nil)
    }
    
    func navigateToMedia(){
        let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "mediaFrag") as! MediaFrag
        
        selectViewController(currentViewController, direction: .forward, animated: true, completion: nil)
    }
    
    func navigateToTeams(){
        let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "teamFrag") as! TeamFrag
        
        selectViewController(currentViewController, direction: .forward, animated: true, completion: nil)
    }
    
    func navigateToHome(){
        let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "gamerConnectFrag") as! GamerConnectFrag
        
        selectViewController(currentViewController, direction: .reverse, animated: true, completion: nil)
    }
    
    func navigateToTeamDashboard(team: TeamObject, newTeam: Bool){
        //change this to go to team needs selection later.
        let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "teamDashboard") as! TeamDashboard
        currentViewController.team = team
        
        selectViewController(currentViewController, direction: .forward, animated: true, completion: nil)
    }
    
    func navigateToTeamNeeds(team: TeamObject) {
        let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "teamNeeds") as! TeamNeedsSelection
        currentViewController.team = team
        
        selectViewController(currentViewController, direction: .forward, animated: true, completion: nil)
    }
    
    func navigateToCreateFrag(){
        let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "createFrag") as! CreateTeamFrag
        
        selectViewController(currentViewController, direction: .forward, animated: true, completion: nil)
    }
    
    func navigateToTeamBuild(team: TeamObject){
        let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "teamBuild") as! TeamBuildFrag
        
        currentViewController.team = team
        
        selectViewController(currentViewController, direction: .forward, animated: true, completion: nil)
    }
    
    func navigateToTeamFreeAgentSearch(team: TeamObject){
        let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "teamFreeAgentSearch") as! TeamBuildFA
        
        currentViewController.team = team
        
        selectViewController(currentViewController, direction: .forward, animated: true, completion: nil)
    }
    
    func navigateToTeamFreeAgentResults(team: TeamObject){
        let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "teamFreeAgentResults") as! TeamBuildFAResults
        
        currentViewController.team = team
        
        selectViewController(currentViewController, direction: .forward, animated: true, completion: nil)
    }
    
    func navigateToFreeAgentDash(){
        let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "faDash") as! FADash
        
        selectViewController(currentViewController, direction: .forward, animated: true, completion: nil)
    }
    
    func navigateToTeamFreeAgentDash() {
        let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "faDash") as! FADash
        
        selectViewController(currentViewController, direction: .forward, animated: true, completion: nil)
    }
    
    func navigateToViewTeams() {
        let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "viewTeams") as! ViewTeams
        
        selectViewController(currentViewController, direction: .forward, animated: true, completion: nil)
    }
    
    func navigateToTeamFreeAgentFront(){
        let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "faFront") as! FreeAgentFront
               
        selectViewController(currentViewController, direction: .forward, animated: true, completion: nil)
    }
    
    func navigateToTeamFreeAgentFront(team: TeamObject?, currentUser: User) {
        let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "faFront") as! FreeAgentFront
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
}
