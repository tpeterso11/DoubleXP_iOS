//
//  FAQuestion.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 12/15/19.
//  Copyright © 2019 Peterson, Toussaint. All rights reserved.
//

import Foundation

class FAQuestion: NSObject, NSCoding {

    /*
     private boolean questionAnswered;
     private String answer;
     */
    var _questionNumber = ""
    var questionNumber:String {
        get {
            return (_questionNumber)
        }
        set (newVal) {
            _questionNumber = newVal
        }
    }
    
    var _question = ""
    var question:String {
        get {
            return (_question)
        }
        set (newVal) {
            _question = newVal
        }
    }
    
    var _option1 = ""
    var option1:String {
        get {
            return (_option1)
        }
        set (newVal) {
            _option1 = newVal
        }
    }
    
    var _teamName = ""
    var teamName: String {
        get {
            return (_teamName)
        }
        set (newVal) {
            _teamName = newVal
        }
    }

    var _option1Description = ""
    var option1Description: String {
        get {
            return (_option1Description)
        }
        set (newVal) {
            _option1Description = newVal
        }
    }
    
    var _question1SetURL = ""
    var question1SetURL: String {
        get {
            return (_question1SetURL)
        }
        set (newVal) {
            _question1SetURL = newVal
        }
    }
    
    var _option2 = ""
    var option2:String {
        get {
            return (_option2)
        }
        set (newVal) {
            _option2 = newVal
        }
    }

    var _option2Description = ""
    var option2Description: String {
        get {
            return (_option2Description)
        }
        set (newVal) {
            _option2Description = newVal
        }
    }

    var _question2SetURL = ""
    var question2SetURL: String {
        get {
            return (_question2SetURL)
        }
        set (newVal) {
            _question2SetURL = newVal
        }
    }
    
    var _option3 = ""
    var option3:String {
        get {
            return (_option3)
        }
        set (newVal) {
            _option3 = newVal
        }
    }

    var _option3Description = ""
    var option3Description: String {
        get {
            return (_option3Description)
        }
        set (newVal) {
            _option3Description = newVal
        }
    }
    
    var _question3SetURL = ""
    var question3SetURL: String {
        get {
            return (_question3SetURL)
        }
        set (newVal) {
            _question3SetURL = newVal
        }
    }
    
    var _option4 = ""
    var option4:String {
        get {
            return (_option4)
        }
        set (newVal) {
            _option4 = newVal
        }
    }

    var _option4Description = ""
    var option4Description: String {
        get {
            return (_option4Description)
        }
        set (newVal) {
            _option4Description = newVal
        }
    }
    
    var _question4SetURL = ""
    var question4SetURL: String {
        get {
            return (_question4SetURL)
        }
        set (newVal) {
            _question4SetURL = newVal
        }
    }
    
    var _option5 = ""
    var option5:String {
        get {
            return (_option5)
        }
        set (newVal) {
            _option5 = newVal
        }
    }

    var _option5Description = ""
    var option5Description: String {
        get {
            return (_option5Description)
        }
        set (newVal) {
            _option5Description = newVal
        }
    }
    
    var _question5SetURL = ""
    var question5SetURL: String {
        get {
            return (_question5SetURL)
        }
        set (newVal) {
            _question5SetURL = newVal
        }
    }
    
    var _option6 = ""
    var option6:String {
        get {
            return (_option6)
        }
        set (newVal) {
            _option6 = newVal
        }
    }

    var _option6Description = ""
    var option6Description: String {
        get {
            return (_option6Description)
        }
        set (newVal) {
            _option6Description = newVal
        }
    }
    
    var _question6SetURL = ""
    var question6SetURL: String {
        get {
            return (_question6SetURL)
        }
        set (newVal) {
            _question6SetURL = newVal
        }
    }
    
    var _option7 = ""
    var option7:String {
        get {
            return (_option7)
        }
        set (newVal) {
            _option7 = newVal
        }
    }

    var _option7Description = ""
    var option7Description: String {
        get {
            return (_option7Description)
        }
        set (newVal) {
            _option7Description = newVal
        }
    }
    
    var _question7SetURL = ""
    var question7SetURL: String {
        get {
            return (_question7SetURL)
        }
        set (newVal) {
            _question7SetURL = newVal
        }
    }
    
    var _option8 = ""
    var option8:String {
        get {
            return (_option8)
        }
        set (newVal) {
            _option8 = newVal
        }
    }

    var _option8Description = ""
    var option8Description: String {
        get {
            return (_option8Description)
        }
        set (newVal) {
            _option8Description = newVal
        }
    }
    
    var _question8SetURL = ""
    var question8SetURL: String {
        get {
            return (_question8SetURL)
        }
        set (newVal) {
            _question8SetURL = newVal
        }
    }
    
    var _option9 = ""
    var option9:String {
        get {
            return (_option9)
        }
        set (newVal) {
            _option9 = newVal
        }
    }

