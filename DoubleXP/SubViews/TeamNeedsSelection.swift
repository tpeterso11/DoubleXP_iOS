//
//  TeamNeedsSelection.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 11/24/19.
//  Copyright © 2019 Peterson, Toussaint. All rights reserved.
//

import UIKit
import Firebase
import moa
import MSPeekCollectionViewDelegateImplementation

class TeamNeedsSelection: ParentVC, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    var team: TeamObject? = nil
    
    
    var selectedNeeds = [String]()
    
    @IBOutlet weak var completeButton: UIButton!
    
    @IBOutlet weak var sub: UILabel!
    @IBOutlet weak var teamNeedsCollection: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        completeButton.addTarget(self, action: #selector(nextButtonClicked), for: .touchUpInside)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.teamNeedsCollection.delegate = self
            self.teamNeedsCollection.dataSource = self
            
            let top = CGAffineTransform(translationX: 0, y: -20)
            UIView.animate(withDuration: 0.8, animations: {
                self.completeButton.alpha = 1
                self.sub.alpha = 1
                self.teamNeedsCollection.alpha = 1
                self.teamNeedsCollection.transform = top
            }, completion: nil)
        }
    }
    
    @objc func nextButtonClicked(_ sender: AnyObject?) {
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let currentLanding = delegate.currentLanding
        
        if(selectedNeeds.isEmpty){
            currentLanding?.stackDepth -= 1
            currentLanding?.navigateToTeamDashboard(team: team!, newTeam: true)
        }
        else{
            let ref = Database.database().reference().child("Teams").child(team!.teamName)
            ref.child("selectedTeamNeeds").setValue(selectedNeeds)
            
            let userRef = Database.database().reference().child("Users").child(delegate.currentUser!.uId).child("teams").child(team!.teamName)
            userRef.child("selectedTeamNeeds").setValue(selectedNeeds)
            
            for team in delegate.currentUser!.teams{
                if(team.teamName == self.team!.teamName){
                    team.selectedTeamNeeds.append(contentsOf: self.selectedNeeds)
                }
            }
            
            currentLanding?.stackDepth -= 1
            currentLanding?.navigateToTeamDashboard(team: team!, newTeam: true)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return team?.teamNeeds.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! TeamNeedsCell
        
        let current = team?.teamNeeds[indexPath.item]
        cell.needLabel.text = current
        
        if(selectedNeeds.contains((team?.teamNeeds[indexPath.item])!)){
            cell.cover.isHidden = false
            cell.doWeNeed.text = "we need a..."
            cell.doWeNeed.font = UIFont.systemFont(ofSize: 18.0, weight: UIFont.Weight.semibold)
        }
        else{
            cell.cover.isHidden = true
            cell.doWeNeed.font = UIFont.systemFont(ofSize: 17.0, weight: UIFont.Weight.regular)
            cell.doWeNeed.text = "do we need a..."
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
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
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.bounds.size.width - 20, height: CGFloat(100))
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if self.teamNeedsCollection.layer.mask == nil {

            //If you are using auto layout
            //self.view.layoutIfNeeded()

            let maskLayer: CAGradientLayer = CAGradientLayer()

            maskLayer.locations = [0.0, 0.2, 0.8, 1.0]
            let width = self.teamNeedsCollection.frame.size.width
            let height = self.teamNeedsCollection.frame.size.height
            maskLayer.bounds = CGRect(x: 0.0, y: 0.0, width: width, height: height)
            maskLayer.anchorPoint = CGPoint.zero

            self.teamNeedsCollection.layer.mask = maskLayer
        }

        scrollViewDidScroll(self.teamNeedsCollection)
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
}
