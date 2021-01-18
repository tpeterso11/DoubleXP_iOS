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

class FAQuizCover: ParentVC, FreeAgentQuizNav{
    
    var question: FAQuestion?
    var gcGame: GamerConnectGame?
    var questions = [FAQuestion]()
    var interviewManager: InterviewManager?
    var currentUrl = ""
    
    @IBOutlet weak var topView: UIView!
    @IBOutlet weak var bottomView: UIView!
    @IBOutlet weak var gameImage: UIImageView!
    @IBOutlet weak var gameName: UILabel!
    @IBOutlet weak var dashButton: UIButton!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var empty: UIView!
    @IBOutlet weak var emptyText: UILabel!
    @IBOutlet weak var emptyFAButton: UIButton!
    var maxProfiles = 0
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setImage()
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        getQuestions()
        
        startButton.alpha = 0.4
        
        let delegate = UIApplication.shared.delegate as! AppDelegate
        interviewManager = delegate.interviewManager
        gameName.text = interviewManager?.currentGCGame?.gameName
        
        startButton.addTarget(self, action: #selector(doneButtonClicked), for: .touchUpInside)
        
        startButton.layer.shadowColor = UIColor.black.cgColor
        startButton.layer.shadowOffset = CGSize(width: 0, height: 2.0)
        startButton.layer.shadowRadius = 2.0
        startButton.layer.shadowOpacity = 0.5
        startButton.layer.masksToBounds = false
        startButton.layer.shadowPath = UIBezierPath(roundedRect: startButton.bounds, cornerRadius: startButton.cornerRadius).cgPath
        
        navDictionary = ["state": "backOnly"]
        
        appDelegate.currentLanding?.updateNavigation(currentFrag: self)
        
        self.pageName = "FA Quiz Front"
        appDelegate.addToNavStack(vc: self)
        
        AppEvents.logEvent(AppEvents.Name(rawValue: "FA Quiz Front"))
    }
    
    @objc func startButtonClicked(_ sender: AnyObject?) {
        self.interviewManager?.showFirstQuestion()
        AppEvents.logEvent(AppEvents.Name(rawValue: "FA Quiz Front - Start Button"))
    }
    
    func showEmpty() {
        empty.isHidden = false
        
        
        //dashButton.addTarget(self, action: #selector(dashButtonClicked), for: .touchUpInside)
    }
    
    @objc func dashButtonClicked(_ sender: AnyObject?) {
        AppEvents.logEvent(AppEvents.Name(rawValue: "FA Quiz Front - Dash Button - Navigate to FA Dash"))
        LandingActivity().navigateToTeamFreeAgentDash()
    }
    
    @objc func doneButtonClicked(_ sender: AnyObject?) {
        AppEvents.logEvent(AppEvents.Name(rawValue: "FA Quiz Front - Done Button - Navigate to FA Dash"))
        LandingActivity().navigateToTeamFreeAgentDash()
    }
    
    private func setImage(){
        let delegate = UIApplication.shared.delegate as! AppDelegate
        interviewManager = delegate.interviewManager
        gameImage.image = Utility.Image.placeholder
        gameImage.moa.url = interviewManager?.currentGCGame?.imageUrl
        gameImage.contentMode = .scaleAspectFill
        gameImage.clipsToBounds = true
    }
    
    func getQuestions(){
        let delegate = UIApplication.shared.delegate as! AppDelegate
        interviewManager = delegate.interviewManager
        
        let ref = Database.database().reference().child("Games").child(interviewManager!.currentGCGame.gameName)
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            if(snapshot.exists()){
                let value = snapshot.value as? NSDictionary
                self.currentUrl = value?["url"] as? String ?? ""
            }
            
            if(self.currentUrl.isEmpty){
                //ordinary generic questions
                self.currentUrl = "https://firebasestorage.googleapis.com/v0/b/gameterminal-767f7.appspot.com/o/esports%2Fcompetition_questions%2Fgeneric_shooter_questions.json?alt=media&token=42895bf2-5881-4143-8eae-0099b7a8702d"
            }
            
            self.interviewManager?.getQuiz(url: self.currentUrl, secondary: false, gameName: (self.interviewManager?.currentGCGame!.gameName)!, callbacks: self)
        }) { (error) in
            AppEvents.logEvent(AppEvents.Name(rawValue: "FA Quiz Front - Error Loading Quiz"))
            print(error.localizedDescription)
        }
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
        let startTap = UITapGestureRecognizer(target: self, action: #selector(self.startButtonClicked))
        self.startButton.alpha = 1
        self.startButton.isUserInteractionEnabled = true
        self.startButton.addGestureRecognizer(startTap)
    }
}
