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

class MediaFrag: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet weak var optionsCollection: UICollectionView!
    @IBOutlet weak var news: UICollectionView!
    var options = [String]()
    var selectedCategory = ""
    var newsSet = false
    var articles = [Any]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        options.append("popular")
        options.append("twitch")
        options.append("news")
        options.append("reviews")
        
        self.selectedCategory = options[0]
        
        optionsCollection.dataSource = self
        optionsCollection.delegate = self
        
        self.news?.collectionViewLayout = TestCollection()
        
        let delegate = UIApplication.shared.delegate as! AppDelegate
        articles.append(contentsOf: delegate.mediaCache.newsCache)
        
        news.delegate = self
        news.dataSource = self
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
            let current = self.articles[indexPath.item]
            if(current is NewsObject){
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "newsCell", for: indexPath) as! NewsArticleCell
                cell.title.text = (current as! NewsObject).title
                cell.subTitle.text = (current as! NewsObject).subTitle
                
                cell.articleBack.moa.onSuccess = { image in
                    UIView.animate(withDuration: 0.5, delay: 0.2, options: [], animations: {
                        cell.articleBack.alpha = 0.1
                        cell.articleBack.contentMode = .scaleAspectFill
                        cell.articleBack.clipsToBounds = true
                    }, completion: nil)
                    
                  return image
                }
                cell.articleBack.moa.url = (current as! NewsObject).imageUrl
                
                return cell
            }
            else{
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "contributorCell", for: indexPath) as! ContributorCell
                return cell
            }
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
            
            let delegate = UIApplication.shared.delegate as! AppDelegate
            
            switch(self.selectedCategory){
                case "popular":
                    self.articles = [Any]()
                    articles.append(contentsOf: delegate.mediaCache.newsCache)
                    
                    self.news.performBatchUpdates({
                        let indexSet = IndexSet(integersIn: 0...0)
                        self.news.reloadSections(indexSet)
                    }, completion: nil)
                break;
                case "twitch":
                    self.articles = [Any]()
                    articles.append(contentsOf: delegate.mediaCache.newsCache)
                    
                    self.news.performBatchUpdates({
                        let indexSet = IndexSet(integersIn: 0...0)
                        self.news.reloadSections(indexSet)
                    }, completion: nil)
                break;
                case "news":
                    self.articles = [Any]()
                    articles.append(0)
                    articles.append(contentsOf: delegate.mediaCache.newsCache)
                    
                    self.news.performBatchUpdates({
                        let indexSet = IndexSet(integersIn: 0...0)
                        self.news.reloadSections(indexSet)
                    }, completion: nil)
                break;
                case "reviews":
                    self.articles = [Any]()
                    articles.append(0)
                    articles.append(contentsOf: delegate.mediaCache.reviewsCache)
                    
                    self.news.performBatchUpdates({
                        let indexSet = IndexSet(integersIn: 0...0)
                        self.news.reloadSections(indexSet)
                    }, completion: nil)
                break;
                default:
                    self.articles = [Any]()
                    articles.append(contentsOf: delegate.mediaCache.newsCache)
                    
                    self.news.performBatchUpdates({
                        let indexSet = IndexSet(integersIn: 0...0)
                        self.news.reloadSections(indexSet)
                    }, completion: nil)
                break;
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
            let current = self.articles[indexPath.item]
            if(current is Int){
                return CGSize(width: (collectionView.bounds.width - 20), height: CGFloat(200))
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
    }
    
}
