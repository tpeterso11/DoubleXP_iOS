//
//  GCRegistration.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 9/19/20.
//  Copyright © 2020 Peterson, Toussaint. All rights reserved.
//

import Foundation
import UIKit
import Lottie
import UnderLineTextField
import SPStorkController

class GCRegistration: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var gcGameTable: UITableView!
    @IBOutlet weak var gameSearchLabel: UILabel!
    @IBOutlet weak var gameSearchField: UnderLineTextField!
    @IBOutlet weak var gamesLayout: UIView!
    @IBOutlet weak var consoleContinue: UIButton!
    @IBOutlet weak var mobileCover: UIView!
    @IBOutlet weak var pcCover: UIView!
    @IBOutlet weak var xboxCover: UIView!
    @IBOutlet weak var nintendoCover: UIView!
    @IBOutlet weak var psCover: UIView!
    @IBOutlet weak var mobileBox: UIView!
    @IBOutlet weak var pcBox: UIView!
    @IBOutlet weak var xboxBox: UIView!
    @IBOutlet weak var nintendoBox: UIView!
    @IBOutlet weak var psBox: UIView!
    @IBOutlet weak var consoleLayout: UIView!
    @IBOutlet weak var drawer: UIView!
    @IBOutlet weak var startLayout: UIView!
    @IBOutlet weak var startProfileButton: UIButton!
    @IBOutlet weak var celebrateAnimation: AnimationView!
    var consoles = [String]()
    var constraint : NSLayoutConstraint?
    private var selectedGameNames = [String]()
    private var availableGames = [GamerConnectGame]()
    private var selectedGames = [GamerConnectGame]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.celebrateAnimation.animationSpeed = 0.6
        self.celebrateAnimation.loopMode = .playOnce
        self.celebrateAnimation.play()
        
        self.startProfileButton.addTarget(self, action: #selector(startButtonClicked), for: .touchUpInside)
        
        let delegate = UIApplication.shared.delegate as! AppDelegate
        var list = [GamerConnectGame]()
        for game in delegate.gcGames {
            if(game.available == "true"){
                list.append(game)
            }
        }
        
        availableGames = list
        
        psBox.layer.cornerRadius = 15.0
        psBox.layer.borderWidth = 1.0
        psBox.layer.borderColor = UIColor.clear.cgColor
        psBox.layer.masksToBounds = true
        
        psBox.layer.shadowColor = UIColor.black.cgColor
        psBox.layer.shadowOffset = CGSize(width: 0, height: 2.0)
        psBox.layer.shadowRadius = 2.0
        psBox.layer.shadowOpacity = 0.5
        psBox.layer.masksToBounds = false
        psBox.layer.shadowPath = UIBezierPath(roundedRect: psBox.bounds, cornerRadius: psBox.layer.cornerRadius).cgPath
        
        let psTap = UITapGestureRecognizer(target: self, action: #selector(psButtonClicked))
        psBox.isUserInteractionEnabled = true
        psBox.addGestureRecognizer(psTap)
        
        nintendoBox.layer.cornerRadius = 15.0
        nintendoBox.layer.borderWidth = 1.0
        nintendoBox.layer.borderColor = UIColor.clear.cgColor
        nintendoBox.layer.masksToBounds = true
        
        nintendoBox.layer.shadowColor = UIColor.black.cgColor
        nintendoBox.layer.shadowOffset = CGSize(width: 0, height: 2.0)
        nintendoBox.layer.shadowRadius = 2.0
        nintendoBox.layer.shadowOpacity = 0.5
        nintendoBox.layer.masksToBounds = false
        nintendoBox.layer.shadowPath = UIBezierPath(roundedRect: nintendoBox.bounds, cornerRadius: nintendoBox.layer.cornerRadius).cgPath
        
        let nintendoTap = UITapGestureRecognizer(target: self, action: #selector(nintendoButtonClicked))
        nintendoBox.isUserInteractionEnabled = true
        nintendoBox.addGestureRecognizer(nintendoTap)
        
        xboxBox.layer.cornerRadius = 15.0
        xboxBox.layer.borderWidth = 1.0
        xboxBox.layer.borderColor = UIColor.clear.cgColor
        xboxBox.layer.masksToBounds = true
        
        xboxBox.layer.shadowColor = UIColor.black.cgColor
        xboxBox.layer.shadowOffset = CGSize(width: 0, height: 2.0)
        xboxBox.layer.shadowRadius = 2.0
        xboxBox.layer.shadowOpacity = 0.5
        xboxBox.layer.masksToBounds = false
        xboxBox.layer.shadowPath = UIBezierPath(roundedRect: xboxBox.bounds, cornerRadius: xboxBox.layer.cornerRadius).cgPath
        
        let xboxTap = UITapGestureRecognizer(target: self, action: #selector(xboxButtonClicked))
        xboxBox.isUserInteractionEnabled = true
        xboxBox.addGestureRecognizer(xboxTap)
        
        pcBox.layer.cornerRadius = 15.0
        pcBox.layer.borderWidth = 1.0
        pcBox.layer.borderColor = UIColor.clear.cgColor
        pcBox.layer.masksToBounds = true
        
        pcBox.layer.shadowColor = UIColor.black.cgColor
        pcBox.layer.shadowOffset = CGSize(width: 0, height: 2.0)
        pcBox.layer.shadowRadius = 2.0
        pcBox.layer.shadowOpacity = 0.5
        pcBox.layer.masksToBounds = false
        pcBox.layer.shadowPath = UIBezierPath(roundedRect: pcBox.bounds, cornerRadius: pcBox.layer.cornerRadius).cgPath
        
        let pcTap = UITapGestureRecognizer(target: self, action: #selector(pcButtonClicked))
        pcBox.isUserInteractionEnabled = true
        pcBox.addGestureRecognizer(pcTap)
        
        mobileBox.layer.cornerRadius = 15.0
        mobileBox.layer.borderWidth = 1.0
        mobileBox.layer.borderColor = UIColor.clear.cgColor
        mobileBox.layer.masksToBounds = true
        
        mobileBox.layer.shadowColor = UIColor.black.cgColor
        mobileBox.layer.shadowOffset = CGSize(width: 0, height: 2.0)
        mobileBox.layer.shadowRadius = 2.0
        mobileBox.layer.shadowOpacity = 0.5
        mobileBox.layer.masksToBounds = false
        mobileBox.layer.shadowPath = UIBezierPath(roundedRect: mobileBox.bounds, cornerRadius: mobileBox.layer.cornerRadius).cgPath
        
        let mobileTap = UITapGestureRecognizer(target: self, action: #selector(mobileButtonClicked))
        mobileBox.isUserInteractionEnabled = true
        mobileBox.addGestureRecognizer(mobileTap)
        
        self.gameSearchField.setRightPaddingPoints(20)
    }
    
    @objc private func psButtonClicked(){
        UIView.animate(withDuration: 0.3, animations: {
            if(self.consoles.contains("ps")){
                self.psCover.alpha = 0
            } else {
                self.psCover.alpha = 1
            }
            
            if(self.consoles.contains("ps")){
                self.consoles.remove(at: self.consoles.index(of: "ps")!)
            } else {
                self.consoles.append("ps")
            }
            
            self.consolesCheckContinueButton()
        }, completion: nil)
    }
    
    @objc private func nintendoButtonClicked(){
        UIView.animate(withDuration: 0.3, animations: {
            if(self.consoles.contains("nintendo")){
                self.nintendoCover.alpha = 0
            } else {
                self.nintendoCover.alpha = 1
            }
            
            if(self.consoles.contains("nintendo")){
                self.consoles.remove(at: self.consoles.index(of: "nintendo")!)
            } else {
                self.consoles.append("nintendo")
            }
            
            self.consolesCheckContinueButton()
        }, completion: nil)
    }
    
    @objc private func pcButtonClicked(){
        UIView.animate(withDuration: 0.3, animations: {
            if(self.consoles.contains("pc")){
                self.pcCover.alpha = 0
            } else {
                self.pcCover.alpha = 1
            }
            
            if(self.consoles.contains("pc")){
                self.consoles.remove(at: self.consoles.index(of: "pc")!)
            } else {
                self.consoles.append("pc")
            }
            
            self.consolesCheckContinueButton()
        }, completion: nil)
    }
    
    @objc private func xboxButtonClicked(){
        UIView.animate(withDuration: 0.3, animations: {
            if(self.consoles.contains("xbox")){
                self.xboxCover.alpha = 0
            } else {
                self.xboxCover.alpha = 1
            }
            
            if(self.consoles.contains("xbox")){
                self.consoles.remove(at: self.consoles.index(of: "xbox")!)
            } else {
                self.consoles.append("xbox")
            }
            
            self.consolesCheckContinueButton()
        }, completion: nil)
    }
    
    @objc private func mobileButtonClicked(){
        UIView.animate(withDuration: 0.3, animations: {
            if(self.consoles.contains("mobile")){
                self.mobileCover.alpha = 0
            } else {
                self.mobileCover.alpha = 1
            }
            
            if(self.consoles.contains("mobile")){
                self.consoles.remove(at: self.consoles.index(of: "mobile")!)
            } else {
                self.consoles.append("mobile")
            }
            
             self.consolesCheckContinueButton()
        }, completion: nil)
    }

    
    @objc private func startButtonClicked(){
        let layoutAnim = CGAffineTransform(translationX: 0, y: 10)
        let layoutAnim2 = CGAffineTransform(translationX: 0, y:-10)
        UIView.animate(withDuration: 0.8, animations: {
            self.startLayout.alpha = 0
            self.startLayout.transform = layoutAnim
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                UIView.animate(withDuration: 0.5, delay: 0.2, options: [], animations: {
                   self.consoleLayout.alpha = 1
                   self.consoleLayout.transform = layoutAnim2
                }, completion: nil)
            }
        }, completion: nil)
    }
    
    private func consolesCheckContinueButton(){
        let layoutReturn = CGAffineTransform(translationX: 0, y: 0)
        let layoutAnim2 = CGAffineTransform(translationX: 0, y: 100)
        if(consoles.isEmpty && self.consoleContinue.alpha == 1){
            UIView.animate(withDuration: 0.5, animations: {
                self.consoleContinue.alpha = 0
                self.consoleContinue.transform = layoutAnim2
            }, completion: nil)
        } else if(!consoles.isEmpty && self.consoleContinue.alpha == 0){
            UIView.animate(withDuration: 0.5, animations: {
                self.consoleContinue.alpha = 1
                self.consoleContinue.transform = layoutReturn
                self.consoleContinue.addTarget(self, action: #selector(self.progressToGames), for: .touchUpInside)
            }, completion: nil)
        }
    }
    
    @objc private func progressToGames(){
        let layoutAnim = CGAffineTransform(translationX: -100, y: 0)
        let layoutAnim2 = CGAffineTransform(translationX: 0, y: -10)
        UIView.animate(withDuration: 0.8, animations: {
            self.consoleLayout.alpha = 0
            self.consoleLayout.transform = layoutAnim
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                UIView.animate(withDuration: 0.5, delay: 0.2, options: [], animations: {
                   self.gamesLayout.alpha = 1
                   self.gamesLayout.transform = layoutAnim
                }, completion: nil)
            }
        }, completion: { (finished: Bool) in
            UIView.animate(withDuration: 0.5, delay: 0.8, options: [], animations: {
                self.gameSearchField.alpha = 1
                self.gameSearchLabel.alpha = 1
                self.gameSearchField.transform = layoutAnim2
                self.gameSearchLabel.transform = layoutAnim2
                
                self.gcGameTable.dataSource = self
                self.gcGameTable.delegate = self
                self.gcGameTable.reloadData()
            }, completion: nil)
        })
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.availableGames.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let current = availableGames[indexPath.item]
        let cell = tableView.dequeueReusableCell(withIdentifier: "game", for: indexPath) as! NewRegGameCell
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
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
        cell.gameName.text = current.gameName
        
        if(self.selectedGameNames.contains(current.gameName)){
            cell.cover.alpha = 1
            cell.confirmAnimation.currentFrame = 500
        } else {
            cell.cover.alpha = 0
            cell.confirmAnimation.currentFrame = 0
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath) as! NewRegGameCell
        let current = self.availableGames[indexPath.item]
        
        self.launchOverlay()
        /*if(!self.selectedGameNames.contains(current.gameName)){
            UIView.animate(withDuration: 0.8, animations: {
                cell.cover.alpha = 1
            }, completion: { (finished: Bool) in
                cell.confirmAnimation.play(toFrame: 500)
            })
        } else {
            cell.confirmAnimation.play { (false) in
                UIView.animate(withDuration: 0.5, delay: 0.2, options: [], animations: {
                    cell.cover.alpha = 0
                }, completion: nil)
            }
        }*/
    }
    
    @objc private func launchOverlay(){
        let controller = UIViewController()
        self.presentAsStork(controller)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 180.0;
    }
}
