//
//  Utility.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 12/25/19.
//  Copyright © 2019 Peterson, Toussaint. All rights reserved.
//

import Foundation
import UIKit

class Utility: NSObject{
    struct Image {
        static let placeholder = #imageLiteral(resourceName: "newlogo")
    }
}

extension UIView {
    enum Animation {
        case goOut
        case comeIn
    }
    
    func slideOutBottom(from: Animation = .goOut, startDelay: TimeInterval = 500, x: CGFloat = 0, y: CGFloat = 0, completion: ((Bool) -> Void)? = nil) -> UIView{
        let top = CGAffineTransform(translationX: 0, y: 20)

        UIView.animate(withDuration: 0.4, delay: 0.3, options: [], animations: {
            self.alpha = 0
            self.transform = top
        }, completion: nil)
        
        return self
    }
    
    func slideInBottom(from: Animation = .comeIn, startDelay: TimeInterval = 500, x: CGFloat = 0, y: CGFloat = 0, completion: ((Bool) -> Void)? = nil) -> UIView{
        
        let top = CGAffineTransform(translationX: 0, y: -10)

        UIView.animate(withDuration: 0.4, delay: 0.6, options: [], animations: {
            self.alpha = 1
            self.transform = top
        }, completion: nil)
        
        return self
    }
    
    func slideInBottomReset(from: Animation = .comeIn, startDelay: TimeInterval = 500, x: CGFloat = 0, y: CGFloat = 0, completion: ((Bool) -> Void)? = nil) -> UIView{
        
        let top = CGAffineTransform(translationX: 0, y: 0)

        UIView.animate(withDuration: 0.4, delay: 0.6, options: [], animations: {
            self.alpha = 1
            self.transform = top
        }, completion: nil)
        
        return self
    }
    
    func slideInBottomSmall(from: Animation = .comeIn, startDelay: TimeInterval = 500, x: CGFloat = 0, y: CGFloat = 0, distance: CGFloat = 0, completion: ((Bool) -> Void)? = nil) -> UIView{
           
           let top = CGAffineTransform(translationX: 0, y: -13)

           UIView.animate(withDuration: 0.4, delay: 0.3, options: [], animations: {
               self.alpha = 1
               self.transform = top
           }, completion: nil)
           
           return self
       }
    
    func slideOutBottomSecond(){
        let top = CGAffineTransform(translationX: 0, y: 0)

        UIView.animate(withDuration: 0.5, delay: 0.0, options: [], animations: {
            self.alpha = 0
            self.transform = top
        }, completion: nil)
    }
    
    func slideOutBottomSmall(){
        let top = CGAffineTransform(translationX: 0, y: 0)

        UIView.animate(withDuration: 0.5, delay: 0.0, options: [], animations: {
            self.alpha = 0
            self.transform = top
        }, completion: nil)
    }
    
    func slideInBottomNav(){
        let top = CGAffineTransform(translationX: 0, y: 0)

        UIView.animate(withDuration: 0.5, delay: 0.4, options: [], animations: {
            self.alpha = 1
            self.transform = top
        }, completion: nil)
    }
    
    func offsetFor(edge: Animation) -> CGPoint{
        if (self.superview?.frame.size) != nil{
            switch edge{
                case .comeIn: return CGPoint(x: 0, y: -frame.maxY)
                case .goOut: return CGPoint(x: 0, y: frame.maxY)
            }
        }
        return CGPoint(x: 0, y: 0)
    }
    
    func slideInLeftMenu(from: Animation = .comeIn, startDelay: TimeInterval = 500, x: CGFloat = 0, y: CGFloat = 0, distance: CGFloat = 0, completion: ((Bool) -> Void)? = nil) -> UIView{
        
        let top = CGAffineTransform(translationX: 0, y: -159)

        UIView.animate(withDuration: 0.4, delay: 0.3, options: [], animations: {
            self.alpha = 1
            self.transform = top
        }, completion: nil)
        
        return self
    }
}
