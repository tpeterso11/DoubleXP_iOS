//
//  GameTransitionAnimator.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 10/2/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//

import UIKit

/// A protocol for the view controller that is *presenting* the transition.
protocol TransitionPresentingDelegate: AnyObject {
    func getStartingImageView(for transition: GameTransitionAnimator) -> UIImageView?
}

// We are re-introducing the getTopViews requirement.
protocol TransitionPresentedDelegate: AnyObject {
    func getDestinationImageView(for transition: GameTransitionAnimator) -> UIImageView?
    func getTopViews(for transition: GameTransitionAnimator) -> [UIView]
}

class GameTransitionDelegate: NSObject, ObservableObject, UIViewControllerTransitioningDelegate, TransitionPresentingDelegate {
    
    // @Published allows SwiftUI to react and hide the source image
    @Published var transitioningGameID: String? = nil
    
    // This is the dummy UIImageView from our host VC
    weak var startingImageView: UIImageView?
    
    /// Call this from the animator's completion block to clean up
    func clearTransitionState() {
        DispatchQueue.main.async {
            self.transitioningGameID = nil
            self.startingImageView?.image = nil
        }
    }
    
    // MARK: - TransitionPresentingDelegate
    
    func getStartingImageView(for transition: GameTransitionAnimator) -> UIImageView? {
        return self.startingImageView
    }
    
    // MARK: - UIViewControllerTransitioningDelegate
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        let animator = GameTransitionAnimator(presenting: true)
        animator.presentingDelegate = self
        return animator
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        let animator = GameTransitionAnimator(presenting: false)
        animator.presentingDelegate = self
        return animator
    }
}

class GameTransitionAnimator: NSObject, UIViewControllerAnimatedTransitioning {

    let presenting: Bool
    weak var presentingDelegate: TransitionPresentingDelegate?
    private let snapshotTag = 101

