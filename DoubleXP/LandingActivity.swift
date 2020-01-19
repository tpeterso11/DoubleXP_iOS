//
//  LandingActivity.swift
//  DoubleXP
//
//  Created by Peterson, Toussaint on 4/17/19.
//  Copyright © 2019 Peterson, Toussaint. All rights reserved.
//

import UIKit
import SwiftHTTP
import ImageLoader
import SwiftNotificationCenter

protocol Profile {
    func goToProfile()
}

class LandingActivity: UIViewController, EMPageViewControllerDelegate, NavigateToProfile, SearchCallbacks {
    @IBOutlet weak var navigationView: UIView!
    @IBOutlet weak var navContainer: UIView!
    @IBOutlet weak var teamButton: UIImageView!
    @IBOutlet weak var homeButton: UIImageView!
    @IBOutlet weak var requestButton: UIImageView!
    @IBOutlet weak var bottomNav: UIView!
    @IBOutlet weak var mainNavView: UIView!
    @IBOutlet weak var secondaryNv: UIView!
    @IBOutlet weak var requests: UIImageView!
    @IBOutlet weak var connect: UIImageView!
    @IBOutlet weak var team: UIImageView!
    @IBOutlet weak var bottomNavBack: UIImageView!
    @IBOutlet weak var bottomNavSearch: UITextField!
    @IBOutlet weak var primaryBack: UIImageView!
    @IBOutlet weak var searchButton: UIButton!
    //@IBOutlet weak var newNav: UIView!
    
