//
//  FAQuizCover.swift
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
import FBSDKCoreKit
import Lottie

class FAQuizCover: ParentVC, FreeAgentQuizNav{
    
    var question: FAQuestion?
    var gcGame: GamerConnectGame?
    var questions = [FAQuestion]()
    var interviewManager: InterviewManager?
    var currentUrl = ""
    
    @IBOutlet weak var lottie: LottieAnimationView!
    @IBOutlet weak var bottomView: UIView!
    var maxProfiles = 0
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        lottie.loopMode = .loop
        lottie.play()
        
        let delegate = UIApplication.shared.delegate as! AppDelegate
        interviewManager = delegate.interviewManager
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
            self.getQuestions()
        }
        
        AppEvents.shared.logEvent(AppEvents.Name(rawValue: "FA Quiz Front"))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.bottomView.layer.cornerRadius = 10.0
        self.bottomView.layer.borderWidth = 1.0
        self.bottomView.layer.borderColor = UIColor.clear.cgColor
        self.bottomView.layer.masksToBounds = true
        
        self.bottomView.layer.shadowColor = UIColor.black.cgColor
        self.bottomView.layer.shadowOffset = CGSize(width: 0, height: 2.0)
        self.bottomView.layer.shadowRadius = 2.0
        self.bottomView.layer.shadowOpacity = 0.5
        self.bottomView.layer.masksToBounds = false
        self.bottomView.layer.shadowPath = UIBezierPath(roundedRect: self.bottomView.layer.bounds, cornerRadius: self.bottomView.layer.cornerRadius).cgPath
    }
    
    @objc func startButtonClicked(_ sender: AnyObject?) {
        self.interviewManager?.showFirstQuestion()
        AppEvents.shared.logEvent(AppEvents.Name(rawValue: "FA Quiz Front - Start Button"))
    }
    
    func showEmpty() {
        //dashButton.addTarget(self, action: #selector(dashButtonClicked), for: .touchUpInside)
    }
    
    @objc func dashButtonClicked(_ sender: AnyObject?) {
        AppEvents.shared.logEvent(AppEvents.Name(rawValue: "FA Quiz Front - Dash Button - Navigate to FA Dash"))
        LandingActivity().navigateToTeamFreeAgentDash()
    }
    
    @objc func doneButtonClicked(_ sender: AnyObject?) {
        AppEvents.shared.logEvent(AppEvents.Name(rawValue: "FA Quiz Front - Done Button - Navigate to FA Dash"))
        LandingActivity().navigateToTeamFreeAgentDash()
    }
    
    private func setImage(){
        let delegate = UIApplication.shared.delegate as! AppDelegate
        interviewManager = delegate.interviewManager
    }
    
    func getQuestions(){
        let delegate = UIApplication.shared.delegate as! AppDelegate
        interviewManager = delegate.interviewManager
        
        self.interviewManager?.getQuiz(url: (self.interviewManager?.currentGCGame!.quizUrl)!, secondary: false, gameName: (self.interviewManager?.currentGCGame!.gameName)!, callbacks: self)
    }
    
    func addQuestion(question: FAQuestion, interviewManager: InterviewManager) {
    }
    
    func addQuestion(question: FAQuestion) {
    }
    
    func updateAnswer(answer: String, question: FAQuestion) {
    }
    
    func showConfirmation() {
    }
    
    func showConsoles() {
    }
    
    func showComplete() {
    }
    
    func showSubmitted() {
    }
    
    func updateAnswerArray(answerArray: [String], question: FAQuestion) {
    }
    
    func onInitialQuizLoaded() {
        UIView.animate(withDuration: 0.5, animations: {
            self.bottomView.alpha = 0
        }, completion: { (finished: Bool) in
            self.interviewManager?.showFirstQuestion()
        })
    }
}
