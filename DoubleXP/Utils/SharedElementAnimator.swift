//
//  SharedElementAnimator.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 10/6/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//

import Foundation
import UIKit

/// Any view controller that wants to participate in a shared element transition
/// must conform to this protocol.
protocol SharedElementSource {
    /// Returns a dictionary mapping unique animation IDs to the views on screen.
    func getSharedElements() -> [String: UIView]
}

class TransitionIntent {
    let sourceViews: [String: UIView]
    
    init(sourceViews: [String: UIView]) {
        self.sourceViews = sourceViews
    }
}

// MARK: - The "Hero-Style" Animator

class SharedElementAnimator: NSObject, UIViewControllerAnimatedTransitioning {

    private let duration = 0.6
    private let intent: TransitionIntent

    init(intent: TransitionIntent) {
        self.intent = intent
        super.init()
    }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return duration
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView
        
        guard let toVC = transitionContext.viewController(forKey: .to) else {
            transitionContext.completeTransition(false)
            return
        }
        
        // --- VISUAL DEBUGGER: Check for delegate conformance ---
        guard let toSource = (toVC as? UINavigationController)?.topViewController as? SharedElementSource else {
            print("🔴 [Animator] FAILED: Could not get `toSource` delegate. Triggering CYAN fallback.")
            if let toView = toVC.view {
                toView.alpha = 0
                containerView.addSubview(toView)
                // Make the fallback visually obvious
                toView.backgroundColor = .cyan
                UIView.animate(withDuration: 0.3) { toView.alpha = 1 } completion: { _ in transitionContext.completeTransition(true) }
            } else {
                transitionContext.completeTransition(false)
            }
            return
        }
        
        containerView.addSubview(toVC.view)
        toVC.view.frame = transitionContext.finalFrame(for: toVC)
        toVC.view.alpha = 0
        toVC.view.layoutIfNeeded()

        let fromViews = intent.sourceViews
        let toViews = toSource.getSharedElements()

        var animatingViews: [(id: String, snapshot: UIView, endFrame: CGRect)] = []

        // --- Prepare and Create Snapshots ---
        let elementIDs = Array(fromViews.keys)
        elementIDs.forEach { id in
            fromViews[id]?.isHidden = true
            toViews[id]?.isHidden = true
        }
        
        for id in elementIDs {
            guard let fromView = fromViews[id], let toView = toViews[id],
                  let snapshot = fromView.snapshotView(afterScreenUpdates: true) else {
                print("🟡 [Animator] WARNING: Could not find matching views for ID: '\(id)'.")
                continue
            }
            
            // --- VISUAL DEBUGGER: Add borders to the real views ---
            fromView.layer.borderColor = UIColor.green.cgColor
            fromView.layer.borderWidth = 4
            toView.layer.borderColor = UIColor.red.cgColor
            toView.layer.borderWidth = 4
            // ----------------------------------------------------

            let startFrame = containerView.convert(fromView.frame, from: fromView.superview)
            let endFrame = containerView.convert(toView.frame, from: toView.superview)
            
            snapshot.frame = startFrame
            snapshot.layer.cornerRadius = fromView.layer.cornerRadius
            snapshot.clipsToBounds = true
            
            containerView.addSubview(snapshot)
            animatingViews.append((id, snapshot, endFrame))
        }

        // --- Animate Everything ---
        UIView.animate(withDuration: duration, delay: 0, usingSpringWithDamping: 0.85, initialSpringVelocity: 0.1, options: .curveEaseInOut, animations: {
            toVC.view.alpha = 1.0
            for (_, snapshot, endFrame) in animatingViews {
                snapshot.frame = endFrame
            }
        }) { _ in
            // --- The "Replace and Constrain" Cleanup ---
            for (id, snapshot, _) in animatingViews {
                guard let toView = toViews[id], let superview = toView.superview else { continue }
                superview.addSubview(snapshot)
                snapshot.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    snapshot.topAnchor.constraint(equalTo: toView.topAnchor),
                    snapshot.leadingAnchor.constraint(equalTo: toView.leadingAnchor),
                    snapshot.trailingAnchor.constraint(equalTo: toView.trailingAnchor),
                    snapshot.bottomAnchor.constraint(equalTo: toView.bottomAnchor)
                ])
            }
            
            // --- VISUAL DEBUGGER: Clean up borders ---
            elementIDs.forEach { id in
                fromViews[id]?.layer.borderWidth = 0
                toViews[id]?.layer.borderWidth = 0
                fromViews[id]?.isHidden = false
            }
            
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
    }
}
