//
//  Requests.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 11/17/19.
//  Copyright © 2019 Peterson, Toussaint. All rights reserved.
//

import UIKit
import Firebase
import ImageLoader
import moa
import MSPeekCollectionViewDelegateImplementation

class Requests: ParentVC, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, RequestsUpdate {
    var userRequests = [Section]()
    
    
    @IBOutlet weak var requestList: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let currentUser = delegate.currentUser
        
        if(currentUser != nil){
            buildRequests(user: currentUser!)
        }
        else{
            return
        }
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let currentLanding = appDelegate.currentLanding
        currentLanding?.removeBottomNav(showNewNav: false, hideSearch: true, searchHint: nil)
        
        appDelegate.navStack.append(self)
        
        self.pageName = "Requests"
    }
    
    private func buildRequests(user: User){
        if(!user.pendingRequests.isEmpty){
            var section = Section(name: "Friend Requests", items: nil)
            var requests = [FriendRequestObject]()
            for request in user.pendingRequests{
                if(!requests.contains(request)){
                    requests.append(request)
                }
            }
            
            section.items = requests
            self.userRequests.append(section)
        }
        
        if(!user.teamInvites.isEmpty){
            var section = Section(name: "Team Invites", items: nil)
            var requests = [TeamObject]()
            for request in user.teamInvites{
                requests.append(request)
            }
            
            section.items = requests
            self.userRequests.append(section)
        }
        
        if(!userRequests.isEmpty){
            requestList.delegate = self
            requestList.dataSource = self
        }
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return self.userRequests.count
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "requestHeader", for: indexPath) as! RequestHeader
        
        let current = userRequests[indexPath.section]
        header.title.text = current.name
        
        if(current.name == "Friend Requests"){
            header.sub.text = "These players want to connect."
        }
        else{
            header.sub.text = "These teams want you to join."
        }
        
        return header
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.userRequests[section].items.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "requestCell", for: indexPath) as! RequestCell
        
        let current = self.userRequests[indexPath.section].items[indexPath.item]
        
        if(current is TeamObject){
            cell.requestLabel.text = (current as! TeamObject).teamName
        }
        else{
            cell.requestLabel.text = (current as! FriendRequestObject).gamerTag
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
            return CGSize(width: collectionView.bounds.size.width, height: CGFloat(80))
    }
    
    func updateCell(indexPath: IndexPath) {
        self.requestList.deleteItems(at: [indexPath])
    }
    
    struct Section {
        var name: String
        var items: [Any]
        
        init(name: String, items: [Any]?) {
            self.name = name
            self.items = [Any]()
        }
        
        func getCount() -> Int{
            return items.count
        }
    }
}
