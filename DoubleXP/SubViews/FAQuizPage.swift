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
    private var options = [Any]()
    private var optionDescriptions = [String]()
    private var interviewManager: InterviewManager?
    
    @IBOutlet weak var counterText: UILabel!
    @IBOutlet weak var questionDescription: UILabel!
    @IBOutlet weak var questionLabel: UILabel!
    @IBOutlet weak var questionOptions: UICollectionView!
    @IBOutlet weak var loadingOverlay: UIView!
    @IBOutlet weak var optionCounter: UIView!
    @IBOutlet weak var continueButton: UIView!
    @IBOutlet weak var multiBlur: UIVisualEffectView!
    @IBOutlet weak var loadingSpinner: UIActivityIndicatorView!
    
    private let reuseIdentifier = "cell"
    private var answerNumber = 0
    private var answers = [String]()
    
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
        
        options.append(0)
        
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
        
        if(Int(question!.maxOptions) ?? 0 > 1){
            self.continueButton.layer.cornerRadius = 10.0
            self.continueButton.layer.borderWidth = 1.0
            self.continueButton.layer.borderColor = UIColor.white.cgColor
            self.continueButton.layer.masksToBounds = true

            self.continueButton.layer.shadowColor = UIColor.black.cgColor
            self.continueButton.layer.shadowOffset = CGSize(width: 0, height: 2.0)
            self.continueButton.layer.shadowRadius = 2.0
            self.continueButton.layer.shadowOpacity = 0.5
            self.continueButton.layer.masksToBounds = false
            self.continueButton.layer.shadowPath = UIBezierPath(roundedRect: self.continueButton.bounds, cornerRadius: self.continueButton.layer.cornerRadius).cgPath
            
            self.optionCounter.layer.cornerRadius = 10.0
            self.optionCounter.layer.borderWidth = 1.0
            self.optionCounter.layer.borderColor = UIColor.white.cgColor
            self.optionCounter.layer.masksToBounds = true

            self.optionCounter.layer.shadowColor = UIColor.black.cgColor
            self.optionCounter.layer.shadowOffset = CGSize(width: 0, height: 2.0)
            self.optionCounter.layer.shadowRadius = 2.0
            self.optionCounter.layer.shadowOpacity = 0.5
            self.optionCounter.layer.masksToBounds = false
            self.optionCounter.layer.shadowPath = UIBezierPath(roundedRect: self.optionCounter.bounds, cornerRadius: self.optionCounter.layer.cornerRadius).cgPath
            
            handleCounter(answerNumber: self.answerNumber)
        }
        
        animateEntry()
    }
    
    private func animateEntry(){
        let top = CGAffineTransform(translationX: 0, y: -40)
        UIView.animate(withDuration: 0.8, delay: 0.8, options: [], animations: {
            self.questionOptions.alpha = 1
            self.questionDescription.alpha = 1
            self.questionLabel.alpha = 1
            
            if(Int(self.question!.maxOptions) ?? 0 > 1){
                self.optionCounter.transform = top
                self.optionCounter.alpha = 1
                self.multiBlur.alpha = 1
            }
        }, completion: nil)
    }
    
    private func handleCounter(answerNumber: Int){
        if(answerNumber > Int(question!.maxOptions) ?? 1){
            return
        }
        self.counterText.text = String(answerNumber) + "/" + question!.maxOptions
        
        if(Int(question!.maxOptions) ?? 0 > 1){
            if(self.continueButton.alpha == 0 && answers.count > 0){
                let continueTap = UITapGestureRecognizer(target: self, action: #selector(continueClicked))
                self.continueButton.isUserInteractionEnabled = true
                self.continueButton.addGestureRecognizer(continueTap)
                
                let top = CGAffineTransform(translationX: 0, y: -40)
                UIView.animate(withDuration: 0.5, delay: 0.2, options: [], animations: {
                    self.continueButton.transform = top
                    self.continueButton.alpha = 1
                }, completion: nil)
            } else if(self.continueButton.alpha == 1 && answers.count == 0){
                let top = CGAffineTransform(translationX: 0, y: 0)
                UIView.animate(withDuration: 0.5, delay: 0.2, options: [], animations: {
                    self.continueButton.transform = top
                    self.continueButton.alpha = 1
                }, completion: nil)
            }
        } else {
            UIView.animate(withDuration: 0.3, animations: {
                self.loadingOverlay.alpha = 1
                self.loadingSpinner.startAnimating()
                
                let top = CGAffineTransform(translationX: 0, y: 0)
                self.optionCounter.transform = top
                self.continueButton.transform = top
                self.optionCounter.alpha = 0
                self.continueButton.alpha = 0
            }, completion: { (finished: Bool) in
                self.updateAnswer(answer: self.answers[0], question: self.question!)
            })
        }
    }
    
    func addQuestion(question: FAQuestion, interviewManager: InterviewManager) {
    }
    
    func addQuestion(question: FAQuestion) {
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.options.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let current = self.options[indexPath.item]
        
        if(current is Int){
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "empty", for: indexPath) as! EmptyCollectionViewCell
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! OptionCell
            cell.answer.text = current as! String
            cell.coverLabel.text = current as! String
            
            let index = indexPath.item
            if index >= 0 && index < self.optionDescriptions.count {
                cell.answerDesc.text = self.optionDescriptions[index]
                cell.coverDesc.text = self.optionDescriptions[index]
            } else {
                cell.answerDesc.alpha = 0
                cell.coverDesc.alpha = 0
            }
            
            cell.contentView.layer.cornerRadius = 10.0
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
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let current = self.options[indexPath.item]
        
        if(current is String){
            let cell = self.questionOptions.cellForItem(at: indexPath) as! OptionCell
            if(self.answers.contains(cell.answer.text!)){
                UIView.animate(withDuration: 0.3, animations: {
                    cell.cover.alpha = 0
                }, completion: nil)
                
                self.answers.remove(at: answers.index(of: cell.answer.text!)!)
                self.answerNumber -= 1
                self.handleCounter(answerNumber: self.answerNumber)
            } else {
                if(answerNumber > Int(question!.maxOptions) ?? 0){
                    return
                }
                UIView.animate(withDuration: 0.3, animations: {
                    cell.cover.alpha = 1
                }, completion: { (finished: Bool) in
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        self.answers.append(cell.answer.text!)
                        self.answerNumber += 1
                        self.handleCounter(answerNumber: self.answerNumber)
                    }
                })
            }
        }
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
        let current = self.options[indexPath.item]
        
        if(current is String){
            return CGSize(width: collectionView.bounds.width - 20, height: CGFloat(110))
        } else {
            return CGSize(width: collectionView.bounds.width, height: CGFloat(50))
        }
    }
    
    func updateAnswer(answer: String, question: FAQuestion) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.interviewManager?.updateAnswer(answer: answer, answerArray: nil, question: question)
        }
    }
    
    @objc private func continueClicked(){
        if(self.answers.isEmpty){
            return
        }
        
        if(self.answers.count == 1){
            let number = Int(question!.maxOptions)
            if(number ?? 0 > 1){
                self.updateAnswerArray(answerArray: self.answers, question: question!)
            } else {
                self.updateAnswer(answer: self.answers[0], question: question!)
            }
        } else {
            self.updateAnswerArray(answerArray: self.answers, question: question!)
        }
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
    
    func updateAnswerArray(answerArray: [String], question: FAQuestion) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.interviewManager?.updateAnswer(answer: nil, answerArray: answerArray, question: question)
        }
    }
}

