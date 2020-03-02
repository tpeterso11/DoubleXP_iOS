//
//  TeamBuildFA.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 12/3/19.
//  Copyright © 2019 Peterson, Toussaint. All rights reserved.
//
import UIKit
import Firebase
import moa

class TeamBuildFA: ParentVC, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    var team: TeamObject?
    var currentUser: User?
    var selectedGame: GamerConnectGame?
    var cellHeights: [CGFloat] = []
    
    var availableTeamNeed = [String]()
    var selectedNeeds = [String]()
    @IBOutlet weak var topBorder: UIView!
    @IBOutlet weak var bottomBorder: UIView!
    @IBOutlet weak var mainImage: UIImageView!
    
    @IBOutlet weak var searchButtonCaptain: UIButton!
    @IBOutlet weak var saveChanges: UIButton!
    @IBOutlet weak var captainCover: UIView!
    @IBOutlet weak var captainControls: UIView!
    @IBOutlet weak var teamNeeds: UICollectionView!
    @IBOutlet weak var searchButton: UIButton!
    
    enum Const {
           static let closeCellHeight: CGFloat = 75
           static let openCellHeight: CGFloat = 235
           static let rowsCount = 1
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let delegate = UIApplication.shared.delegate as! AppDelegate
        currentUser = delegate.currentUser
    
        self.pageName = "Team Build Free Agent"
        delegate.navStack.append(self)
        
        for game in delegate.gcGames{
            if(game.gameName == team!.games[0]){
                self.selectedGame = game
                break
            }
        }
        
        captainCover.isHidden = true
        captainControls.isHidden = false
        
        searchButtonCaptain.addTarget(self, action: #selector(searchButtonClicked), for: .touchUpInside)
        
        if(selectedGame != nil && (!(selectedGame?.teamNeeds.isEmpty)!)){
            self.selectedNeeds.append(contentsOf: team!.selectedTeamNeeds)
            createData()
        }
    }
    
    private func createData(){
        teamNeeds.delegate = self
        teamNeeds.dataSource = self
        
        let top = CGAffineTransform(translationX: 0, y: -10)
        UIView.animate(withDuration: 0.8, delay: 0.2, options: [], animations: {
            self.teamNeeds.alpha = 1
            self.teamNeeds.transform = top
        }, completion: nil)
    }
    
    @objc func searchButtonClicked(_ sender: AnyObject?) {
        //send up any changes to DB.
        
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let currentLanding = delegate.currentLanding
        
        currentLanding!.navigateToTeamFreeAgentResults(team: self.team!)
    }
    
    @objc func saveClicked(_ sender: AnyObject?) {
        //send up any changes to DB.
        let ref = Database.database().reference().child("Teams").child(team!.teamName)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            if(snapshot.exists()){
                ref.child("selectedTeamNeeds").setValue(self.selectedNeeds)
            }
            
            let userRef = Database.database().reference().child("Users").child(self.currentUser!.uId).child("teams").child(self.team!.teamName)
            if(snapshot.exists()){
                userRef.child("selectedTeamNeeds").setValue(self.selectedNeeds)
            }
            
            self.team!.selectedTeamNeeds = self.selectedNeeds
            
            UIView.transition(with: self.saveChanges, duration: 0.3, options: .curveEaseInOut, animations: {
              self.saveChanges.backgroundColor = .green
              self.saveChanges.setTitle("saved.", for: .normal)
              self.saveChanges.setTitleColor(.white, for: .normal)
            })
            //color fill green
            
        }) { (error) in
            UIView.transition(with: self.saveChanges, duration: 0.3, options: .curveEaseInOut, animations: {
              self.saveChanges.backgroundColor = .red
              self.saveChanges.setTitle("error.", for: .normal)
              self.saveChanges.setTitleColor(.white, for: .normal)
            })
            //color fill red
            print(error.localizedDescription)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.selectedGame?.teamNeeds.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! TeamNeedsCell
        
        let current = team?.teamNeeds[indexPath.item]
        cell.needLabel.text = current
        
        if(selectedNeeds.contains((self.selectedGame?.teamNeeds[indexPath.item])!)){
            cell.cover.isHidden = false
            cell.doWeNeed.text = "we need a..."
            cell.doWeNeed.font = UIFont.systemFont(ofSize: 18.0, weight: UIFont.Weight.semibold)
        }
        else{
            cell.cover.isHidden = true
            cell.doWeNeed.font = UIFont.systemFont(ofSize: 17.0, weight: UIFont.Weight.regular)
            cell.doWeNeed.text = "do we need a..."
        }

        cell.layer.shadowColor = UIColor.black.cgColor
        cell.layer.shadowOffset = CGSize(width: 0, height: 2.0)
        cell.layer.shadowRadius = 2.0
        cell.layer.shadowOpacity = 0.5
        cell.layer.masksToBounds = false
        cell.layer.shadowPath = UIBezierPath(roundedRect: cell.bounds, cornerRadius: cell.contentView.layer.cornerRadius).cgPath
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let manager = GamerProfileManager()
        if(manager.getGamerTagForGame(gameName: team!.games[0]) == team!.teamCaptain){
            if(!selectedNeeds.contains((team?.teamNeeds[indexPath.item])!)){
                selectedNeeds.append(team?.teamNeeds[indexPath.item] ?? "")
                
                let cell = collectionView.cellForItem(at: indexPath) as! TeamNeedsCell
                cell.cover.isHidden = false
                cell.doWeNeed.text = "we need a..."
                cell.doWeNeed.font = UIFont.systemFont(ofSize: 18.0, weight: UIFont.Weight.semibold)
            }
            else{
                selectedNeeds = selectedNeeds.filter{$0 != team?.teamNeeds[indexPath.item]}
                
                let cell = collectionView.cellForItem(at: indexPath) as! TeamNeedsCell
                cell.cover.isHidden = true
                cell.doWeNeed.font = UIFont.systemFont(ofSize: 17.0, weight: UIFont.Weight.regular)
                cell.doWeNeed.text = "do we need a..."
            }
            
            checkSaveButton()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.bounds.size.width - 20, height: CGFloat(100))
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {

        let outerColor = UIColor(white: 1.0, alpha: 0.0).cgColor
        let innerColor = UIColor(white: 1.0, alpha: 1.0).cgColor

        var colors = [CGColor]()

        if scrollView.contentOffset.y + scrollView.contentInset.top <= 0 {
            colors = [innerColor, innerColor, innerColor, outerColor]
        } else if scrollView.contentOffset.y + scrollView.frame.size.height >= scrollView.contentSize.height {
            colors = [outerColor, innerColor, innerColor, innerColor]
        } else {
            colors = [outerColor, innerColor, innerColor, outerColor]
        }

        if let mask = scrollView.layer.mask as? CAGradientLayer {
            mask.colors = colors

            CATransaction.begin()
            CATransaction.setDisableActions(true)
            mask.position = CGPoint(x: 0.0, y: scrollView.contentOffset.y)
            CATransaction.commit()
        }

    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if self.teamNeeds.layer.mask == nil {

            //If you are using auto layout
            //self.view.layoutIfNeeded()

            let maskLayer: CAGradientLayer = CAGradientLayer()

            maskLayer.locations = [0.0, 0.2, 0.8, 1.0]
            let width = self.teamNeeds.frame.size.width
            let height = self.teamNeeds.frame.size.height
            maskLayer.bounds = CGRect(x: 0.0, y: 0.0, width: width, height: height)
            maskLayer.anchorPoint = CGPoint.zero

            self.teamNeeds.layer.mask = maskLayer
        }

        scrollViewDidScroll(self.teamNeeds)
    }
    
    private func checkSaveButton(){
        var changed = false
        
        if(self.selectedNeeds.count < team!.selectedTeamNeeds.count){
            changed = true
        }
        
        if(self.selectedNeeds.count > team!.selectedTeamNeeds.count){
            changed = true
        }
        
        //so, if it's not obvious that the number of choices has changed, then we will check the values.
        if(!changed){
            for value in self.selectedNeeds{
                if(!team!.selectedTeamNeeds.contains(value)){
                    changed = true
                }
            }
        }
        
        if(changed){
            self.saveChanges.isUserInteractionEnabled = true
            self.saveChanges.addTarget(self, action: #selector(saveClicked), for: .touchUpInside)
            
            UIView.transition(with: self.saveChanges, duration: 0.3, options: .curveEaseInOut, animations: {
                if(self.saveChanges.titleLabel?.text == "saved." || self.saveChanges.titleLabel?.text == "error."){
                    self.saveChanges.setTitle("Save Changes", for: .normal)
                    self.saveChanges.backgroundColor = #colorLiteral(red: 0.5893185735, green: 0.04998416454, blue: 0.09506303817, alpha: 1)
                }
              self.saveChanges.alpha = 1
            })
        }
        else{
            self.saveChanges.isUserInteractionEnabled = false
            
            UIView.transition(with: self.saveChanges, duration: 0.3, options: .curveEaseInOut, animations: {
              self.saveChanges.alpha = 0.4
            })
        }
    }
    
}