    var _option9Description = ""
    var option9Description: String {
        get {
            return (_option9Description)
        }
        set (newVal) {
            _option9Description = newVal
        }
    }
    
    var _question9SetURL = ""
    var question9SetURL: String {
        get {
            return (_question9SetURL)
        }
        set (newVal) {
            _question9SetURL = newVal
        }
    }
    
    var _option10 = ""
    var option10:String {
        get {
            return (_option10)
        }
        set (newVal) {
            _option10 = newVal
        }
    }

    var _option10Description = ""
    var option10Description: String {
        get {
            return (_option10Description)
        }
        set (newVal) {
            _option10Description = newVal
        }
    }
    
    var _question10SetURL = ""
    var question10SetURL: String {
        get {
            return (_question10SetURL)
        }
        set (newVal) {
            _question10SetURL = newVal
        }
    }
    
    var _required = ""
    var required: String {
        get {
            return (_required)
        }
        set (newVal) {
            _required = newVal
        }
    }
    
    var _questionDescription = ""
    var questionDescription: String {
        get {
            return (_questionDescription)
        }
        set (newVal) {
            _questionDescription = newVal
        }
    }
    
    var _acceptMultiple = ""
    var acceptMultiple: String {
        get {
            return (_acceptMultiple)
        }
        set (newVal) {
            _acceptMultiple = newVal
        }
    }
    
    var _questionAnswered = false
    var questionAnswered: Bool {
        get {
            return (_questionAnswered)
        }
        set (newVal) {
            _questionAnswered = newVal
        }
    }
    
    var _answer = ""
    var answer: String {
        get {
            return (_answer)
        }
        set (newVal) {
            _answer = newVal
        }
    }
    
    init(question: String)
    {
        super.init()
        self.question = question
    }

    required init(coder decoder: NSCoder)
    {
        super.init()
        self.question = (decoder.decodeObject(forKey: "question") as! String)
        self.answer = (decoder.decodeObject(forKey: "answer") as! String)
        self.questionAnswered = (decoder.decodeObject(forKey: "questionAnswered") as! Bool)
        self.acceptMultiple = (decoder.decodeObject(forKey: "acceptMultiple") as! String)
        self.questionDescription = (decoder.decodeObject(forKey: "questionDescription") as! String)
        self.required = (decoder.decodeObject(forKey: "required") as! String)
        self.question5SetURL = (decoder.decodeObject(forKey: "question5SetURL") as! String)
        self.option5Description = (decoder.decodeObject(forKey: "option5Description") as! String)
        self.option5 = (decoder.decodeObject(forKey: "option5") as! String)
        self.question4SetURL = (decoder.decodeObject(forKey: "question4SetURL") as! String)
        self.option4Description = (decoder.decodeObject(forKey: "option4Description") as! String)
        self.option4 = (decoder.decodeObject(forKey: "option4") as! String)
        self.question3SetURL = (decoder.decodeObject(forKey: "question3SetURL") as! String)
        self.option3Description = (decoder.decodeObject(forKey: "option3Description") as! String)
        self.option3 = (decoder.decodeObject(forKey: "option3") as! String)
        self.question2SetURL = (decoder.decodeObject(forKey: "question2SetURL") as! String)
        self.option2Description = (decoder.decodeObject(forKey: "option2Description") as! String)
        self.option2 = (decoder.decodeObject(forKey: "option2") as! String)
        self.question1SetURL = (decoder.decodeObject(forKey: "question1SetURL") as! String)
        self.option1Description = (decoder.decodeObject(forKey: "option1Description") as! String)
        self.option1 = (decoder.decodeObject(forKey: "option1") as! String)
    }

    func encode(with coder: NSCoder) {
        coder.encode(self.question, forKey: "question")
        coder.encode(self.answer, forKey: "answer")
        coder.encode(self.questionAnswered, forKey: "questionAnswered")
        coder.encode(self.acceptMultiple, forKey: "acceptMultiple")
        coder.encode(self.questionDescription, forKey: "questionDescription")
        coder.encode(self.required, forKey: "required")
        coder.encode(self.question5SetURL, forKey: "question5SetURL")
        coder.encode(self.option5Description, forKey: "option5Description")
        coder.encode(self.option5, forKey: "option5")
        coder.encode(self.question4SetURL, forKey: "question4SetURL")
        coder.encode(self.option4Description, forKey: "option4Description")
        coder.encode(self.option4, forKey: "option4")
        coder.encode(self.question3SetURL, forKey: "question3SetURL")
        coder.encode(self.option3Description, forKey: "option3Description")
        coder.encode(self.option3, forKey: "option3")
        coder.encode(self.question2SetURL, forKey: "question2SetURL")
        coder.encode(self.option2Description, forKey: "option2Description")
        coder.encode(self.option2, forKey: "option2")
        coder.encode(self.question1SetURL, forKey: "question1SetURL")
        coder.encode(self.option1Description, forKey: "option1Description")
        coder.encode(self.option1, forKey: "option1")
    }
}
