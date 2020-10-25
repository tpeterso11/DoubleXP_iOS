//
//  TestSegue.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 10/17/20.
//  Copyright © 2020 Peterson, Toussaint. All rights reserved.
//
import UIKit
import SPStorkController
import Foundation
public class TestSegue: UIStoryboardSegue {
    
    public var transitioningDelegate: SPStorkTransitioningDelegate?
    
    override public func perform() {
        transitioningDelegate = transitioningDelegate ?? SPStorkTransitioningDelegate()
        destination.transitioningDelegate = transitioningDelegate
        destination.modalPresentationStyle = .custom
        super.perform()
    }
}
