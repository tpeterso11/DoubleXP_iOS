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

typealias Runnable = () -> ()

@IBDesignable extension UIButton {

    @IBInspectable var borderWidth: CGFloat {
        set {
            layer.borderWidth = newValue
        }
        get {
            return layer.borderWidth
        }
    }

    @IBInspectable var cornerRadius: CGFloat {
        set {
            layer.cornerRadius = newValue
        }
        get {
            return layer.cornerRadius
        }
    }

    @IBInspectable var borderColor: UIColor? {
        set {
            guard let uiColor = newValue else { return }
            layer.borderColor = uiColor.cgColor
        }
        get {
            guard let color = layer.borderColor else { return nil }
            return UIColor(cgColor: color)
        }
    }
}

protocol Profile {
    func goToProfile()
}

class LandingActivity: UIViewController, EMPageViewControllerDelegate, NavigateToProfile, SearchCallbacks, LandingMenuCallbacks, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UITextFieldDelegate {
    
    @IBOutlet weak var navigationView: UIView!
    @IBOutlet weak var navContainer: UIView!
    @IBOutlet weak var teamButton: UIImageView!
    @IBOutlet weak var homeButton: UIImageView!
    @IBOutlet weak var requestButton: UIImageView!
    @IBOutlet weak var bottomNav: UIView!
    @IBOutlet weak var mainNavView: UIView!
    @IBOutlet weak var secondaryNv: UIView!
    @IBOutlet weak var blur: UIVisualEffectView!
    @IBOutlet weak var requests: UIImageView!
    @IBOutlet weak var connect: UIImageView!
    @IBOutlet weak var team: UIImageView!
    @IBOutlet weak var bottomNavBack: UIImageView!
    @IBOutlet weak var bottomNavSearch: UITextField!
    @IBOutlet weak var primaryBack: UIImageView!
    @IBOutlet weak var searchButton: UIButton!
    var mainNavShowing = false
    //@IBOutlet weak var newNav: UIView!
    
    @IBOutlet weak var clickArea: UIView!
    @IBOutlet weak var mediaButton: UIImageView!
    @IBOutlet weak var logOut: UIButton!
    @IBOutlet weak var menuCollection: UICollectionView!
    @IBOutlet weak var friendsLabel: UILabel!
    @IBOutlet weak var menuButton: UIImageView!
    @IBOutlet weak var menuVie: AnimatingView!
    @IBOutlet weak var mainNavCollection: UICollectionView!
    private var requestsAdded = false
    private var teamFragAdded = false
    private var profileAdded = false
    private var homeAdded = false
    private var mediaAdded = false
    private var isSecondaryNavShowing = false
    var stackDepth = 0
    var searchShowing = true
    var backButtonShowing = false
    var menuItems = [Any]()

    
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
        
        stackDepth = appDelegate.navStack.count
        
        menuVie.alpha = 1.0
        menuVie.layer.shadowColor = UIColor.black.cgColor
        menuVie.layer.shadowOffset = CGSize(width: 0, height: 2.0)
        menuVie.layer.shadowRadius = 2.0
        menuVie.layer.shadowOpacity = 0.5
        menuVie.layer.masksToBounds = false
        menuVie.layer.shadowPath = UIBezierPath(roundedRect: menuVie.bounds, cornerRadius: menuVie.layer.cornerRadius).cgPath
        
        logOut.layer.shadowColor = UIColor.black.cgColor
        logOut.layer.shadowOffset = CGSize(width: 0, height: 2.0)
        logOut.layer.shadowRadius = 2.0
        logOut.layer.shadowOpacity = 0.5
        logOut.layer.masksToBounds = false
        logOut.layer.shadowPath = UIBezierPath(roundedRect: logOut.bounds, cornerRadius: logOut.layer.cornerRadius).cgPath
        
