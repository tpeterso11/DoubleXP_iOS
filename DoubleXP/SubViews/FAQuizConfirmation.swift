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
import PopupDialog
import FBSDKCoreKit

class FAQuizConfirmation: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout{
    var questions = [FAQuestion]()
    var interviewManager: InterviewManager?
    
    @IBOutlet weak var submitButton: UIButton!
    @IBOutlet weak var questionList: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let delegate = UIApplication.shared.delegate as! AppDelegate
        interviewManager = delegate.interviewManager
        
        //let one = FAQuestion(question: "Console")
        //one.answer =  interviewManager!.faObject!.consoles[0]
        //questions.append(one)
        questions.append(contentsOf: interviewManager!.questions)
        questions.remove(at: 0)
        
        questionList.delegate = self
        questionList.dataSource = self
        
        submitButton.addTarget(self, action: #selector(nextButtonClicked), for: .touchUpInside)
        AppEvents.logEvent(AppEvents.Name(rawValue: "FA Quiz Confirmation"))
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
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        showImageDialog(pos: indexPath.item)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
            return CGSize(width: collectionView.bounds.size.width, height: CGFloat(80))
    }
    
    @objc func nextButtonClicked(_ sender: AnyObject?) {
        interviewManager?.submitProfile()
        AppEvents.logEvent(AppEvents.Name(rawValue: "FA Quiz Confirmation - Submit"))
    }
    
    func showImageDialog(animated: Bool = true, pos: Int) {
        let current = self.questions[pos]
        var choices = [String]()
        var buttons = [PopupDialogButton]()
        //let currentAnswer = interviewManager?.faObject?.questions[pos]
        
        // Prepare the popup assets
        let title = current.question
        let message = current.questionDescription
        
        if(!current.option1.isEmpty){
            choices.append(current.option1)
        }
        
        if(!current.option2.isEmpty){
            choices.append(current.option2)
        }
        
        if(!current.option3.isEmpty){
            choices.append(current.option3)
        }
        
        if(!current.option4.isEmpty){
            choices.append(current.option4)
        }
        
        if(!current.option5.isEmpty){
            choices.append(current.option5)
        }
        
        // Create first button
        let buttonOne = CancelButton(title: "Keep My Answer") { [weak self] in
            //do nothing
        }
        buttons.append(buttonOne)
        
        for choice in choices{
            if(choice == current.answer){
                choices.remove(at: choices.index(of: choice)!)
            }
            else{
                let button = DefaultButton(title: choice) { [weak self] in
                    current.answer = choice
                    self?.questionList.reloadData()
                }
                buttons.append(button)
            }
        }
        
        // Create the dialog
        let popup = PopupDialog(title: title, message: message)
        
        // Create fourth (shake) button
        //let buttonTwo = DefaultButton(title: "SHAKE", dismissOnTap: false) { [weak popup] in
        //    popup?.shake()
        //}

        // Add buttons to dialog
        popup.addButtons(buttons)

        // Present dialog
        self.present(popup, animated: animated, completion: nil)
        
        AppEvents.logEvent(AppEvents.Name(rawValue: "FA Quiz Confirmation - Change Answer Popup"))
    }
    
    func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size

        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height

        // Figure out what our orientation is, and use that to form the rectangle
        var newSize: CGSize
        if(widthRatio > heightRatio) {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio,  height: size.height * widthRatio)
        }

        // This is the rect that we've calculated out and this is what is actually used below
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)

        // Actually do the resizing to the rect using the ImageContext stuff
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()

        return newImage
    }
}

