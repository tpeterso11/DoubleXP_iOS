//
//  FAQuizPage.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 12/19/19.
//  Copyright © 2019 Peterson, Toussaint. All rights reserved.
//

import UIKit
import Firebase
import ImageLoader
import moa
import SwiftHTTP
import SwiftNotificationCenter

class FAQuizPage: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, FreeAgentQuizNav{
    var question: FAQuestion?
    private var options = [String]()
    private var interviewManager: InterviewManager?
    
    @IBOutlet weak var questionNumber: UILabel!
    @IBOutlet weak var questionDescription: UILabel!
    @IBOutlet weak var questionLabel: UILabel!
    @IBOutlet weak var questionOptions: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let delegate = UIApplication.shared.delegate as! AppDelegate
        interviewManager = delegate.interviewManager
        
        questionNumber.text = "Question # " + question!.questionNumber
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
        
        cell.contentView.layer.cornerRadius = 2.0
        cell.contentView.layer.borderWidth = 1.0
        cell.contentView.layer.borderColor = UIColor.black.cgColor
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
        cell.contentView.layer.borderColor = UIColor.blue.cgColor
        cell.answer.textColor = UIColor.blue
        
        for unselectedAnswer in self.questionOptions.visibleCells{
            if(unselectedAnswer != cell){
                cell.contentView.layer.borderColor = UIColor.black.cgColor
                cell.answer.textColor = UIColor.black
            }
        }
        
        updateAnswer(answer: cell.answer.text!, question: question!)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
            return CGSize(width: collectionView.bounds.size.width, height: CGFloat(50))
    }
    
    func updateAnswer(answer: String, question: FAQuestion) {
        interviewManager?.updateAnswer(answer: answer, question: question)
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

