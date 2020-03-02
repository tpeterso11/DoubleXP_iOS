//
//  Profile.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 3/1/20.
//  Copyright © 2020 Peterson, Toussaint. All rights reserved.
//

import Foundation
import UIKit

class ProfileFrag: ParentVC, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout{
    
    @IBOutlet weak var profileCollection: UICollectionView!
    @IBOutlet weak var pcSwitch: UISwitch!
    @IBOutlet weak var nintendoSwitch: UISwitch!
    @IBOutlet weak var xboxSwitch: UISwitch!
    @IBOutlet weak var psSwitch: UISwitch!
    @IBOutlet weak var bioEntry: UITextField!
    @IBOutlet weak var gamesCollection: UITableView!
    var gcGames = [GamerConnectGame]()
    var gamesPlayed = [GamerConnectGame]()
    var payload = [String]()
    
    var cellHeights: [CGFloat] = []
    enum Const {
           static let closeCellHeight: CGFloat = 83
           static let openCellHeight: CGFloat = 205
           static let rowsCount = 1
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        gcGames = appDelegate.gcGames
        
        if(!appDelegate.navStack.contains(self)){
            appDelegate.navStack.append(self)
        }
        
        self.pageName = "Profile"
        
        let currentUser = appDelegate.currentUser!
        /*if(currentUser.bio.isEmpty){
            self.bioEntry.placeholder = "let the people know about you."
        }
        else{
            self.bioEntry.placeholder = currentUser.bio
        }*/
        
        for game in gcGames{
            if(currentUser.games.contains(game.gameName)){
                gamesPlayed.append(game)
            }
        }
        setup()
    }
    
    private func setup(){
        /*cellHeights = Array(repeating: Const.closeCellHeight, count: self.gamesPlayed.count)
        gamesCollection.estimatedRowHeight = Const.closeCellHeight
        gamesCollection.rowHeight = UITableView.automaticDimension
        
        if #available(iOS 10.0, *) {
            gamesCollection.refreshControl = UIRefreshControl()
            gamesCollection.refreshControl?.addTarget(self, action: #selector(refreshHandler), for: .valueChanged)
        }*/
        
        self.payload.append("tag")
        self.payload.append("games")
        self.payload.append("console")
        
        profileCollection.dataSource = self
        profileCollection.delegate = self
        //self.payload.append("import")
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.payload.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let current = self.payload[indexPath.item]
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let currentUser = appDelegate.currentUser!
        
        if(current == "tag"){
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "tag", for: indexPath) as! ProfileGamerTagCell
            
            if(currentUser.bio.isEmpty){
                cell.bioTextField.placeholder = "you don't have a bio yet. let the people know who you are."
            }
            else{
                cell.bioTextField.placeholder = currentUser.bio
            }
            
            return cell
        }
        else if(current == "games"){
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "games", for: indexPath) as! ProfileGamesCell
            cell.setUi()
            return cell
        }
        else{
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "consoles", for: indexPath) as! ProfileConsolesCell
            
            if(currentUser.ps){
                cell.psSwitch.isOn = true
            }
            if(currentUser.xbox){
                cell.psSwitch.isOn = true
            }
            if(currentUser.pc){
                cell.psSwitch.isOn = true
            }
            if(currentUser.nintendo){
                cell.psSwitch.isOn = true
            }
            
            
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let current = self.payload[indexPath.item]
        
        if (current == "tag") {
            return CGSize(width: collectionView.bounds.size.width, height: CGFloat(150))
        }
        else if(current == "games"){
            return CGSize(width: collectionView.bounds.size.width, height: CGFloat(500))
        }
        else{
            return CGSize(width: collectionView.bounds.size.width, height: CGFloat(150))
        }
    }
}
