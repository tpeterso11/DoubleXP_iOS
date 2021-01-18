//
//  NewRegGameCell.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 9/20/20.
//  Copyright © 2020 Peterson, Toussaint. All rights reserved.
//

import Foundation
import UIKit
import Lottie
import UnderLineTextField
import CollectionPickerView

class NewRegGameCell: UITableViewCell/*, UICollectionViewDataSource, UICollectionViewDelegate*/ {
    @IBOutlet weak var gameBack: UIImageView!
    @IBOutlet weak var gameName: UILabel!
    @IBOutlet weak var cover: UIView!
    @IBOutlet weak var confirmAnimation: AnimationView!
    @IBOutlet weak var backConsole: UIView!
    @IBOutlet weak var gamerTagField: UnderLineTextField!
    @IBOutlet weak var gamerTagContinue: UIButton!
    @IBOutlet weak var gamerTagCancel: UIButton!
    @IBOutlet weak var consoleBack: UIView!
    @IBOutlet weak var consolePicker: CollectionPickerView!
    
    var open = false
    var view: NewRegGameCell?
    var game: GamerConnectGame?
    var consoles: [String]?
    var selectedGameNames = [String]()
    var selectedCell = false
    
    func initialize(game: GamerConnectGame, consoles: [String], selectedGameNames: [String]) {
        self.game = game
        self.consoles = consoles
        self.selectedGameNames = selectedGameNames
        gamerTagField.addTarget(self, action: #selector(self.textFieldDidChange(_:)), for: .editingChanged)
        
        if(selectedCell){
            showSelected()
        } else {
            clearSelection()
        }
    }
    
    private func showSelected(){
        self.selectedCell = true
        self.cover.isHidden = false
        self.confirmAnimation.currentFrame = 1500
    }
    
    private func clearSelection(){
        if(cover.alpha == 1){
            hideCover()
            return
        }
        self.selectedCell = false
        self.confirmAnimation.currentFrame = 0
        gamerTagField.text = ""
        self.gamerTagContinue.alpha = 0.5
        self.gamerTagContinue.isUserInteractionEnabled = false
    }
    
    private func hideCover(){
        UIView.animate(withDuration: 0.5, delay: 0.2, options: [], animations: {
            self.cover.alpha = 0
        }, completion: { (finished: Bool) in
            self.clearSelection()
        })
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        if(textField.text!.count > 4){
            self.gamerTagContinue.alpha = 1
            self.gamerTagContinue.addTarget(self, action: #selector(gamerTagEntered), for: .touchUpInside)
            self.gamerTagContinue.isUserInteractionEnabled = true
        } else {
            self.gamerTagContinue.alpha = 0.5
            self.gamerTagContinue.isUserInteractionEnabled = false
        }
    }
    
    @objc private func gamerTagEntered(){
        if(consoles?.count == 1){
            self.flipBack()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [self] in
                self.animateAdded()
            }
        } else {
            showConsole()
        }
    }
    
    private func showConsole(){
        self.backConsole.isHidden = true
        self.consoleBack.isHidden = false
//_todo
//        self.consolePicker.dataSource = self
    }
    
    private func animateAdded(){
        if(!self.selectedGameNames.contains(self.game!.gameName)){
            self.selectedCell = true
            UIView.animate(withDuration: 0.8, animations: {
                self.cover.alpha = 1
            }, completion: { (finished: Bool) in
                self.confirmAnimation.play(toFrame: 500)
            })
        } else {
            self.confirmAnimation.play { (false) in
                self.selectedCell = false
                UIView.animate(withDuration: 0.5, delay: 0.2, options: [], animations: {
                    self.cover.alpha = 0
                }, completion: nil)
            }
        }
    }
    
    @IBAction func flip(sender: UIView){
        if(open){
            self.open = false
            backConsole.isHidden = true
            
            gamerTagCancel.isUserInteractionEnabled = false
        } else {
            clearSelection()
            self.open = true
            backConsole.isHidden = false
            gamerTagCancel.addTarget(self, action: #selector(flipBack), for: .touchUpInside)
        }
        UIView.transition(with: sender, duration: 0.8, options: .transitionFlipFromTop, animations: nil, completion: nil)
    }
    
    @objc private func flipBack(){
        if(self.contentView != nil){
            self.open = false
            backConsole.isHidden = true
            
            UIView.transition(with: self.contentView, duration: 0.8, options: .transitionFlipFromBottom, animations: nil, completion: nil)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return consoles?.count ?? 0
    }
}
