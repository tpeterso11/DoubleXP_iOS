//
//  FAQuiz.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 12/15/19.
//  Copyright © 2019 Peterson, Toussaint. All rights reserved.
//

import UIKit
import Firebase
import moa
import SwiftHTTP
import SwiftNotificationCenter

class FAQuiz: ParentVC, EMPageViewControllerDelegate, FreeAgentQuizNav {
    
    var user: User!
    var team: TeamObject?
    var gcGame: GamerConnectGame?
    var gameName: String!
    var currentUrl = ""
    var questions = [FAQuestion]()
    var currentQuestion = 0
    
    @IBOutlet weak var quizController: UIView!
    @IBOutlet weak var nextButton: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let interviewManager = delegate.interviewManager
        let currentUser = delegate.currentUser
        
        interviewManager.initialize(gameName: gcGame!.gameName, uId: currentUser!.uId)
    }
    
    func addQuestion(question: FAQuestion, interviewManager: InterviewManager) {
    }
    
    func addQuestion(question: FAQuestion) {
    }
    
    func updateAnswer(answer: String, question: FAQuestion) {
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
    }
}
