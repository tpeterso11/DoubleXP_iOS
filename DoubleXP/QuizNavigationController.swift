//
//  QuizNavigationController.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 12/19/19.
//  Copyright © 2019 Peterson, Toussaint. All rights reserved.
//

import UIKit
import SwiftNotificationCenter

class QuizNavigationController: EMPageViewController, EMPageViewControllerDataSource, FreeAgentQuizNav {
    
    func em_pageViewController(_ pageViewController: EMPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
        return nil
    }
    
    func em_pageViewController(_ pageViewController: EMPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        return nil
    }
    
    func goBack(){
        self.scrollReverse(animated: true, completion: nil)
    }
    
    fileprivate var items: [UIViewController] = []
    var interviewManager: InterviewManager?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        dataSource = self
        
        let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "faCover") as! FAQuizCover
        
        let delegate = UIApplication.shared.delegate as! AppDelegate
        currentViewController.gcGame = delegate.selectedGCGame
        
        selectViewController(currentViewController, direction: .forward, animated: false, completion: nil)
        
        Broadcaster.register(FreeAgentQuizNav.self, observer: self)
    }
    
    func addQuestion(question: FAQuestion, interviewManager: InterviewManager) {
        if(!question.optionsUrl.isEmpty){
            let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "faOptionQuestion") as! QuizOptionPage
            
            currentViewController.question = question
            currentViewController.interviewManager = interviewManager
            
            selectViewController(currentViewController, direction: .forward, animated: true, completion: nil)
        } else {
            let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "faQuestion") as! FAQuizPage
            
            currentViewController.question = question
            
            selectViewController(currentViewController, direction: .forward, animated: true, completion: nil)
        }
    }
    
    func showConsoles() {
        let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "faConsoles") as! FAQuizConsoles
        
        selectViewController(currentViewController, direction: .forward, animated: true, completion: nil)
    }
    
    func showComplete() {
        let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "faConfirmation") as! FAQuizConfirmation
        
        selectViewController(currentViewController, direction: .forward, animated: true, completion: nil)
    }
    
    func showSubmitted() {
        let currentViewController = self.storyboard!.instantiateViewController(withIdentifier: "faSubmitted") as! FAQuizComplete
        
        selectViewController(currentViewController, direction: .forward, animated: true, completion: nil)
    }
    
    func updateAnswer(answer: String, question: FAQuestion){
    }
    
    fileprivate func populateItems() {
         let c = FAQuizCover()
    
        items.append(c)
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = items.index(of: viewController) else {
            return nil
        }
        
        let previousIndex = viewControllerIndex - 1
        
        guard previousIndex >= 0 else {
            return items.last
        }
        
        guard items.count > previousIndex else {
            return nil
        }
        
        return items[previousIndex]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = items.index(of: viewController) else {
            return nil
        }
        
        let nextIndex = viewControllerIndex + 1
        guard items.count != nextIndex else {
            return items.first
        }
        
        guard items.count > nextIndex else {
            return nil
        }
        
        return items[nextIndex]
    }
    
    func onInitialQuizLoaded() {
    }
    
    func showEmpty() {
    }
    
    func updateAnswerArray(answerArray: [String], question: FAQuestion) {
    }
}

