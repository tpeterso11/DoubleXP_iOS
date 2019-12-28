//
//  FADash.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 12/10/19.
//  Copyright © 2019 Peterson, Toussaint. All rights reserved.
//

import UIKit
import Firebase
import ImageLoader
import moa
import MSPeekCollectionViewDelegateImplementation
import SendBirdSDK

class FADash: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, FACallbacks {
    @IBOutlet weak var faList: UICollectionView!
    @IBOutlet weak var searchTeams: UIButton!
    @IBOutlet weak var createButton: UIButton!
    private var profileList: [FreeAgentObject] = [FreeAgentObject]()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadProfiles()
        searchTeams.addTarget(self, action: #selector(searchButtonClicked), for: .touchUpInside)
        createButton.addTarget(self, action: #selector(createButtonClicked), for: .touchUpInside)
    }
    
    private func loadProfiles(){
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let currentUser = delegate.currentUser
        
        let ref = Database.database().reference().child("Free Agents V2").child(currentUser!.uId)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            self.profileList = [FreeAgentObject]()
            
            if(snapshot.exists()){
                for profile in snapshot.children{
                    let currentProfile = profile as! DataSnapshot
                    let dict = currentProfile.value as! [String: Any]
                    let game = dict["game"] as? String ?? ""
                    let consoles = dict["consoles"] as? [String] ?? [String]()
                    let gamerTag = dict["gamerTag"] as? String ?? ""
                    let competitionId = dict["competitionId"] as? String ?? ""
                    let userId = dict["userId"] as? String ?? ""
                    let questions = dict["questions"] as? [[String]] ?? [[String]]()
                    
                    let result = FreeAgentObject(gamerTag: gamerTag, competitionId: competitionId, consoles: consoles, game: game, userId: userId, questions: questions)
                    self.profileList.append(result)
                }
            }
            
            if(!self.profileList.isEmpty){
                let manager = FreeAgentManager()
                manager.cacheProfiles(profiles: self.profileList)
                
                self.faList.delegate = self
                self.faList.dataSource = self
            }
            else{
                //show empty
            }
            
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
    @objc func searchButtonClicked(_ sender: AnyObject?) {
        LandingActivity().navigateToViewTeams()
    }
    
    @objc func createButtonClicked(_ sender: AnyObject?) {
        LandingActivity().navigateToTeamFreeAgentFront()
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return profileList.count
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
            return CGSize(width: collectionView.bounds.size.width, height: CGFloat(80))
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! FADashCell
        let current = profileList[indexPath.item]
        
        cell.gameName.text = current.game
        
        var backUrl = ""
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let games = delegate.gcGames!
        for game in games{
            if(game.gameName == current.game){
                backUrl = game.imageUrl
                break
            }
        }
        
        cell.gameBack.moa.url = backUrl
        cell.gameBack.contentMode = .scaleAspectFill
        cell.gameBack.clipsToBounds = true
        
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(deleteButtonClicked))
        cell.deleteIcon.tag = indexPath.item
        cell.deleteIcon.isUserInteractionEnabled = true
        cell.deleteIcon.addGestureRecognizer(singleTap)
        
        return cell
    }
    
    func updateCell(indexPath: IndexPath) {
        self.faList.deleteItems(at: [indexPath])
    }
    
    @objc func deleteButtonClicked(_ sender: AnyObject?) {
        let manager = FreeAgentManager()
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let currentUser = delegate.currentUser
        
        let indexPath = IndexPath(item: (sender?.tag)!, section: 0)
        manager.deleteProfile(faObject: profileList[(sender?.tag)!], indexPath: indexPath, currentUser: currentUser!, callbacks: self)
    }
}
