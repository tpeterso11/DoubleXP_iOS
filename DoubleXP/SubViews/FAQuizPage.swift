//
//  FAQuizPage.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 12/19/19.
//  Copyright © 2019 Peterson, Toussaint. All rights reserved.
//

import UIKit
import Firebase
import moa
import SwiftHTTP
import SwiftNotificationCenter

class FAQuizPage: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, FreeAgentQuizNav{
    var question: FAQuestion?
    private var options = [String]()
    private var optionDescriptions = [String]()
    private var interviewManager: InterviewManager?
    
    @IBOutlet weak var questionDescription: UILabel!
    @IBOutlet weak var questionLabel: UILabel!
    @IBOutlet weak var questionOptions: UICollectionView!
    @IBOutlet weak var loadingOverlay: UIView!
    @IBOutlet weak var loadingSpinner: UIActivityIndicatorView!
    
    private let reuseIdentifier = "cell"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let delegate = UIApplication.shared.delegate as! AppDelegate
        interviewManager = delegate.interviewManager
        
        questionDescription.text = question!.questionDescription
        questionLabel.text = question!.question
        
        if(!question!.option1.isEmpty){
            options.append(question!.option1)
        }
        if(!question!.option2.isEmpty){
            options.append(question!.option2)
        }
        if(!question!.option3.isEmpty){
            options.append(question!.option3)
        }
        if(!question!.option4.isEmpty){
            options.append(question!.option4)
        }
        if(!question!.option5.isEmpty){
            options.append(question!.option5)
        }
        if(!question!.option6.isEmpty){
            options.append(question!.option6)
        }
        if(!question!.option7.isEmpty){
            options.append(question!.option7)
        }
        if(!question!.option8.isEmpty){
            options.append(question!.option8)
        }
        if(!question!.option9.isEmpty){
            options.append(question!.option9)
        }
        if(!question!.option10.isEmpty){
            options.append(question!.option10)
        }
        
        if(!question!.option1Description.isEmpty){
            optionDescriptions.append(question!.option1Description)
        }
        if(!question!.option2Description.isEmpty){
            optionDescriptions.append(question!.option2Description)
        }
        if(!question!.option3Description.isEmpty){
            optionDescriptions.append(question!.option3Description)
        }
        if(!question!.option4Description.isEmpty){
            optionDescriptions.append(question!.option4Description)
        }
        if(!question!.option5Description.isEmpty){
            optionDescriptions.append(question!.option5Description)
        }
        if(!question!.option6Description.isEmpty){
            optionDescriptions.append(question!.option6Description)
        }
        if(!question!.option7Description.isEmpty){
            optionDescriptions.append(question!.option7Description)
        }
        if(!question!.option8Description.isEmpty){
            optionDescriptions.append(question!.option8Description)
        }
        if(!question!.option9Description.isEmpty){
            optionDescriptions.append(question!.option9Description)
        }
        if(!question!.option10Description.isEmpty){
            optionDescriptions.append(question!.option10Description)
        }
        
        questionOptions.delegate = self
        questionOptions.dataSource = self
    }
    
    func addQuestion(question: FAQuestion) {
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.options.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! OptionCell
        let current = self.options[indexPath.item]
        cell.answer.text = current
        if(!self.optionDescriptions.isEmpty){
            cell.answerDesc.text = self.optionDescriptions[indexPath.item]
        }
        
        cell.contentView.layer.cornerRadius = 20.0
        cell.contentView.layer.borderWidth = 1.0
        cell.contentView.layer.borderColor = UIColor.white.cgColor
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
        let cell = self.questionOptions.cellForItem(at: indexPath) as! OptionCell
        updateAnswer(answer: cell.answer.text!, question: question!)
    }
    
    func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        UIView.animate(withDuration: 0.2) {
            if let cell = collectionView.cellForItem(at: indexPath) as? OptionCell {
                cell.answer.transform = .init(scaleX: 0.95, y: 0.95)
                cell.answerDesc.transform = .init(scaleX: 0.95, y: 0.95)
                cell.divider.transform = .init(scaleX: 0.95, y: 0.95)
                cell.layer.shadowOpacity = 0
            }
        }
    }

    func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        UIView.animate(withDuration: 0.2) {
            if let cell = collectionView.cellForItem(at: indexPath) as? OptionCell {
                cell.answer.transform = .identity
                cell.answerDesc.transform = .identity
                cell.divider.transform = .identity
                cell.layer.shadowOpacity = 0.5
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let flowayout = collectionViewLayout as? UICollectionViewFlowLayout
        let space: CGFloat = (flowayout?.minimumInteritemSpacing ?? 0.0) + (flowayout?.sectionInset.left ?? 0.0) + (flowayout?.sectionInset.right ?? 0.0)
        let size:CGFloat = (collectionView.frame.size.width - space) / 2.0
        return CGSize(width: size, height: size)
    }
    
    func updateAnswer(answer: String, question: FAQuestion) {
        UIView.animate(withDuration: 0.5, delay: 0.2, options: [], animations: {
            self.loadingOverlay.alpha = 1
            self.loadingSpinner.startAnimating()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.interviewManager?.updateAnswer(answer: answer, question: question)
            }
        }, completion: nil)
    }
    
    func onInitialQuizLoaded() {
    }
    
    func showConfirmation() {
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