        bottomNavSearch.addTarget(self, action: #selector(textFieldDidBeginEditing(_:)), for: .editingChanged)
        //bottomNavSearch.addTarget(self, action: #selector(textFieldDidEndEditing(_:)), for: .editingChanged)
        bottomNavSearch.delegate = self
        bottomNavSearch.returnKeyType = .done
        
        Broadcaster.register(LandingMenuCallbacks.self, observer: self)
    }
    
    @objc func searchClicked(_ sender: AnyObject?) {
        if(!bottomNavSearch.text!.isEmpty){
            Broadcaster.notify(SearchCallbacks.self) {
                $0.searchSubmitted(searchString: bottomNavSearch.text!)
            }
            
            bottomNavSearch.text = ""
        }
    }
    
    @objc func sendMessage(_ sender: AnyObject?) {
        var count = 0
        if(!bottomNavSearch.text!.isEmpty && count < 1){
            count += 1
            Broadcaster.notify(SearchCallbacks.self) {
                $0.messageTextSubmitted(string: bottomNavSearch.text!, list: nil)
            }
            
            bottomNavSearch.text = ""
        }
    }
    
    @objc func backButtonClicked(_ sender: AnyObject?) {
        if(menuVie.viewShowing){
            dismissMenu()
        }
        else{
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            var stack = appDelegate.navStack
            stackDepth -= 1
            
            if(!stack.isEmpty){
                Broadcaster.notify(NavigateToProfile.self) {
                    let vc = stack[self.stackDepth - 1] as! ParentVC
                    $0.programmaticallyLoad(vc: stack[self.stackDepth - 1] as! ParentVC, fragName: vc.pageName!)
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
    
    @objc func navigateToCurrentUserProfile() {
        stackDepth += 1
        
        let top = CGAffineTransform(translationX: -249, y: 0)
        UIView.animate(withDuration: 0.4, delay: 0.0, options:[], animations: {
            self.menuVie.transform = top
        }, completion: { (finished: Bool) in
            UIView.animate(withDuration: 0.3, delay: 0.0, options: [], animations: {
                self.blur.alpha = 0.0
            }, completion: { (finished: Bool) in
                UIView.animate(withDuration: 0.3, delay: 0.0, options: [], animations: {
                    self.restoreBottomNav()
                }, completion: { (finished: Bool) in
                    self.stackDepth += 1
                    Broadcaster.notify(NavigateToProfile.self) {
                        $0.navigateToCurrentUserProfile()
                    }
                })
            })
        })
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
    
    func navigateToMedia() {
        stackDepth += 1
        Broadcaster.notify(NavigateToProfile.self) {
            $0.navigateToMedia()
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
    
    func menuNavigateToMessaging(uId: String) {
        menuVie.viewShowing = false
        
        let top = CGAffineTransform(translationX: -249, y: 0)
        UIView.animate(withDuration: 0.4, delay: 0.0, options:[], animations: {
            self.menuVie.transform = top
        }, completion: { (finished: Bool) in
            UIView.animate(withDuration: 0.3, delay: 0.0, options: [], animations: {
                self.blur.alpha = 0.0
            }, completion: { (finished: Bool) in
                UIView.animate(withDuration: 0.3, delay: 0.0, options: [], animations: {
                    self.restoreBottomNav()
                }, completion: { (finished: Bool) in
                    self.stackDepth += 1
                    Broadcaster.notify(NavigateToProfile.self) {
                      $0.navigateToMessaging(groupChannelUrl: nil, otherUserId: uId)
                    }
                })
            })
        })
    }
    
    func menuNavigateToProfile(uId: String){
        menuVie.viewShowing = false
        self.restoreBottomNav()
        
        let top = CGAffineTransform(translationX: -249, y: 0)
        UIView.animate(withDuration: 0.4, delay: 0.3, options:[], animations: {
            self.menuVie.transform = top
        }, completion: { (finished: Bool) in
            UIView.animate(withDuration: 0.3, delay: 0.0, options: [], animations: {
                self.blur.alpha = 0.0
            }, completion: { (finished: Bool) in
                UIView.animate(withDuration: 0.3, delay: 0.0, options: [], animations: {
                        self.stackDepth += 1
                        Broadcaster.notify(NavigateToProfile.self) {
                                $0.navigateToProfile(uid: uId)
                        }
                }, completion: nil)
            })
        })
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
    
    func updateNavigation(currentFrag: ParentVC){
        let navOptions = currentFrag.navDictionary
        
        switch(navOptions!["state"]){
            case "original":
                restoreBottomNav()
            break
            
            case "backOnly":
                removeBottomNav(showNewNav: false, hideSearch: true, searchHint: nil, searchButtonText: nil, isMessaging: false)
            break
            
            case "secondary":
                removeBottomNav(showNewNav: true, hideSearch: true, searchHint: nil, searchButtonText: nil, isMessaging: false)
            break
            
            case "search":
                removeBottomNav(showNewNav: true, hideSearch: false, searchHint: navOptions!["searchHint"], searchButtonText: navOptions!["searchButton"], isMessaging: false)
            break
            
            case "messaging":
                removeBottomNav(showNewNav: true, hideSearch: false, searchHint: navOptions!["searchHint"], searchButtonText: navOptions!["searchButton"], isMessaging: true)
            break
            
            case "none":
                removeBottomNav(showNewNav: true, hideSearch: true, searchHint: nil, searchButtonText: nil, isMessaging: false)
            break
            
            default:
                removeBottomNav(showNewNav: false, hideSearch: false, searchHint: nil, searchButtonText: nil, isMessaging: false)
            break
        }
    }
    
    func removeBottomNav(showNewNav: Bool, hideSearch: Bool, searchHint: String?, searchButtonText: String?, isMessaging: Bool){
        if(showNewNav){
            //remove nav icons
            mainNavView.slideOutBottom()
            
            if(!bottomNavSearch.isHidden && hideSearch){
                bottomNavSearch.slideOutBottom()
                searchButton.slideOutBottom()
                
                searchShowing = false
            }
            else{
                //search is not showing and we want to show it
                if(!searchShowing && hideSearch == false){
                    bottomNavSearch.isHidden = false
                    bottomNavSearch.slideInBottomReset()
                    
                    //apply title to search button and bring it in.
                    if(searchButtonText != nil){
                        searchButton.setTitle(searchButtonText, for: .normal)
                    }
                    searchButton.slideInBottomReset()
                    
                    if(isMessaging){
                        searchButton.addTarget(self, action: #selector(sendMessage), for: .touchUpInside)
                    }
                    else{
                        searchButton.addTarget(self, action: #selector(searchClicked), for: .touchUpInside)
                    }
                    
                    searchShowing = true
                }
                //if search is already showing
                else if(searchShowing && hideSearch == false){
                    if(searchButtonText != nil){
                        searchButton.setTitle(searchButtonText, for: .normal)
                    }
                    searchButton.slideInBottomReset()
                    
                    if(isMessaging){
                        searchButton.addTarget(self, action: #selector(sendMessage), for: .touchUpInside)
                    }
                    else{
                        searchButton.addTarget(self, action: #selector(searchClicked), for: .touchUpInside)
                    }
                    
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
            
            if(!backButtonShowing){
                secondaryNv.slideInBottom()
                secondaryNv.isHidden = false
            }
            
            isSecondaryNavShowing = true
        }
        else if(isSecondaryNavShowing && hideSearch){
            if(isSecondaryNavShowing){
                secondaryNv.slideOutBottomSecond()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.mainNavView.slideInBottomNav()
                }
            }
            
            if(hideSearch && searchShowing){
                bottomNavSearch.slideOutBottom()
                searchButton.slideOutBottom()
            }
            
            searchShowing = false
            if(!backButtonShowing){
                primaryBack.slideInBottomSmall()
            }
        }
        else{
            if(isSecondaryNavShowing){
                secondaryNv.slideOutBottomSecond()
            }
            isSecondaryNavShowing = false
            
            if(hideSearch && searchShowing){
                bottomNavSearch.slideOutBottom()
                searchButton.slideOutBottom()
            }
            else if(!hideSearch && !searchShowing){
                bottomNavSearch.isHidden = false
                searchButton.isHidden = false
                
                searchShowing = true
            }
            
            if(!mainNavShowing){
                mainNavView.slideInBottomNav()
            }
            
            if(!backButtonShowing){
                primaryBack.slideInBottomSmall()
            }
        }
    }
    
    func restoreBottomNav(){
        if(isSecondaryNavShowing == true){
            secondaryNv.slideOutBottomSecond()
            primaryBack.slideOutBottomSmall()
            mainNavView.slideInBottomNav()
        }
        else{
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            if(appDelegate.currentFrag == "Home"){
                primaryBack.slideOutBottomSmall()
                backButtonShowing = false
            }
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
        
        let singleTapMenu = UITapGestureRecognizer(target: self, action: #selector(menuButtonClicked))
        menuButton.isUserInteractionEnabled = true
        menuButton.addGestureRecognizer(singleTapMenu)
        
        let singleTapMedia = UITapGestureRecognizer(target: self, action: #selector(mediaButtonClicked))
        mediaButton.isUserInteractionEnabled = true
        mediaButton.addGestureRecognizer(singleTapMedia)
        
        bottomNav.isHidden = false
        bottomNav.isUserInteractionEnabled = true
    }
    
    @objc func homeButtonClicked(_ sender: AnyObject?) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        if(appDelegate.currentFrag != "Home" && !homeAdded){
            navigateToHome()
            homeAdded = true
            requestsAdded = false
            teamFragAdded = false
            profileAdded = false
            mediaAdded = false
        }
        
        updateNavColor(color: .darkGray)
    }
    
    @objc func mediaButtonClicked(_ sender: AnyObject?) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        if(appDelegate.currentFrag != "Media" && !mediaAdded){
            navigateToMedia()
            homeAdded = false
            requestsAdded = false
            teamFragAdded = false
            profileAdded = false
            mediaAdded = true
        }
        
        updateNavColor(color: .darkGray)
    }
    
    @objc func teamButtonClicked(_ sender: AnyObject?) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        if(appDelegate.currentFrag != "Team" && !teamFragAdded){
            navigateToTeams()
            teamFragAdded = true
            homeAdded = false
            requestsAdded = false
            profileAdded = false
            mediaAdded = false
        }
        
        updateNavColor(color: .darkGray)
    }
    
    @objc func requestButtonClicked(_ sender: AnyObject?) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        if(appDelegate.currentFrag != "Requests" && !requestsAdded){
            navigateToRequests()
            requestsAdded = true
            homeAdded = false
            teamFragAdded = false
            profileAdded = false
            mediaAdded = false
        }
        
        updateNavColor(color: .darkGray)
    }
    
    @objc func menuButtonClicked(_ sender: AnyObject?) {
        if(!menuVie.viewShowing){
            figureMenu()
            
            removeBottomNav(showNewNav: false, hideSearch: true, searchHint: nil, searchButtonText: nil, isMessaging: false)
            
            self.menuCollection.dataSource = self
            self.menuCollection.delegate = self
            
            let top = CGAffineTransform(translationX: 249, y: 0)
            UIView.animate(withDuration: 0.3, delay: 0.0, options:[], animations: {
                self.blur.alpha = 1.0
            }, completion: { (finished: Bool) in
                UIView.animate(withDuration: 0.4, delay: 0.3, options: [], animations: {
                    self.menuVie.transform = top
                    
                    let backTap = UITapGestureRecognizer(target: self, action: #selector(self.dismissMenu))
                    self.clickArea.isUserInteractionEnabled = true
                    self.clickArea.addGestureRecognizer(backTap)
                }, completion: nil)
            })
            
            self.blur.isUserInteractionEnabled = true
            menuVie.viewShowing = true
        }
    }
    
    func figureMenu(){
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let currentUser = appDelegate.currentUser
        
        self.menuItems.append(0)
        self.menuItems.append("Friends")
        self.menuItems.append(1)
        
        if let flowLayout = menuCollection?.collectionViewLayout as? UICollectionViewFlowLayout {
           flowLayout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        }
    }
    
    @objc func dismissMenu(){
        self.restoreBottomNav()
        menuVie.viewShowing = false
        
        let top = CGAffineTransform(translationX: -249, y: 0)
        UIView.animate(withDuration: 0.4, delay: 0.2, options:[], animations: {
            self.menuVie.transform = top
        }, completion: { (finished: Bool) in
            UIView.animate(withDuration: 0.3, delay: 0.0, options: [], animations: {
                self.blur.alpha = 0.0
                self.blur.isUserInteractionEnabled = false
            }, completion: nil)
        })
    }
    
    func messageTextSubmitted(string: String, list: [String]?) {
    }
    
    func updateNavColor(color: UIColor) {
        UIView.transition(with: self.bottomNav, duration: 0.3, options: .curveEaseInOut, animations: {
            self.bottomNav.backgroundColor = color
            self.mainNavView.backgroundColor = color
        }, completion: nil)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) { // became first responder

        //move textfields up
        let myScreenRect: CGRect = UIScreen.main.bounds
        let keyboardHeight : CGFloat = 500

        UIView.beginAnimations( "animateView", context: nil)
        var movementDuration:TimeInterval = 0.35
        var needToMove: CGFloat = 0

        var frame : CGRect = self.view.frame
        if (textField.frame.origin.y + textField.frame.size.height + /*self.navigationController.navigationBar.frame.size.height + */UIApplication.shared.statusBarFrame.size.height > (myScreenRect.size.height - keyboardHeight)) {
            needToMove = (textField.frame.origin.y + textField.frame.size.height + /*self.navigationController.navigationBar.frame.size.height +*/ UIApplication.shared.statusBarFrame.size.height) - (myScreenRect.size.height - keyboardHeight);
        }

        frame.origin.y = -needToMove
        self.view.frame = frame
        UIView.commitAnimations()
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
            //move textfields back down
            UIView.beginAnimations( "animateView", context: nil)
        var movementDuration:TimeInterval = 0.35
            var frame : CGRect = self.view.frame
            frame.origin.y = 0
            self.view.frame = frame
            UIView.commitAnimations()
    }
    
    func settingsProfileClicked(){
        
    }
    
    func navigateToMessagingFromMenu(uId: String){
        navigateToMessaging(groupChannelUrl: nil, otherUserId: uId)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.menuItems.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let current = menuItems[indexPath.item]
        if(current is String){
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "header", for: indexPath) as! MenuHeaderCell
            cell.headerText.text = current as? String
            return cell
        }
        else{
            if(current is Int){
                if(current as? Int == 0){
                    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "settings", for: indexPath) as! MenuSettingsCell
                    cell.tag = indexPath.item
                    cell.profileButton.addTarget(self, action: #selector(navigateToCurrentUserProfile), for: .touchUpInside)
                    return cell
                }
                else if(current as? Int == 1){
                    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "friendsList", for: indexPath) as! MenuFriendsList
                    cell.loadContent()
                    return cell
                }
                else{
                    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "dxpFriends", for: indexPath) as! MenuFriendsCell
                    return cell
                }
            }
            else{
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "dxpFriends", for: indexPath) as! MenuFriendsCell
                return cell
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let current = self.menuItems[indexPath.item]
        if(current is String){
            return CGSize(width: collectionView.bounds.size.width, height: CGFloat(50))
        }
        else{
            if(current is Int){
                if(current as? Int == 0){
                    //settings tab
                    return CGSize(width: collectionView.bounds.size.width, height: CGFloat(50))
                }
                else if(current as? Int == 1){
                    return CGSize(width: collectionView.bounds.size.width, height: CGFloat(400))
                }
                
                else{
                    return CGSize(width: collectionView.bounds.size.width, height: CGFloat(100))
                }
            }
            else{
                return CGSize(width: collectionView.bounds.size.width, height: CGFloat(100))
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
    }
    
    func programmaticallyLoad(vc: ParentVC, fragName: String) {
    }
    
}

