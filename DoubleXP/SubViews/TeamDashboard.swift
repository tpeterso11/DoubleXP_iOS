//
//  TeamDashboard.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 11/24/19.
//  Copyright © 2019 Peterson, Toussaint. All rights reserved.
//

import UIKit
import Firebase
import ImageLoader
import moa
import MSPeekCollectionViewDelegateImplementation

class TeamDashboard: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    var team: TeamObject? = nil
    
    
    @IBOutlet weak var teamLabel: UILabel!
    @IBOutlet weak var selectedNeeds: UICollectionView!
    @IBOutlet weak var buildButton: UIButton!
    @IBOutlet weak var chatButton: UIButton!
    @IBOutlet weak var alertButton: UIButton!
    @IBOutlet weak var captainStar: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let delegate = UIApplication.shared.delegate as! AppDelegate!
        let currentUser = delegate?.currentUser
    
        teamLabel.text = team?.teamName
        
        let teamManager = TeamManager()
        if teamManager.isTeamCaptain(user: currentUser!, team: self.team!){
            captainStar.isHidden = false
        }
        
        buildButton.addTarget(self, action: #selector(buildButtonClicked), for: .touchUpInside)
    }
    
    @objc func buildButtonClicked(_ sender: AnyObject?) {
        LandingActivity().navigateToTeamBuild(team: self.team!)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
            return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "teamCell", for: indexPath) as! TeamCellTeamFrag
        
        
        return cell
    }
    
}
