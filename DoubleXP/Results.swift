//
//  Results.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 10/13/20.
//  Copyright © 2020 Peterson, Toussaint. All rights reserved.
//

import Foundation
import UIKit

class Results: UITableViewController {
    var payload = [Any]()
    var returning = false
    var userUid = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        buildPayload()
    }
    
    private func buildPayload(){
        let delegate = UIApplication.shared.delegate as! AppDelegate
        payload = [Any]()
        
        payload.append("header") //header "we did it!"
        if(!delegate.registerUserCache.isEmpty){
            let usersPayload = [delegate.cachedUserType: delegate.registerUserCache]
            payload.append(usersPayload)
        } else {
            let usersPayload = [delegate.cachedUserType: createDefaultList()]
            payload.append(usersPayload)
        }
        
        var quizzes = false
        var stats = false
        for game in delegate.currentUser!.games {
            for gcGame in delegate.gcGames {
                if(gcGame.gameName == game) {
                    if(gcGame.hasQuiz){
                        quizzes = true
                    }
                    if(gcGame.statsAvailable){
                        stats = true
                    }
                    if(quizzes && stats){
                        break
                    }
                }
            }
        }
        if(quizzes){
            payload.append(0)
        }
        if(stats){
            payload.append(1)
        }
        payload.append(false)
        
        if(isKeyPresentInUserDefaults(key: "registered")){
            self.returning = true
        }
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
    }
    
    private func isKeyPresentInUserDefaults(key: String) -> Bool {
        return UserDefaults.standard.object(forKey: key) != nil
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return payload.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let current = payload[indexPath.item]
        if(current is String){
            if((current as! String) == "header"){
                let cell = tableView.dequeueReusableCell(withIdentifier: "header", for: indexPath) as! ResultsHeaderCell
                return cell
            }
        }
        if(current is [String: [User]]){
            let cell = tableView.dequeueReusableCell(withIdentifier: "user", for: indexPath) as! ResultsUserCell
            return cell
        }
        if(current is Int){
            if((current as! Int) == 0){
                let cell = tableView.dequeueReusableCell(withIdentifier: "upgrade", for: indexPath) as! ResultsUpgradeCell
                cell.header.text = "free agent quiz"
                cell.sub.text = "let them know how you play."
                
                let cellTap = UITapGestureRecognizer(target: self, action: #selector(proceedUpgrade))
                cell.isUserInteractionEnabled = true
                cell.contentView.addGestureRecognizer(cellTap)
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "upgrade", for: indexPath) as! ResultsUpgradeCell
                cell.header.text = "import stats"
                cell.sub.text = "let them know how good you are."
                
                let cellTap = UITapGestureRecognizer(target: self, action: #selector(proceedUpgrade))
                cell.isUserInteractionEnabled = true
                cell.contentView.addGestureRecognizer(cellTap)
                return cell
            }
        }
        if(current is Bool){
            let cell = tableView.dequeueReusableCell(withIdentifier: "button", for: indexPath) as! ResultsButtonCell
            if(returning){
                cell.header.text = "you keep improving your profile."
                cell.sub.text = "we'll keep finding ways to get you gaming."
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
    
    @objc private func proceedUpgrade(){
        performSegue(withIdentifier: "home", sender: self)
    }
    
    func proceedToProfile(userUid: String){
        self.userUid = userUid
        performSegue(withIdentifier: "profile", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if(segue.identifier == "profile"){
            let destinationVC = segue.destination as! LandingActivity
            destinationVC.resultsUserUid = userUid
        }
    }
    
    private func createDefaultList() -> [User]{
        let userOne = User(uId: "xyz")
        userOne.gamerTag = "allthesaint011"
        
        let userTwo = User(uId: "abc")
        userTwo.gamerTag = "Kwatakye Raven"
        
        var users = [User]()
        users.append(userOne)
        users.append(userTwo)
        return users
    }
}
