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

class FreeAgentFront: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, MSPeekImplementationDelegate {
    var user: User!
    var team: TeamObject?
    var games = [GamerConnectGame]()
    var chosenGame = ""
    var currentPos = 0
    
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
        
        chosenGame = "NBA 2K20"
        handleNextButton(activate: true)
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
                (gameCell as! faQuizGameCell).cover.isHidden = true
                (gameCell as! faQuizGameCell).gameName.textColor = UIColor.black
            }
        }
        
        handleNextButton(activate: chosenGame != "")
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        return CGSize(width: 280, height: 180)
    }
    
    private func handleNextButton(activate: Bool){
        if(activate){
            nextButton.alpha = 1
            
            let singleTap = UITapGestureRecognizer(target: self, action: #selector(nextClicked))
            nextButton.isUserInteractionEnabled = true
            nextButton.addGestureRecognizer(singleTap)
        }
        else{
            nextButton.alpha = 0.4
            nextButton.isUserInteractionEnabled = false
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
