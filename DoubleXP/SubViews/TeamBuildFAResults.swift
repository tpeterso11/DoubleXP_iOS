//
//  TeamBuildFAResults.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 12/3/19.
//  Copyright © 2019 Peterson, Toussaint. All rights reserved.
//
import UIKit
import Firebase

class TeamBuildFAResults: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    var team: TeamObject?
    var currentUser: User?
    var finalList = [FreeAgentObject]()
    
    @IBOutlet weak var faResults: UICollectionView!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let delegate = UIApplication.shared.delegate as! AppDelegate
        currentUser = delegate.currentUser
        
        doSearch(needs: team!.selectedTeamNeeds)
    }
    
    func doSearch(needs: [String]){
        let ref = Database.database().reference().child("Free Agents V2")
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            var results = [FreeAgentObject]()
            
            if(snapshot.exists()){
                for agent in snapshot.children{
                    let currentObj = agent as! DataSnapshot
                    for profile in currentObj.children{
                        let currentProfile = profile as! DataSnapshot
                        let dict = currentProfile.value as! [String: Any]
                        let game = dict["game"] as? String ?? ""
                        if((game as String) == self.team!.games[0]){
                            let consoles = dict["consoles"] as? [String] ?? [String]()
                            if(consoles.contains((self.team?.consoles[0])!)){
                                let gamerTag = dict["gamerTag"] as? String ?? ""
                                let competitionId = dict["competitionId"] as? String ?? ""
                                let userId = dict["userId"] as? String ?? ""
                                let questions = dict["questions"] as? [[String]] ?? [[String]]()
                                
                                let result = FreeAgentObject(gamerTag: gamerTag, competitionId: competitionId, consoles: consoles, game: game, userId: userId, questions: questions)
                                results.append(result)
                            }
                        }
                    }
                }
            }
            
            if(!results.isEmpty){
                self.processResults(results: results)
            }
            else{
                
            }
            
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
    private func processResults(results: [FreeAgentObject]){
        let selected = team!.selectedTeamNeeds
        finalList = [FreeAgentObject]()
        
        if(!selected.isEmpty){
            for freeAgent in results{
                if(selected.contains(freeAgent.questions[0][0])){
                    finalList.append(freeAgent)
                }
            }
            
            faResults.dataSource = self
            faResults.delegate = self
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return finalList.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! FreeAgentResultCell
        
        let current = finalList[indexPath.item]
        cell.game.text = team!.games[0]
        cell.gamerTag.text = current.gamerTag
        
        return cell
    }
}


