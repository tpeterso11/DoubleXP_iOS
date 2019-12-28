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
    
    @IBOutlet weak var gcGames: UICollectionView!
    @IBOutlet weak var nextButton: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let delegate = UIApplication.shared.delegate as! AppDelegate
        games = delegate.gcGames
        
        gcGames.configureForPeekingDelegate()
        gcGames.delegate = self
        gcGames.dataSource = self
        
        handleNextButton(activate: false)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return games.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! faQuizGameCell
        
        let game = games[indexPath.item]
        cell.gameBack.moa.url = game.imageUrl
        cell.gameBack.contentMode = .scaleAspectFill
        cell.gameBack.clipsToBounds = true
        
        cell.gameName.text = games[indexPath.item].gameName
        
        cell.contentView.layer.cornerRadius = 2.0
        cell.contentView.layer.borderWidth = 1.0
        cell.contentView.layer.borderColor = UIColor.clear.cgColor
        cell.contentView.layer.masksToBounds = true
        
        cell.layer.shadowColor = UIColor.black.cgColor
        cell.layer.shadowOffset = CGSize(width: 0, height: 2.0)
        cell.layer.shadowRadius = 2.0
        cell.layer.shadowOpacity = 0.5
        cell.layer.masksToBounds = false
        cell.layer.shadowPath = UIBezierPath(roundedRect: cell.bounds, cornerRadius: cell.contentView.layer.cornerRadius).cgPath
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = self.gcGames.cellForItem(at: indexPath) as! faQuizGameCell
        
        if(chosenGame != games[indexPath.item].gameName){
            chosenGame = games[indexPath.item].gameName
            cell.cover.isHidden = false
            cell.gameName.textColor = UIColor.white
        }
        else{
            chosenGame = ""
            cell.cover.isHidden = true
            cell.gameName.textColor = UIColor.black
        }
        
        for gameCell in gcGames.visibleCells {
            if (cell != gameCell as! faQuizGameCell){
                (gameCell as! faQuizGameCell).cover.isHidden = true
                (gameCell as! faQuizGameCell).gameName.textColor = UIColor.black
            }
        }
        
        handleNextButton(activate: chosenGame != "")
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let kWhateverHeightYouWant = 150
        
        return CGSize(width: collectionView.bounds.size.width, height: CGFloat(kWhateverHeightYouWant))
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
