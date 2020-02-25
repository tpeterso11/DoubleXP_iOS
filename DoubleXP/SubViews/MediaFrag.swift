//
//  MediaFrag.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 2/25/20.
//  Copyright © 2020 Peterson, Toussaint. All rights reserved.
//

import Foundation
import UIKit
import Firebase
import ImageLoader
import moa
import SwiftHTTP
import SwiftNotificationCenter
import TRMosaicLayout

class MediaFrag: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet weak var optionsCollection: UICollectionView!
    @IBOutlet weak var news: UICollectionView!
    var options = [String]()
    var selectedCategory = ""
    var articles = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        options.append("popular")
        options.append("twitch")
        options.append("news")
        options.append("reviews")
        
        self.selectedCategory = options[0]
        
        articles.append("reviews")
        articles.append("reviews")
        articles.append("reviews")
        articles.append("reviews")
        articles.append("reviews")
        
        optionsCollection.dataSource = self
        optionsCollection.delegate = self
        
        let mosaicLayout = TRMosaicLayout()
        self.news?.collectionViewLayout = TestCollection()
        //mosaicLayout.delegate = self
        
        news.dataSource = self
        news.delegate = self
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if(collectionView == optionsCollection){
            return options.count
        }
        else{
            return articles.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if(collectionView == optionsCollection){
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! MediaCategoryCell
            let current = self.options[indexPath.item]
            
            if(selectedCategory == current){
                cell.mediaCategory.font = UIFont.systemFont(ofSize: 26, weight: .semibold)
                cell.mediaCategory.textColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
            }
            else{
                cell.mediaCategory.font = UIFont.systemFont(ofSize: 24, weight: .regular)
                cell.mediaCategory.textColor = #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)
            }
            cell.mediaCategory.text = current
            
            return cell
        }
        else{
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "newsCell", for: indexPath) as! NewsArticleCell
            /*cell.contentView.layer.cornerRadius = 15.0
            cell.contentView.layer.borderWidth = 1.0
            cell.contentView.layer.borderColor = UIColor.clear.cgColor
            cell.contentView.layer.masksToBounds = true
            
            cell.layer.shadowColor = UIColor.black.cgColor
            cell.layer.shadowOffset = CGSize(width: 0, height: 2.0)
            cell.layer.shadowRadius = 2.0
            cell.layer.shadowOpacity = 0.5
            cell.layer.masksToBounds = false
            cell.layer.shadowPath = UIBezierPath(roundedRect: cell.bounds, cornerRadius: cell.contentView.layer.cornerRadius).cgPath*/
            
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if(collectionView == optionsCollection){
            let current = self.options[indexPath.item]
            
            self.selectedCategory = current
            let cell = collectionView.cellForItem(at: indexPath) as! MediaCategoryCell
            cell.mediaCategory.font = UIFont.systemFont(ofSize: 26, weight: .semibold)
            cell.mediaCategory.textColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
            
            for cell in self.optionsCollection.visibleCells{
                let currentCell = cell as! MediaCategoryCell
                if(currentCell.mediaCategory.text != current){
                    currentCell.mediaCategory.font = UIFont.systemFont(ofSize: 24, weight: .regular)
                    currentCell.mediaCategory.textColor = #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)
                }
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let kWhateverHeightYouWant = 150
        
        if(collectionView == optionsCollection){
            return CGSize(width: 180, height: CGFloat(150))
        }
        else{
            if(indexPath.item % 3 == 0){
                return CGSize(width: (collectionView.bounds.width / 2) - 20, height: CGFloat(50))
            }
            else{
                return CGSize(width: (collectionView.bounds.width), height: CGFloat(300))
            }
        }
    }
    
    /*func collectionView(_ collectionView: UICollectionView, mosaicCellSizeTypeAtIndexPath indexPath: IndexPath) -> TRMosaicCellType {
        return indexPath.item % 3 == 0 ? TRMosaicCellType.big : TRMosaicCellType.small
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: TRMosaicLayout, insetAtSection: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 3, left: 3, bottom: 3, right: 3)
    }
    
    func heightForSmallMosaicCell() -> CGFloat {
        return 250
    }*/
    
}
