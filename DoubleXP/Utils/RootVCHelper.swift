//
//  File.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 6/22/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//

import Foundation
import UIKit

extension UIApplication {
    private var activeKeyWindow: UIWindow? {
        connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .filter { $0.activationState == .foregroundActive }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
    }

    /// Replace app root with an animated transition.
    static func switchRoot<T: UIViewController>(
        to viewControllerType: T.Type,
        storyboardName: String = "Main",
        storyboardId: String? = nil,
        animationDuration: CFTimeInterval = 0.3,
        animationType: CATransitionType = .fade,
        animationSubtype: CATransitionSubtype? = nil
    ) {
        guard let window = UIApplication.shared.activeKeyWindow else { return }

        // Instantiate the new root VC
        let sb = UIStoryboard(name: storyboardName, bundle: nil)
        let id = storyboardId ?? String(describing: T.self)
        guard let newVC = sb.instantiateViewController(withIdentifier: id) as? T else {
            fatalError("VC with identifier '\(id)' not found in \(storyboardName)")
        }
        let nav = UINavigationController(rootViewController: newVC)

        // Setup transition
        let transition = CATransition()
        transition.duration = animationDuration
        transition.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        transition.type = animationType
        if let subtype = animationSubtype {
            transition.subtype = subtype
        }

        // Apply it and switch
        window.layer.add(transition, forKey: kCATransition)
        window.rootViewController = nav
        window.makeKeyAndVisible()
    }
}
