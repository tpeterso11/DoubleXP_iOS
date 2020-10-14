//
//  OptionAnswerCell.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 6/18/20.
//  Copyright © 2020 Peterson, Toussaint. All rights reserved.
//

import Foundation
import UIKit

class OptionAnswerCell: UITableViewCell, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet weak var question: UILabel!
    @IBOutlet weak var optionCollection: UICollectionView!
    var options = [String]()
    var imageCache = NSCache<NSString, UIImage>()
    
    func setOptions(options: [String], cache: NSCache<NSString, UIImage>){
        self.options = options
        self.imageCache = cache
        
        self.optionCollection.delegate = self
        self.optionCollection.dataSource = self
    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return options.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "option", for: indexPath) as! OptionCollectionCell
                
        let current = options[indexPath.item]
        let startIndex = current.index(of: "http")
        let answerIndex = current.index(of: "/")
        if(startIndex != nil){
            let url = current.suffix(from: startIndex!)
            let answer = current.prefix(upTo: answerIndex!)
            
            if(self.options.count < 3){
                cell.optionText.text = String(answer) as String
            }
            
            if(self.imageCache.object(forKey: url as NSString) != nil){
                cell.optionImage.image = imageCache.object(forKey: url as NSString)
            } else {
                cell.optionImage.image = Utility.Image.placeholder
                cell.optionImage.moa.onSuccess = { image in
                    cell.optionImage.image = image
                    self.imageCache.setObject(image, forKey: url as NSString)
                    return image
                }
                cell.optionImage.moa.url = String(url)
            }
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        return CGSize(width: collectionView.bounds.width / CGFloat(options.count), height: CGFloat(120))
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets.zero
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
}

extension StringProtocol {
    func index<S: StringProtocol>(of string: S, options: String.CompareOptions = []) -> Index? {
        range(of: string, options: options)?.lowerBound
    }
    func endIndex<S: StringProtocol>(of string: S, options: String.CompareOptions = []) -> Index? {
        range(of: string, options: options)?.upperBound
    }
    func indices<S: StringProtocol>(of string: S, options: String.CompareOptions = []) -> [Index] {
        var indices: [Index] = []
        var startIndex = self.startIndex
        while startIndex < endIndex,
            let range = self[startIndex...]
                .range(of: string, options: options) {
                indices.append(range.lowerBound)
                startIndex = range.lowerBound < range.upperBound ? range.upperBound :
                    index(range.lowerBound, offsetBy: 1, limitedBy: endIndex) ?? endIndex
        }
        return indices
    }
    func ranges<S: StringProtocol>(of string: S, options: String.CompareOptions = []) -> [Range<Index>] {
        var result: [Range<Index>] = []
        var startIndex = self.startIndex
        while startIndex < endIndex,
            let range = self[startIndex...]
                .range(of: string, options: options) {
                result.append(range)
                startIndex = range.lowerBound < range.upperBound ? range.upperBound :
                    index(range.lowerBound, offsetBy: 1, limitedBy: endIndex) ?? endIndex
        }
        return result
    }
}
