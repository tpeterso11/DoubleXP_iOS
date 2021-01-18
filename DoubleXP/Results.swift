//
//  Results.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 10/13/20.
//  Copyright © 2020 Peterson, Toussaint. All rights reserved.
//

import Foundation
import UIKit
import SPStorkController
import SwiftNotificationCenter

class Results: UIViewController, UITableViewDataSource, UITableViewDelegate {
    var payload = [Any]()
    var returning = false
    var userUid = ""
    var currentUpgradeChoice = ""
    @IBOutlet weak var resultTable: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        buildPayload()
    }
    
    private func buildPayload(){
        let delegate = UIApplication.shared.delegate as! AppDelegate
        payload = [Any]()
        
        payload.append("header") //header "we did it!"
        
        if(isKeyPresentInUserDefaults(key: "registered")){
            self.returning = true
        }
        
        if(!returning){
            if(!delegate.registerUserCache.isEmpty){
                let usersPayload = [delegate.cachedUserType: delegate.registerUserCache]
                payload.append(usersPayload)
            } else {
                let usersPayload = [delegate.cachedUserType: createDefaultList()]
                payload.append(usersPayload)
            }
        }
        
        let currentUser = delegate.currentUser!
        let games = currentUser.games
        
        for game in delegate.gcGames {
            if((game.hasQuiz && games.contains(game.gameName)) || (game.statsAvailable && games.contains(game.gameName))){
                payload.append("toolsHeader")
                break
            }
        }
        //quizzes
        for game in delegate.gcGames {
            if(game.hasQuiz && games.contains(game.gameName)){
                payload.append(0)
                break
            }
        }
        //stats
        for game in delegate.gcGames {
            if(game.statsAvailable && games.contains(game.gameName)){
                payload.append(1)
                break
            }
        }
        payload.append(false)
        
        self.resultTable.delegate = self
        self.resultTable.dataSource = self
    }
    
    private func isKeyPresentInUserDefaults(key: String) -> Bool {
        return UserDefaults.standard.object(forKey: key) != nil
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return payload.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let current = payload[indexPath.item]
        if(current is String){
            if((current as! String) == "header"){
                let cell = tableView.dequeueReusableCell(withIdentifier: "header", for: indexPath) as! ResultsHeaderCell
                if(self.returning){
                    cell.header.text = "welcome back!"
                    cell.sub.text = "now, let's see how we can upgrade your profile."
                } else {
                    cell.header.text = "we did it!"
                    cell.sub.text = "i knew we could..."
                }
                cell.header.alpha = 1
                cell.header.isHidden = false
                
                cell.whiteGuyContainer.layer.cornerRadius = 15.0
                cell.whiteGuyContainer.layer.borderWidth = 1.0
                cell.whiteGuyContainer.layer.borderColor = UIColor.clear.cgColor
                cell.whiteGuyContainer.layer.masksToBounds = true
                
                cell.whiteGuyContainer.layer.shadowColor = UIColor.black.cgColor
                cell.whiteGuyContainer.layer.shadowOffset = CGSize(width: 0, height: 2.0)
                cell.whiteGuyContainer.layer.shadowRadius = 2.0
                cell.whiteGuyContainer.layer.shadowOpacity = 0.5
                cell.whiteGuyContainer.layer.masksToBounds = false
                cell.whiteGuyContainer.layer.shadowPath = UIBezierPath(roundedRect: cell.whiteGuyContainer.bounds, cornerRadius: cell.whiteGuyContainer.layer.cornerRadius).cgPath
                
                return cell
            }
            else if((current as! String) == "toolsHeader"){
                let cell = tableView.dequeueReusableCell(withIdentifier: "toolsHeader", for: indexPath) as! EmptyCell
                return cell
            }
        }
        if(current is [String: [User]]){
            let current = (current as! [String: [User]])
            let delegate = UIApplication.shared.delegate as! AppDelegate
            let values = current.map { $0.value }
            let cell = tableView.dequeueReusableCell(withIdentifier: "user", for: indexPath) as! ResultsUserCell
            cell.setUserList(list: values[0], type: delegate.cachedUserType, resultsConroller: self)
            return cell
        }
        if(current is Int){
            if((current as! Int) == 0){
                let cell = tableView.dequeueReusableCell(withIdentifier: "upgrade", for: indexPath) as! ResultsUpgradeCell
                cell.header.text = "take a free agent quiz"
                cell.sub.text = "let them know how you play."
                
                let cellTap = UpgradeTapGesture(target: self, action: #selector(proceedUpgrade))
                cellTap.tag = indexPath.item
                cell.isUserInteractionEnabled = true
                cell.contentView.addGestureRecognizer(cellTap)
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "upgrade", for: indexPath) as! ResultsUpgradeCell
                cell.header.text = "import stats"
                cell.sub.text = "let them know how good you are."
                
                let cellTap = UpgradeTapGesture(target: self, action: #selector(proceedUpgrade))
                cellTap.tag = indexPath.item
                cell.isUserInteractionEnabled = true
                cell.contentView.addGestureRecognizer(cellTap)
                return cell
            }
        }
        if(current is Bool){
            let cell = tableView.dequeueReusableCell(withIdentifier: "button", for: indexPath) as! ResultsButtonCell
            if(returning){
                cell.header.text = "you keep gaming."
                cell.sub.text = "we'll keep finding ways to get you gaming."
                cell.button.titleLabel!.text = "done."
            } else {
                cell.header.text = "we've kept you long enough"
                cell.sub.text = "let's get you back in the game."
                cell.button.titleLabel!.text = "done."
            }
            cell.button.addTarget(self, action: #selector(self.proceedHome), for: .touchUpInside)
            return cell
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! GameSelectionV2Cell
        return cell
    }
    
    @objc private func proceedHome(){
        UserDefaults.standard.setValue("true", forKey: "registered")
        performSegue(withIdentifier: "home", sender: self)
    }
    
    @objc private func proceedUpgrade(sender: UpgradeTapGesture){
        let current = payload[sender.tag] as? Int ?? -1
        if(current == 0){
            currentUpgradeChoice = "quiz"
        } else {
            currentUpgradeChoice = "stats"
        }
        performSegue(withIdentifier: "upgrade", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if(segue.identifier == "upgrade"){
            let svc = segue.destination as! Upgrade
            svc.extra = self.currentUpgradeChoice
        }
    }
    
    func proceedToProfile(userUid: String){
        let delegate = UIApplication.shared.delegate as! AppDelegate
        delegate.cachedTest = userUid
        performSegue(withIdentifier: "profile", sender: self)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let current = self.payload[indexPath.item]
        if(current is String){
            if((current as! String) == "toolsHeader"){
                return CGFloat(120)
            } else {
                return CGFloat(350)
            }
        }
        if(current is [String: [User]]){
            return CGFloat(570)
        }
        if(current is Int){
            return CGFloat(80)
        }
        if(current is Bool){
            return CGFloat(180)
        }
        return CGFloat(150)
    }
    
    private func createDefaultList() -> [User]{
        let userOne = User(uId: "DihWEjaTfVNbo7zvqTDoycIvDiv2")
        userOne.gamerTag = "allthesaint011"
        
        let userTwo = User(uId: "N1k1BqmvEvdOXrbmi2p91kTNLOo1")
        userTwo.gamerTag = "Kwatakye Raven"
        
        var users = [User]()
        users.append(userOne)
        users.append(userTwo)
        return users
    }
}

class UpgradeTapGesture: UITapGestureRecognizer {
    var tag: Int!
}