    init(presenting: Bool) {
        self.presenting = presenting
        super.init()
    }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.6
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        if presenting {
            animatePresentation(using: transitionContext)
        } else {
            animateDismissal(using: transitionContext)
        }
    }
    
    // MARK: - Presentation Animation
    
    func animatePresentation(using transitionContext: UIViewControllerContextTransitioning) {
        print("\n--- [Animator] Starting Presentation ---")
        let containerView = transitionContext.containerView
        let duration = transitionDuration(using: transitionContext)
        
        guard let toVC = transitionContext.viewController(forKey: .to),
              let presentingDelegate = self.presentingDelegate,
              let presentedDelegate = (toVC as? UINavigationController)?.topViewController as? TransitionPresentedDelegate,
              let startingImageView = presentingDelegate.getStartingImageView(for: self),
              let destinationImageView = presentedDelegate.getDestinationImageView(for: self)
        else {
            print("🔴 [Animator] FAILED: Pre-animation checks failed.")
            transitionContext.completeTransition(false)
            return
        }
        print("✅ [Animator] All delegates and views acquired.")
        
        if let presentedVC = presentedDelegate as? UIViewController { presentedVC.loadViewIfNeeded() }
        
        let dimmingView = UIView(frame: containerView.bounds)
        dimmingView.backgroundColor = .black; dimmingView.alpha = 0
        containerView.addSubview(dimmingView)

        containerView.addSubview(toVC.view)
        toVC.view.frame = transitionContext.finalFrame(for: toVC)
        toVC.view.layoutIfNeeded(); toVC.view.alpha = 0

        let startFrame = containerView.convert(startingImageView.frame, from: startingImageView.superview)
        let endFrame = containerView.convert(destinationImageView.frame, from: destinationImageView.superview)

        let snapshot = UIImageView(frame: startFrame)
        snapshot.image = startingImageView.image; snapshot.contentMode = .scaleAspectFill
        snapshot.clipsToBounds = true; snapshot.layer.cornerRadius = startingImageView.layer.cornerRadius
        containerView.addSubview(snapshot)
        
        startingImageView.isHidden = true
        destinationImageView.isHidden = true
        
        UIView.animate(withDuration: duration, delay: 0, usingSpringWithDamping: 0.85, initialSpringVelocity: 0.1, options: .curveEaseInOut, animations: {
            snapshot.frame = endFrame
            snapshot.layer.cornerRadius = destinationImageView.layer.cornerRadius
            toVC.view.alpha = 1.0; dimmingView.alpha = 0.7
        }) { _ in
            print("✅ [Animator] Main animation finished. Starting cleanup.")
            guard let superview = destinationImageView.superview else {
                return
            }
            
            snapshot.tag = self.snapshotTag
            superview.addSubview(snapshot)
            snapshot.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                snapshot.topAnchor.constraint(equalTo: destinationImageView.topAnchor),
                snapshot.leadingAnchor.constraint(equalTo: destinationImageView.leadingAnchor),
                snapshot.trailingAnchor.constraint(equalTo: destinationImageView.trailingAnchor),
                snapshot.bottomAnchor.constraint(equalTo: destinationImageView.bottomAnchor)
            ])
            print("✅ [Animator] Snapshot re-parented and constrained.")

            let topViews = presentedDelegate.getTopViews(for: self)
            print("🟡 [Animator] Found \(topViews.count) views to bring to the front.")
            for topView in topViews {
                superview.bringSubviewToFront(topView)
                print("  - Brought \(type(of: topView)) to front.")
            }

            startingImageView.isHidden = false
            dimmingView.removeFromSuperview()
            
            (self.presentingDelegate as? GameTransitionDelegate)?.clearTransitionState()
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            print("--- [Animator] Presentation Completed Successfully ---")
        }
    }
    
    // MARK: - Dismissal Animation
    
    func animateDismissal(using transitionContext: UIViewControllerContextTransitioning) {
        let TID = UUID().uuidString.prefix(8) // Short trace id
        func L(_ msg: @autoclosure () -> String) { print("🧭 [Dismiss \(TID)] \(msg())") }
        func E(_ msg: @autoclosure () -> String) { print("🛑 [Dismiss \(TID)] \(msg())") }

        L("=== BEGIN DISMISS ===")
        L("Thread: \(Thread.isMainThread ? "Main" : "Background")")
        let t0 = CACurrentMediaTime()

        let containerView = transitionContext.containerView
        let duration = transitionDuration(using: transitionContext)
        L("Container: \(containerView), frame: \(containerView.frame.d), bounds: \(containerView.bounds.d)")
        L("Duration: \(duration)s, presenting? \(presenting ? "YES" : "NO")")

        // 1) Get VCs
        guard
            let fromVC = transitionContext.viewController(forKey: .from),
            let toVC   = transitionContext.viewController(forKey: .to)
        else {
            E("Missing fromVC and/or toVC"); transitionContext.completeTransition(false); return
        }
        L("fromVC: \(type(of: fromVC))  | toVC: \(type(of: toVC))")
        L("fromVC.view.frame=\(fmt(fromVC.view?.frame)) | toVC.view.frame=\(fmt(toVC.view?.frame))")

        // 2) Ensure toVC is in hierarchy & laid out (critical for correct endFrame)
        if toVC.view.superview == nil {
            containerView.insertSubview(toVC.view, belowSubview: fromVC.view)
            toVC.view.frame = transitionContext.finalFrame(for: toVC)
            L("Inserted toVC.view below fromVC.view. toVC.finalFrame: \(toVC.view.frame.d)")
        } else {
            L("toVC.view already in container (super: \(String(describing: toVC.view.superview)))")
        }
        toVC.view.layoutIfNeeded()
        L("toVC.view.layoutIfNeeded() done. toVC.view.frame after layout: \(toVC.view.frame.d)")

        // 3) Delegates
        guard let presentingDelegate = self.presentingDelegate else {
            E("No presentingDelegate — fade fallback")
            UIView.animate(withDuration: 0.25, animations: { fromVC.view.alpha = 0 }) { _ in
                transitionContext.completeTransition(true)
                L("Completed via fade fallback (no presentingDelegate).")
            }
            return
        }
        L("presentingDelegate OK")

        guard
            let presentedDelegate = (fromVC as? UINavigationController)?.topViewController as? TransitionPresentedDelegate
        else {
            E("fromVC not UINavigationController(top conforms) or no TransitionPresentedDelegate — fade fallback")
            UIView.animate(withDuration: 0.25, animations: { fromVC.view.alpha = 0 }) { _ in
                transitionContext.completeTransition(true)
                L("Completed via fade fallback (presentedDelegate missing).")
            }
            return
        }
        L("presentedDelegate OK: \(type(of: presentedDelegate))")

        // 4) Destination (presented side) image & pinned snapshot
        guard let destinationImageView = presentedDelegate.getDestinationImageView(for: self) else {
            E("getDestinationImageView returned nil — fade fallback")
            UIView.animate(withDuration: 0.25, animations: { fromVC.view.alpha = 0 }) { _ in
                transitionContext.completeTransition(true)
                L("Completed via fade fallback (no destinationImageView).")
            }
            return
        }
        L("destinationImageView found: \(destinationImageView.debugLineage(prefix: "dest"))")
        L("dest.hidden=\(destinationImageView.isHidden) mode=\(destinationImageView.contentMode.rawValue) cr=\(destinationImageView.layer.cornerRadius)")

        let destSuper = destinationImageView.superview
        let pinnedSnapshot = destSuper?.viewWithTag(self.snapshotTag) as? UIImageView
        L("Pinned snapshot lookup by tag=\(self.snapshotTag): \(pinnedSnapshot != nil ? "FOUND" : "NOT FOUND")")
        if let ps = pinnedSnapshot {
            L("pinnedSnapshot: \(ps.debugLineage(prefix: "pin"))")
            L("pin.hidden=\(ps.isHidden) mode=\(ps.contentMode.rawValue) cr=\(ps.layer.cornerRadius)")
        }

        // 5) Source of truth for what the user SEES on the presented screen
        let sourceViewForSnapshot: UIView = pinnedSnapshot ?? destinationImageView
        L("Source for moving snapshot: \(sourceViewForSnapshot === pinnedSnapshot ? "pinnedSnapshot" : "destinationImageView")")

        // If we did not have pinned snapshot, the destinationImageView was likely hidden during presentation
        if pinnedSnapshot == nil && destinationImageView.isHidden {
            L("destinationImageView was hidden — unhiding so snapshot is accurate")
            destinationImageView.isHidden = false
        }

        // 6) Build MOVING snapshot we can animate in container coords
        guard let movingSnapshot = sourceViewForSnapshot.snapshotView(afterScreenUpdates: true) else {
            E("Could not snapshot sourceViewForSnapshot — fade fallback")
            UIView.animate(withDuration: 0.25, animations: { fromVC.view.alpha = 0 }) { _ in
                transitionContext.completeTransition(true)
                L("Completed via fade fallback (no snapshot).")
            }
            return
        }
        movingSnapshot.layer.masksToBounds = true
        movingSnapshot.layer.cornerRadius = sourceViewForSnapshot.layer.cornerRadius
        movingSnapshot.contentMode = (sourceViewForSnapshot as? UIImageView)?.contentMode ?? .scaleToFill

        // 7) Compute start frame from sourceViewForSnapshot
        guard let srcSuper = sourceViewForSnapshot.superview else {
            E("sourceViewForSnapshot has no superview — cannot convert rect")
            transitionContext.completeTransition(false)
            return
        }
        let startFrame = srcSuper.convert(sourceViewForSnapshot.frame, to: containerView)
        movingSnapshot.frame = startFrame
        containerView.addSubview(movingSnapshot)

        L("Start frame: \(startFrame.d)")
        L("Start in local: \(sourceViewForSnapshot.frame.d) | super: \(String(describing: srcSuper))")
        L("movingSnapshot cornerRadius=\(movingSnapshot.layer.cornerRadius) contentMode=\(movingSnapshot.contentMode.rawValue)")

        // 8) Dimming (mirror of presentation)
        let dimmingView = UIView(frame: containerView.bounds)
        dimmingView.backgroundColor = .black
        dimmingView.alpha = 0.7
        containerView.insertSubview(dimmingView, belowSubview: fromVC.view)
        L("Inserted dimmingView (alpha 0.7) below fromVC.view")

        // 9) Find the STARTING image (in presenting VC). If off-screen → fade fallback.
        guard let startingImageView = presentingDelegate.getStartingImageView(for: self) else {
            L("Starting image NIL (off-screen cell likely) — fade fallback path")
            UIView.animate(withDuration: 0.25, animations: {
                fromVC.view.alpha = 0; dimmingView.alpha = 0
            }, completion: { _ in
                movingSnapshot.removeFromSuperview()
                transitionContext.completeTransition(true)
                L("Completed via fade fallback (off-screen start).")
            })
            return
        }
        L("startingImageView found: \(startingImageView.debugLineage(prefix: "start"))")
        L("start.hidden=\(startingImageView.isHidden) mode=\(startingImageView.contentMode.rawValue) cr=\(startingImageView.layer.cornerRadius)")

        // Safety: layout again in case the delegate scrolled to make the cell visible
        toVC.view.layoutIfNeeded()
        L("toVC.view.layoutIfNeeded() AGAIN after getStartingImageView")

        guard let startSuper = startingImageView.superview else {
            E("startingImageView has no superview — cannot convert end frame")
            UIView.animate(withDuration: 0.25, animations: { fromVC.view.alpha = 0; dimmingView.alpha = 0 }) { _ in
                movingSnapshot.removeFromSuperview()
                transitionContext.completeTransition(true)
                L("Completed via fade fallback (no superview for start).")
            }
            return
        }
        let endFrame = startSuper.convert(startingImageView.frame, to: containerView)
        L("Computed endFrame: \(endFrame.d)")
        L("start local frame: \(startingImageView.frame.d)")

        // 10) Hide real views to avoid double-vision
        startingImageView.isHidden = true
        destinationImageView.isHidden = true
        pinnedSnapshot?.isHidden = true
        L("Hidden: start/dest/pin (pin exists? \(pinnedSnapshot != nil))")

        // 11) Animate
        L("Begin animation → duration=\(duration), damping=0.85, velocity=0.1")
        UIView.animate(withDuration: duration,
                       delay: 0,
                       usingSpringWithDamping: 0.85,
                       initialSpringVelocity: 0.1,
                       options: .curveEaseInOut,
                       animations: {
            movingSnapshot.frame = endFrame
            movingSnapshot.layer.cornerRadius = startingImageView.layer.cornerRadius
            fromVC.view.alpha = 0.0
            dimmingView.alpha = 0.0
        }, completion: { _ in
            L("Animation block finished")
            // 12) Cleanup
            startingImageView.isHidden = false
            pinnedSnapshot?.isHidden = false
            movingSnapshot.removeFromSuperview()
            dimmingView.removeFromSuperview()

            let success = !transitionContext.transitionWasCancelled
            (self.presentingDelegate as? GameTransitionDelegate)?.clearTransitionState()
            transitionContext.completeTransition(success)
            let t1 = CACurrentMediaTime()
            L("Completed transition. Success=\(success). Elapsed=\(String(format: "%.3f", t1 - t0))s")
            L("=== END DISMISS ===")
        })
    }
}

private extension CGRect {
    var d: String {
        "x:\(String(format: "%.1f", origin.x)) y:\(String(format: "%.1f", origin.y)) w:\(String(format: "%.1f", size.width)) h:\(String(format: "%.1f", size.height))"
    }
    static var na: String { "n/a" }
}

private extension UIView {
    /// Walks up the superview chain and reports frames + classes (great for “where am I?” bugs)
    func debugLineage(prefix: String = "view") -> String {
        var parts: [String] = []
        var v: UIView? = self
        var idx = 0
        while let cur = v, idx < 12 {
            let name = String(describing: type(of: cur))
            parts.append("\(idx == 0 ? "\(prefix)" : "↑"):\(name){\(cur.frame.d)} hidden=\(cur.isHidden)")
            v = cur.superview
            idx += 1
        }
        return parts.joined(separator: "  ")
    }
}
private func fmt(_ rect: CGRect?) -> String { rect.map { $0.d } ?? "n/a" }
