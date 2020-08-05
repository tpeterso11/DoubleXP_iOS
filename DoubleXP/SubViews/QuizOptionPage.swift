//
//  QuizOptionPage.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 6/13/20.
//  Copyright © 2020 Peterson, Toussaint. All rights reserved.
//

import Foundation
import UIKit

class QuizOptionPage: UIViewController, UITableViewDelegate, UITableViewDataSource, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, FreeAgentQuizNav{
    
    @IBOutlet weak var choicesCollection: UICollectionView!
    var question: FAQuestion?
private var options = [OptionObj]()
private var optionDescriptions = [String]()
var interviewManager: InterviewManager!
    var images = [String]()
    var maxOptions = 0
    var answers = [String]()
    @IBOutlet weak var optionTable: UITableView!
    @IBOutlet weak var continueButton: UIButton!
    @IBOutlet weak var questionLabel: UILabel!
    @IBOutlet weak var loadingOverla: UIView!
    @IBOutlet weak var loadingSpinner: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        options = interviewManager.optionCache
        maxOptions = Int(question!.maxOptions) ?? 1
        questionLabel.text = "which 3 champions do you play with the most?"//question?.question
    
        optionTable.delegate = self
        optionTable.dataSource = self
        
        choicesCollection.delegate = self
        choicesCollection.dataSource = self
        
        continueButton.addTarget(self, action: #selector(continueClicked), for: .touchUpInside)
        checkButton()
    }
    
    @objc private func continueClicked(){
        updateAnswerArray(answerArray: self.answers, question: self.question!)
    }
    
