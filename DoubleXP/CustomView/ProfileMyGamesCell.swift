//
//  ProfileMyGamesCell.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 10/31/20.
//  Copyright © 2020 Peterson, Toussaint. All rights reserved.
//

import Foundation
import UIKit

class ProfileMyGamesCell: UITableViewCell {
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
}