    @IBOutlet weak var mainNavCollection: UICollectionView!
    private var requestsAdded = false
    private var teamFragAdded = false
    private var profileAdded = false
    private var homeAdded = false
    private var isSecondaryNavShowing = false
    var stackDepth = 0
    var searchShowing = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        enableButtons()
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.currentLanding = self
        
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(backButtonClicked))
        bottomNavBack.isUserInteractionEnabled = true
        bottomNavBack.addGestureRecognizer(singleTap)
        
        let singleTap2 = UITapGestureRecognizer(target: self, action: #selector(backButtonClicked))
        primaryBack.isUserInteractionEnabled = true
        primaryBack.addGestureRecognizer(singleTap2)
        
        searchButton.addTarget(self, action: #selector(searchClicked), for: .touchUpInside)
        stackDepth = appDelegate.navStack.count
    }
    
    @objc func searchClicked(_ sender: AnyObject?) {
        if(!bottomNavSearch.text!.isEmpty){
            Broadcaster.notify(SearchCallbacks.self) {
                $0.searchSubmitted(searchString: bottomNavSearch.text!)
            }
        }
    }
    
    @objc func backButtonClicked(_ sender: AnyObject?) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        var stack = appDelegate.navStack
        stackDepth -= 1
        
        if(!stack.isEmpty){
            Broadcaster.notify(NavigateToProfile.self) {
                let vc = stack[self.stackDepth - 1] as! ParentVC
                $0.programmaticallyLoad(vc: stack[self.stackDepth - 1], fragName: vc.pageName!)
            }
            
            if(stack.count > 1){
                stack.removeLast()
            }
            
            if(stack.count == 1){
                restoreBottomNav()
            }
        }
        
        appDelegate.navStack = stack
    }
    
    func navigateToProfile(uid: String){
        stackDepth += 1
        Broadcaster.notify(NavigateToProfile.self) {
            $0.navigateToProfile(uid: uid)
        }
    }
    
    func navigateToRequests(){
        stackDepth += 1
        Broadcaster.notify(NavigateToProfile.self) {
            $0.navigateToRequests()
        }
    }
    
    func navigateToHome(){
        Broadcaster.notify(NavigateToProfile.self) {
            $0.navigateToHome()
        }
    }
    
    func navigateToTeams() {
        stackDepth += 1
       Broadcaster.notify(NavigateToProfile.self) {
           $0.navigateToTeams()
       }
    }
    
    func navigateToSearch(game: GamerConnectGame){
        stackDepth += 1
        Broadcaster.notify(NavigateToProfile.self) {
            $0.navigateToSearch(game: game)
        }
    }
    
    func navigateToCreateFrag() {
        stackDepth += 1
        Broadcaster.notify(NavigateToProfile.self) {
            $0.navigateToCreateFrag()
        }
    }
    
    func navigateToTeamDashboard(team: TeamObject, newTeam: Bool) {
        stackDepth += 1
        Broadcaster.notify(NavigateToProfile.self) {
            $0.navigateToTeamDashboard(team: team, newTeam: newTeam)
        }
    }
    
    func navigateToTeamNeeds(team: TeamObject) {
        stackDepth += 1
        Broadcaster.notify(NavigateToProfile.self) {
            $0.navigateToTeamNeeds(team: team)
        }
    }
    
    func navigateToTeamBuild(team: TeamObject) {
        stackDepth += 1
        Broadcaster.notify(NavigateToProfile.self) {
            $0.navigateToTeamBuild(team: team)
        }
    }
    
    func navigateToTeamFreeAgentSearch(team: TeamObject){
        stackDepth += 1
        Broadcaster.notify(NavigateToProfile.self) {
            $0.navigateToTeamFreeAgentSearch(team: team)
        }
    }
    
    func navigateToTeamFreeAgentResults(team: TeamObject){
        stackDepth += 1
        Broadcaster.notify(NavigateToProfile.self) {
            $0.navigateToTeamFreeAgentResults(team: team)
        }
    }
    
    func navigateToTeamFreeAgentDash(){
        stackDepth += 1
       Broadcaster.notify(NavigateToProfile.self) {
           $0.navigateToTeamFreeAgentDash()
       }
    }
    
    func navigateToTeamFreeAgentFront(){
        stackDepth += 1
       Broadcaster.notify(NavigateToProfile.self) {
           $0.navigateToTeamFreeAgentFront()
       }
    }
    
    func navigateToFreeAgentQuiz(user: User!, team: TeamObject?, game: GamerConnectGame!) {
        stackDepth += 1
        Broadcaster.notify(NavigateToProfile.self) {
            $0.navigateToFreeAgentQuiz(team: team, gcGame: game, currentUser: user)
        }
    }
    
    func navigateToFreeAgentQuiz(team: TeamObject?, gcGame: GamerConnectGame, currentUser: User){
        stackDepth += 1
          Broadcaster.notify(NavigateToProfile.self) {
            $0.navigateToFreeAgentQuiz(team: team, gcGame: gcGame, currentUser: currentUser)
          }
    }
    
    func navigateToMessaging(groupChannelUrl: String?, otherUserId: String?){
        stackDepth += 1
        Broadcaster.notify(NavigateToProfile.self) {
          $0.navigateToMessaging(groupChannelUrl: groupChannelUrl, otherUserId: otherUserId)
        }
    }
    
    func navigateToViewTeams(){
        stackDepth += 1
        Broadcaster.notify(NavigateToProfile.self) {
          $0.navigateToViewTeams()
        }
    }
    
    func searchSubmitted(searchString: String) {
    }
    
    func goBack(){
        Broadcaster.notify(NavigateToProfile.self) {
            $0.goBack()
        }
    }
    
    func programmaticallyLoad(vc: UIViewController, fragName: String) {
    }
    
    func removeBottomNav(showNewNav: Bool, hideSearch: Bool, searchHint: String?){
        if(showNewNav){
            mainNavView.slideOutBottom()
            
            if(!bottomNavSearch.isHidden && hideSearch){
                bottomNavSearch.slideOutBottom()
                searchButton.slideOutBottom()
                
                searchShowing = false
            }
            else{
                if(!searchShowing && hideSearch == false){
                    bottomNavSearch.slideInBottomReset()
                    searchButton.slideInBottomReset()
                    
                    searchShowing = true
                }
                else{
                    bottomNavSearch.isHidden = hideSearch
                    searchShowing = hideSearch
                }
            }
            
            if(searchHint != nil){
                bottomNavSearch.placeholder = searchHint
            }
            else{
                bottomNavSearch.placeholder = "Search"
            }
            
            secondaryNv.slideInBottom()
            secondaryNv.isHidden = false
            
            isSecondaryNavShowing = true
        }
        else if(isSecondaryNavShowing && hideSearch){
            searchShowing = false
            
            primaryBack.slideInBottomSmall()
        }
        else{
            isSecondaryNavShowing = false
            
            searchShowing = true
            bottomNavSearch.isHidden = false
            searchButton.isHidden = false
            
            primaryBack.slideInBottomSmall()
        }
    }
    
    func restoreBottomNav(){
        if(isSecondaryNavShowing == true){
            secondaryNv.slideOutBottomSecond()
            
            mainNavView.slideInBottomNav()
        }
        else{
            primaryBack.slideOutBottomSmall()
        }
    }
    
    
    private func enableButtons(){
        let singleTapTeam = UITapGestureRecognizer(target: self, action: #selector(teamButtonClicked))
        team.isUserInteractionEnabled = true
        team.addGestureRecognizer(singleTapTeam)
        
        let singleTapHome = UITapGestureRecognizer(target: self, action: #selector(homeButtonClicked))
        connect.isUserInteractionEnabled = true
        connect.addGestureRecognizer(singleTapHome)
        
        let singleTapRequests = UITapGestureRecognizer(target: self, action: #selector(requestButtonClicked))
        requests.isUserInteractionEnabled = true
        requests.addGestureRecognizer(singleTapRequests)
        
        bottomNav.isHidden = false
        bottomNav.isUserInteractionEnabled = true
    }
    
    @objc func homeButtonClicked(_ sender: AnyObject?) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        if(appDelegate.currentFrag != "Home"){
            navigateToHome()
            homeAdded = true
            requestsAdded = false
            teamFragAdded = false
            profileAdded = false
        }
    }
    
    @objc func teamButtonClicked(_ sender: AnyObject?) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        if(appDelegate.currentFrag != "Team"){
            navigateToTeams()
            teamFragAdded = true
            homeAdded = false
            requestsAdded = false
            profileAdded = false
        }
    }
    
    @objc func requestButtonClicked(_ sender: AnyObject?) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        if(appDelegate.currentFrag != "Requests"){
            navigateToRequests()
            requestsAdded = true
            homeAdded = false
            teamFragAdded = false
            profileAdded = false
        }
    }
}