    private func checkButton(){
        if(images.count > 0){
            self.continueButton.alpha = 1
            self.continueButton.isUserInteractionEnabled = true
        } else {
            self.continueButton.alpha = 0.2
            self.continueButton.isUserInteractionEnabled = false
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return Int(self.question!.maxOptions) ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "answerCell", for: indexPath) as! AnswerCell
        
        if(self.images.indices.contains(indexPath.item)){
            let cache = self.interviewManager.imageCache
            if(cache.object(forKey: images[indexPath.item] as NSString) != nil){
                cell.answerImage.image = cache.object(forKey: images[indexPath.item] as NSString)
            } else {
                cell.answerImage.moa.onSuccess = { image in
                    cell.answerImage.image = image
                    cache.setObject(image, forKey: self.images[indexPath.item] as NSString)
                    return image
                }
                cell.answerImage.moa.url = images[indexPath.item]
                cell.answerImage.image = nil
            }
        } else {
            cell.answerImage.image = nil
        }
        
        cell.contentView.layer.cornerRadius = 2.0
        cell.contentView.layer.borderWidth = 1.0
        cell.contentView.layer.borderColor = UIColor.clear.cgColor
        cell.contentView.layer.masksToBounds = true
        
        cell.layer.shadowColor = UIColor.black.cgColor
        cell.layer.shadowOffset = CGSize(width: 0, height: 2.0)
        cell.layer.shadowRadius = 2.0
        cell.layer.shadowOpacity = 0.5
        cell.layer.masksToBounds = false
        cell.layer.shadowPath = UIBezierPath(roundedRect: cell.bounds, cornerRadius: cell.contentView.layer.cornerRadius).cgPath
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath){
            let currentCell = cell as! AnswerCell
            if(currentCell.answerImage.image != nil){
                let currentImage = images[indexPath.item]
                images.remove(at: indexPath.item)
                
                if(answers.contains(options[currentCell.tag].optionLabel)){
                    self.answers.remove(at: self.answers.index(of: options[currentCell.tag].optionLabel)!)
                }
                
                self.optionTable?.visibleCells.forEach { cell in
                    if let currentTableCell = cell as? QuizOptionCell {
                        if(cell.tag != nil){
                            let currentOption = options[cell.tag]
                            if(currentOption.imageUrl == currentImage){
                                UIView.animate(withDuration: 0.3, animations: {
                                    currentTableCell.selectedText.text = ""
                                    currentTableCell.selectedCell.alpha = 0
                                }, completion: nil)
                            }
                        }
                    }
                }
                self.choicesCollection.reloadData()
                self.optionTable.reloadData()
                self.checkButton()
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return options.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedItem = options[indexPath.item]
        let cell = tableView.cellForRow(at: indexPath) as! QuizOptionCell
        if(images.count <= (maxOptions - 1)){
            if(images.contains(selectedItem.imageUrl)){
                if(answers.contains(selectedItem.optionLabel)){
                    self.answers.remove(at: self.answers.index(of: selectedItem.optionLabel)!)
                }
                if(images.contains(selectedItem.imageUrl)){
                    images.remove(at: images.index(of: selectedItem.imageUrl)!)
                }
    
                UIView.animate(withDuration: 0.3, animations: {
                    cell.selectedText.text = ""
                    cell.selectedCell.alpha = 0
                }, completion: nil)
            } else {
                let answerWurl = selectedItem.optionLabel + "/DXP/" + selectedItem.imageUrl
                self.answers.append(answerWurl)
                self.images.append(selectedItem.imageUrl)
                UIView.animate(withDuration: 0.3, animations: {
                    cell.selectedText.text = selectedItem.title
                    cell.selectedCell.alpha = 1
                }, completion: nil)
            }
            
            self.choicesCollection.reloadData()
            
            self.checkButton()
        } else {
            if(answers.contains(selectedItem.optionLabel)){
                self.answers.remove(at: self.answers.index(of: selectedItem.optionLabel)!)
            }
            
            if(images.contains(selectedItem.imageUrl)){
                images.remove(at: images.index(of: selectedItem.imageUrl)!)
                UIView.animate(withDuration: 0.3, animations: {
                    cell.selectedText.text = ""
                    cell.selectedCell.alpha = 0
                }, completion: nil)
                
                self.choicesCollection.reloadData()
                self.checkButton()
            }
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "option", for: indexPath) as! QuizOptionCell
        let current = options[indexPath.item]
        
        cell.optionLabel.text = current.optionLabel
        
        let cache = self.interviewManager.imageCache
        if(cache.object(forKey: current.imageUrl as NSString) != nil){
            cell.optionBack.image = cache.object(forKey: current.imageUrl as NSString)
        } else {
            cell.optionBack.image = Utility.Image.placeholder
            cell.optionBack.moa.onSuccess = { image in
                cell.optionBack.image = image
                self.interviewManager.imageCache.setObject(image, forKey: current.imageUrl as NSString)
                return image
            }
            cell.optionBack.moa.url = current.imageUrl
        }
        
        if(images.contains(current.imageUrl)){
            cell.selectedCell.alpha = 1
        } else {
            cell.selectedCell.alpha = 0
        }
        
        cell.optionBack.contentMode = .scaleAspectFill
        cell.optionBack.clipsToBounds = true
        
        cell.selectionStyle = .none
        
        cell.tag = indexPath.item
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
    
        return CGSize(width: 80, height: CGFloat(80))
    }
    
    func centerItemsInCollectionView(cellWidth: Double, numberOfItems: Double, spaceBetweenCell: Double, collectionView: UICollectionView) -> UIEdgeInsets {
        let totalWidth = cellWidth * numberOfItems
        let totalSpacingWidth = spaceBetweenCell * (numberOfItems - 1)
        let leftInset = (collectionView.frame.width - CGFloat(totalWidth + totalSpacingWidth)) / 2
        let rightInset = leftInset
        return UIEdgeInsets(top: 0, left: leftInset, bottom: 0, right: rightInset)
    }
    
    func addQuestion(question: FAQuestion, interviewManager: InterviewManager) {
    }
    
    func addQuestion(question: FAQuestion) {
    }
    
    func updateAnswer(answer: String, question: FAQuestion) {
    }
    
    func updateAnswerArray(answerArray: [String], question: FAQuestion) {
        UIView.animate(withDuration: 0.5, delay: 0.2, options: [], animations: {
            self.loadingOverla.alpha = 1
            self.loadingSpinner.startAnimating()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.interviewManager?.updateAnswer(answer: nil, answerArray: answerArray, question: question)
            }
        }, completion: nil)
    }
    
    func onInitialQuizLoaded() {
    }
    
    func showConsoles() {
    }
    
    func showComplete() {
    }
    
    func showSubmitted() {
    }
    
    func showEmpty() {
    }
}
