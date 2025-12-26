//
//  ProfileMyGamesCell.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 10/31/20.
//  Copyright © 2020 Peterson, Toussaint. All rights reserved.
//

import Foundation
import UIKit

class ProfileMyGamesCell: UITableViewCell, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var gamesCell: UITableView!
    @IBOutlet weak var noTagCover: UIView!
    var payload = [GamerConnectGame]()
    var userForProfile: User?
    
    func setupGames(){
        payload = [GamerConnectGame]()
        let delegate = UIApplication.shared.delegate as! AppDelegate
        //setup(gamesEmpty: delegate.currentProfileFrag!.userForProfile!.games.isEmpty)
    }
    
    private func setup(gamesEmpty: Bool) {
        if(!gamesEmpty){
            let delegate = UIApplication.shared.delegate as! AppDelegate
            /*for game in delegate.currentProfileFrag!.userForProfile!.games{
                for gcGame in delegate.gcGames{
                    if(game == gcGame.gameName){
                        self.payload.append(gcGame)
                    }
                }
            }*/
            self.gamesCell.dataSource = self
            self.gamesCell.delegate = self
            self.gamesCell.reloadData()
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.payload.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "game", for: indexPath) as! ProfileGameCell
        let current = self.payload[indexPath.item]
        /*let url = URL(string: url)
        if (url != nil) {
            ImageLoader.shared.loadImage(from: current.imageUrl) { [weak self] image in
                guard let self = self else { return }
                cell.gameBack.image = image
            }
        }*/
        cell.gameBack.contentMode = .scaleAspectFill
        cell.gameBack.clipsToBounds = true
        cell.gameName.text = current.gameName
        return cell
    }
}
