//
//  FAQuizConfirmation.swift
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

class FAQuizConfirmation: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout{
    var questions = [FAQuestion]()
    var interviewManager: InterviewManager?
    
    @IBOutlet weak var questionList: UICollectionView!
    @IBOutlet weak var nextButton: UIImageView!
    @IBOutlet weak var backButton: UIImageView!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let delegate = UIApplication.shared.delegate as! AppDelegate
        interviewManager = delegate.interviewManager
        
        let one = FAQuestion(question: "Console")
        one.answer =  interviewManager!.faObject!.consoles[0]
        questions.append(one)
        questions.append(contentsOf: interviewManager!.questions)
        
        questionList.delegate = self
        questionList.dataSource = self
        
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(nextButtonClicked))
        nextButton.isUserInteractionEnabled = true
        nextButton.addGestureRecognizer(singleTap)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return questions.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! ConfirmationQuestionCell
        
        cell.question.text = questions[indexPath.item].question
        cell.answer.text = questions[indexPath.item].answer
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
            return CGSize(width: collectionView.bounds.size.width, height: CGFloat(80))
    }
    
    @objc func nextButtonClicked(_ sender: AnyObject?) {
        interviewManager?.submitProfile()
    }
}
