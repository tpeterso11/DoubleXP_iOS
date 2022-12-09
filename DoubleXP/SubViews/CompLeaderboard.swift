//
//  CompLeaderboard.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 4/13/22.
//  Copyright © 2022 Peterson, Toussaint. All rights reserved.
//

import Foundation
import UIKit
import Firebase
import SPStorkController

class CompLeaderboard : UIViewController, UITableViewDelegate, UITableViewDataSource, SPStorkControllerDelegate {
    @IBOutlet weak var leaderboardTable: UITableView!
    var payload = [Any]()
    var compId: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.payload.append("header")
        loadLeaderboard()
    }
    
    private func loadLeaderboard(){
        let ref = Database.database().reference().child("Entries").child(compId!)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            if(snapshot.exists()){
                for user in snapshot.children {
                    let videoArray = snapshot.childSnapshot(forPath: (user as! DataSnapshot).key)
                    var currentEntries = [CompEntryObject]()
                    for video in videoArray.children {
                        let currentVid = video as! DataSnapshot
                        let dict = currentVid.value as! [String: Any]
                        let uid = dict["uid"] as? String ?? ""
                        let gamerTag = dict["gamerTag"] as? String ?? ""
                        let youtubeId = dict["youtubeId"] as? String ?? ""
                        let imgUrl = dict["imgUrl"] as? String ?? ""
                        let compId = dict["compId"] as? String ?? ""
                        let votersUids = dict["votersUids"] as? [String] ?? [String]()
                        let voteCount = dict["voteCount"] as? CLong ?? -1
                        let currentPosition = dict["currentPosition"] as? CLong ?? -1
                        let lastPostion = dict["lastPostion"] as? CLong ?? -1
                    
                        let newEntry = CompEntryObject(uid: uid, youtubeId: youtubeId, imgUrl: imgUrl, compId: compId, voteCount: voteCount, votersUids: votersUids, currentPosition: currentPosition, lastPosition: lastPostion, gamerTag: gamerTag, dbKey: currentVid.key, passUids: [String]())
                        currentEntries.append(newEntry)
                    }
                    if(!currentEntries.isEmpty){
                        let sortedEntries = currentEntries.sorted(by: { $0.voteCount > $1.voteCount })
                        var realIndex = 1
                        for entry in sortedEntries {
                            if(entry.currentPosition != realIndex){
                                entry.lastPosition = entry.currentPosition
                                ref.child(entry.uid).child(entry.dbKey).child("lastPosition").setValue(entry.currentPosition)
                                ref.child(entry.uid).child(entry.dbKey).child("currentPosition").setValue(realIndex)
                                entry.currentPosition = realIndex
                            }
                            else {
                                entry.lastPosition = realIndex
                                entry.currentPosition = realIndex
                            }
                            realIndex += 1
                        }
                        self.payload.append(contentsOf: sortedEntries.sorted(by: { $0.currentPosition > $1.currentPosition }))
                        self.leaderboardTable.delegate = self
                        self.leaderboardTable.dataSource = self
                        self.leaderboardTable.reloadData()
                    } else {
                        //show empty
                        self.payload.append("empty")
                        self.leaderboardTable.delegate = self
                        self.leaderboardTable.dataSource = self
                        self.leaderboardTable.reloadData()
                    }
                }
            } else {
                //show empty
                self.payload.append("empty")
                self.leaderboardTable.delegate = self
                self.leaderboardTable.dataSource = self
                self.leaderboardTable.reloadData()
            }
        })
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.payload.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let current = self.payload[indexPath.item]
        if(current is String){
            if(current as! String == "header"){
                let cell = tableView.dequeueReusableCell(withIdentifier: "header", for: indexPath) as! LeaderboardHeaderCell
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "empty", for: indexPath) as! LeaderboardEmpty
                return cell
            }
        } else {
            let user = current as! CompEntryObject
            let cell = tableView.dequeueReusableCell(withIdentifier: "user", for: indexPath) as! LeaderboardUserCell
            cell.gamerTag.text = user.gamerTag
            if(user.lastPosition < user.currentPosition){
                cell.progressImg.image = #imageLiteral(resourceName: "up_right_arrow.png")
            } else if (user.lastPosition > user.currentPosition) {
                cell.progressImg.image = #imageLiteral(resourceName: "down_right.png")
            }
            cell.positionIndex.text = String(indexPath.item)//String(format: "%02d", user.currentPosition)
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let current = self.payload[indexPath.item] as? CompEntryObject
        
        if(current != nil){
            let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "playerProfile") as! PlayerProfile
            let transitionDelegate = SPStorkTransitioningDelegate()
            currentViewController.transitioningDelegate = transitionDelegate
            currentViewController.modalPresentationStyle = .custom
            currentViewController.modalPresentationCapturesStatusBarAppearance = true
            currentViewController.editMode = false
            currentViewController.uid = current!.uid
            transitionDelegate.showIndicator = true
            transitionDelegate.swipeToDismissEnabled = true
            transitionDelegate.hapticMoments = [.willPresent, .willDismiss]
            transitionDelegate.storkDelegate = self
            self.present(currentViewController, animated: true, completion: nil)
        }
    }
}
