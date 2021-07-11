//
//  ProfileMyGamesCell.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 10/31/20.
//  Copyright © 2020 Peterson, Toussaint. All rights reserved.
//

import Foundation
import UIKit
import FoldingCell

class ProfileMyGamesCell: UITableViewCell, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var tableHeight: NSLayoutConstraint!
    @IBOutlet weak var gamesCell: UITableView!
    @IBOutlet weak var noTagCover: UIView!
    var payload = [GamerConnectGame]()
    var userForProfile: User?
    var cellHeights: [CGFloat] = []
    enum Const {
          static let closeCellHeight: CGFloat = 100
          static let openCellHeight: CGFloat = 280
          static let rowsCount = 1
   }
    
    func setupGames(){
        payload = [GamerConnectGame]()
        let delegate = UIApplication.shared.delegate as! AppDelegate
        setup(gamesEmpty: delegate.currentProfileFrag!.userForProfile!.games.isEmpty)
    }
    
    private func setup(gamesEmpty: Bool) {
        if(!gamesEmpty){
            let delegate = UIApplication.shared.delegate as! AppDelegate
            for game in delegate.currentProfileFrag!.userForProfile!.games{
                for gcGame in delegate.gcGames{
                    if(game == gcGame.gameName){
                        self.payload.append(gcGame)
                    }
                }
            }
            cellHeights = Array(repeating: Const.closeCellHeight, count: self.payload.count)
            self.gamesCell.estimatedRowHeight = Const.closeCellHeight
            self.gamesCell.rowHeight = UITableView.automaticDimension
            
            if #available(iOS 10.0, *) {
                self.gamesCell.refreshControl = UIRefreshControl()
                self.gamesCell.refreshControl?.addTarget(self, action: #selector(refreshHandler), for: .valueChanged)
            }
            
            self.gamesCell.delegate = self
            self.gamesCell.dataSource = self
            self.gamesCell.reloadData()
        }
    }
    
    @objc func refreshHandler() {
        let deadlineTime = DispatchTime.now() + .seconds(1)
        DispatchQueue.main.asyncAfter(deadline: deadlineTime, execute: { [weak self] in
            if #available(iOS 10.0, *) {
                self?.gamesCell.refreshControl?.endRefreshing()
            }
            self?.gamesCell.reloadData()
        })
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return payload.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! FoldingCellCell
        let current = self.payload[indexPath.item]
        
        cell.gameName.text = ""
        cell.developer.text = ""
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        var quizContained = ""
        for profile in appDelegate.currentProfileFrag!.profilePayload {
            if(profile.game == current.gameName){
                quizContained = profile.game
                break
            }
        }
        
        if(!quizContained.isEmpty){
            cell.quizAvailableContainer.isHidden = false
            
            appDelegate.currentProfileFrag!.gamesWithQuiz.append(quizContained)
        } else {
            cell.quizAvailableContainer.isHidden = true
        }
        
        let cache = appDelegate.imageCache
        if(cache.object(forKey: current.imageUrl as NSString) != nil){
            cell.gameBack.image = cache.object(forKey: current.imageUrl as NSString)
        } else {
            cell.gameBack.image = Utility.Image.placeholder
            cell.gameBack.moa.onSuccess = { image in
                cell.gameBack.image = image
                appDelegate.imageCache.setObject(image, forKey: current.imageUrl as NSString)
                return image
            }
            cell.gameBack.moa.url = current.imageUrl
        }
        cell.gameBack.contentMode = .scaleAspectFill
        cell.gameBack.clipsToBounds = true
        
        cell.coverGameName.text = current.gameName.lowercased()
        cell.gameName.text = current.gameName
        cell.developer.text = current.developer
        
        cell.statsAvailable.isHidden = true
        cell.statsAvailableContainer.isHidden = true
        
        /*var contained = ""
        for stat in appDelegate.currentProfileFrag!.userForProfile!.stats{
            if(stat.gameName == current.gameName){
                contained = stat.gameName
                break
            }
        }*/
        
        /*if(!contained.isEmpty){
            cell.statsAvailable.isHidden = false
            cell.statsAvailableContainer.isHidden = false
            
            appDelegate.currentProfileFrag!.gamesWithStats.append(contained)
        } else {
            cell.statsAvailable.isHidden = true
            cell.statsAvailableContainer.isHidden = true
        }*/
        
        cell.layoutMargins = UIEdgeInsets.zero
        cell.separatorInset = UIEdgeInsets.zero
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let current = self.payload[indexPath.item]
        
        if(delegate.currentProfileFrag!.gamesWithQuiz.contains(current.gameName)){
            delegate.currentProfileFrag?.showStatsOverlay(gameName: current.gameName, game: current)
        }
    }
    
    func tableView(_ tableview: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return cellHeights[indexPath.row]
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if(tableView == self.gamesCell){
            guard case let cell as FoldingCellCell = cell else {
                return
            }

            cell.backgroundColor = .clear

            if cellHeights[indexPath.row] == Const.closeCellHeight {
                cell.unfold(false, animated: false, completion: nil)
            } else {
                cell.unfold(true, animated: false, completion: nil)
            }
            //cell.number = indexPath.row
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.tableHeight?.constant = self.gamesCell.contentSize.height
        
        self.layoutIfNeeded()
            // do your thing
    }
}
