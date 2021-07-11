//
//  UpcomingGameDrawer.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 3/28/21.
//  Copyright © 2021 Peterson, Toussaint. All rights reserved.
//

import Foundation
import UIKit
import WebKit

class UpcomingGameDrawer: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, WKNavigationDelegate {
    
    @IBOutlet weak var wvShell: UIView!
    @IBOutlet weak var gameDescription: UILabel!
    @IBOutlet weak var trailerWV: WKWebView!
    @IBOutlet weak var gameStudio: UILabel!
    @IBOutlet weak var gameName: UILabel!
    @IBOutlet weak var releaseDate: UILabel!
    @IBOutlet weak var consoleCollection: UICollectionView!
    @IBOutlet weak var gameImage: UIImageView!
    @IBOutlet weak var trailerCollection: UICollectionView!
    var upcomingGame: UpcomingGame?
    var trailerPayload = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if(upcomingGame != nil){
            self.setUI()
        } else {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    private func setUI(){
        self.gameName.text = self.upcomingGame!.game
        self.gameStudio.text = self.upcomingGame!.developer + " presents:"
        self.gameDescription.text = self.upcomingGame!.gameDesc
        self.releaseDate.text = self.upcomingGame!.releaseDateProper
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let cache = appDelegate.imageCache
        if(cache.object(forKey: self.upcomingGame!.gameImageUrl as NSString) != nil){
            self.gameImage.image = cache.object(forKey: self.upcomingGame!.gameImageUrl as NSString)
        } else {
            self.gameImage.image = Utility.Image.placeholder
            self.gameImage.moa.onSuccess = { image in
                self.gameImage.image = image
                appDelegate.imageCache.setObject(image, forKey: self.upcomingGame!.gameImageUrl as NSString)
                return image
            }
            self.gameImage.moa.url = self.upcomingGame!.gameImageUrl
        }
        
        self.gameImage.contentMode = .scaleAspectFill
        self.gameImage.clipsToBounds = true
        
        let testBounds = CGRect(x: self.gameImage.bounds.minX, y: self.gameImage.bounds.minY, width: self.view.bounds.width, height: self.gameImage.bounds.height)
        //hero.layer.shadowPath = UIBezierPath(roundedRect: testBounds, cornerRadius: hero.layer.cornerRadius).cgPath
        
        let maskLayer = CAGradientLayer(layer: self.gameImage.layer)
        maskLayer.colors = [UIColor.black.cgColor, UIColor.clear.cgColor]
        maskLayer.startPoint = CGPoint(x: 0, y: 0.5)
        maskLayer.endPoint = CGPoint(x: 0, y: 1)
        maskLayer.frame = testBounds
        self.gameImage.layer.mask = maskLayer
        
        self.trailerPayload = [String]()
        self.trailerPayload.append(contentsOf: upcomingGame!.trailerUrls.keys)
        
        self.consoleCollection.dataSource = self
        self.consoleCollection.delegate = self
        
        self.trailerCollection.dataSource = self
        self.trailerCollection.delegate = self
        self.trailerWV.navigationDelegate = self
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if(collectionView == self.consoleCollection){
            return upcomingGame?.consoles.count ?? 0
        } else {
            return self.trailerPayload.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if(collectionView == self.consoleCollection){
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "console", for: indexPath) as! ConsoleCell
            let current = upcomingGame!.consoles[indexPath.item]
            if(current == "ps"){
                cell.consoleImage.image = #imageLiteral(resourceName: "playstation-logotype (1).png")
            } else if(current == "pc"){
                cell.consoleImage.image = #imageLiteral(resourceName: "pc_logo.png")
            } else if(current == "nintendo"){
                cell.consoleImage.image = #imageLiteral(resourceName: "switch_logo.png")
            } else if(current == "mobile"){
                cell.consoleImage.image = #imageLiteral(resourceName: "phone-white.png")
            } else {
                cell.consoleImage.image = #imageLiteral(resourceName: "xbox-logo (1).png")
            }
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "trailer", for: indexPath) as! TrailerCellV2
            let current = self.trailerPayload[indexPath.item]
            cell.trailerType.text = current
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if(collectionView == self.consoleCollection){
            let current = upcomingGame!.consoles[indexPath.item]
            if(current == "ps"){
                return CGSize(width: 30, height: CGFloat(30))
            } else {
                return CGSize(width: 25, height: CGFloat(25))
            }
        } else {
            return CGSize(width: 160, height: CGFloat(70))
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if(collectionView == self.trailerCollection){
            let current = self.trailerPayload[indexPath.item]
            let currentUrl = self.upcomingGame!.trailerUrls[current]
            if(currentUrl != nil){
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    /*let configuration = WKWebViewConfiguration()
                    configuration.allowsInlineMediaPlayback = true
                    configuration.mediaTypesRequiringUserActionForPlayback = .audio
                    let webView = WKWebView(frame: self.wvShell.bounds, configuration: configuration)
                    self.wvShell.addSubview(webView)*/
                    self.trailerWV.load(NSURLRequest(url: NSURL(string: currentUrl!)! as URL) as URLRequest)
                }
            }
        }
    }
}
