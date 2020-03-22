//
//  FreeAgentFront.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 12/13/19.
//  Copyright © 2019 Peterson, Toussaint. All rights reserved.
//

import UIKit
import Firebase
import ImageLoader
import moa
import MSPeekCollectionViewDelegateImplementation

class FreeAgentFront: ParentVC, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, MSPeekImplementationDelegate {
    var user: User!
    var team: TeamObject?
    var games = [GamerConnectGame]()
    var chosenGame = ""
    var currentPos = 0
    
    @IBOutlet weak var continueButton: UIButton!
    @IBOutlet weak var nextButton: UIImageView!
    @IBOutlet weak var gcGameList: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let delegate = UIApplication.shared.delegate as! AppDelegate
        games = delegate.gcGames
        
        gcGameList.delegate = self
        gcGameList.dataSource = self
        //gcGameList.configureForPeekingDelegate()
        
        handleNextButton(activate: false)
        
        navDictionary = ["state": "backOnly"]
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.currentLanding?.updateNavigation(currentFrag: self)
        
        self.pageName = "Free Agent Front"
        delegate.addToNavStack(vc: self)
        
        continueButton.addTarget(self, action: #selector(nextClicked), for: .touchUpInside)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return games.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! homeGCCell
        
        let game = games[indexPath.item]
        cell.backgroundImage.moa.url = game.imageUrl
        cell.backgroundImage.contentMode = .scaleAspectFill
        cell.backgroundImage.clipsToBounds = true
        
        cell.hook.text = games[indexPath.item].gameName
        
        if(self.chosenGame == games[indexPath.item].gameName){
            cell.cover.isHidden = false
        }
        else{
            cell.cover.isHidden = true
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = self.gcGameList.cellForItem(at: indexPath) as! homeGCCell
        
        if(chosenGame != games[indexPath.item].gameName){
            chosenGame = games[indexPath.item].gameName
            cell.cover.isHidden = false
            //cell.hook.textColor = UIColor.white
        }
        else{
            chosenGame = ""
            cell.cover.isHidden = true
            //cell.hook.textColor = UIColor.black
        }
        
        for gameCell in gcGameList.visibleCells {
            if (cell != gameCell as! homeGCCell){
                (gameCell as! homeGCCell).cover.isHidden = true
                //(gameCell as! homeGCCell).gameName.textColor = UIColor.black
            }
        }
        
        handleNextButton(activate: chosenGame != "")
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        return CGSize(width: 280, height: 140)
    }
    
    private func handleNextButton(activate: Bool){
        if(activate){
            continueButton.alpha = 1
            
            continueButton.isUserInteractionEnabled = true
        }
        else{
            continueButton.alpha = 0.4
            continueButton.isUserInteractionEnabled = false
        }
    }
    
    @objc func cellTapped(_ sender: AnyObject?) {
        let indexPath = IndexPath(row: self.currentPos, section: 0)
        
        let cell = self.gcGameList.cellForItem(at: indexPath) as! homeGCCell
        
        if(chosenGame != games[indexPath.item].gameName){
            chosenGame = games[indexPath.item].gameName
            cell.cover.isHidden = false
            //cell.hook.textColor = UIColor.white
        }
        else{
            chosenGame = ""
            cell.cover.isHidden = true
            //cell.hook.textColor = UIColor.black
        }
        
        for gameCell in gcGameList.visibleCells {
            if (cell != gameCell as! homeGCCell){
                (gameCell as! faQuizGameCell).cover.isHidden = true
                (gameCell as! faQuizGameCell).gameName.textColor = UIColor.black
            }
        }
        
        handleNextButton(activate: chosenGame != "")
    }
    
    @objc func nextClicked(_ sender: AnyObject?) {
        guard self.chosenGame != "" else { return }
        
        var chosenGame: GamerConnectGame? = nil
        for game in games{
            if(self.chosenGame == game.gameName){
                chosenGame = game
                break
            }
        }
        
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let currentUser = delegate.currentUser
        
        guard chosenGame != nil else { return }
        
        LandingActivity().navigateToFreeAgentQuiz(team: nil, gcGame: chosenGame!, currentUser: currentUser!)
    }
}
