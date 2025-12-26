//
//  GamePushHeroAnimator.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 10/15/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//
import UIKit

protocol PushHeroPresentingDelegate: AnyObject {
    func pushHero_startingImageView(for transition: CommunityPushHeroAnimator) -> UIImageView?
}

protocol PushHeroPresentedDelegate: AnyObject {
    func pushHero_destinationImageView(for transition: CommunityPushHeroAnimator) -> UIImageView?
    func pushHero_topViews(for transition: CommunityPushHeroAnimator) -> [UIView]
    func pushHero_prepareForMeasurement()
}

protocol HeroTransitionPreparable {
    func prepareForHeroTransition()
}

// MARK: - CommunityPushHeroAnimator (Updated for SwiftUI Support)

final class CommunityPushHeroAnimator: NSObject, UIViewControllerAnimatedTransitioning {

    let presenting: Bool
    weak var presentingDelegate: PushHeroPresentingDelegate?
    private let snapshotTag = 901

    init(presenting: Bool) {
        self.presenting = presenting
        super.init()
    }

    func transitionDuration(using ctx: UIViewControllerContextTransitioning?) -> TimeInterval { 0.6 }

    func animateTransition(using ctx: UIViewControllerContextTransitioning) {
        presenting ? animatePush(using: ctx) : animatePop(using: ctx)
    }

    // MARK: - PUSH

    private func animatePush(using ctx: UIViewControllerContextTransitioning) {
        let container = ctx.containerView
        let duration  = transitionDuration(using: ctx)
        let TID = shortTID()
        L(TID, "=== BEGIN PUSH ===")

        guard
            let toVC = ctx.viewController(forKey: .to),
            let fromVC = ctx.viewController(forKey: .from)
        else { E(TID, "missing to/from VC"); ctx.completeTransition(false); return }

        L(TID, "toVC=\(type(of: toVC)) fromVC=\(type(of: fromVC))")

        // Let the presenting VC prepare if needed
        (presentingDelegate as? HeroTransitionPreparable)?.prepareForHeroTransition()

        // Get delegates - support both UIKit and SwiftUI (via hosting controller)
        guard
            let presented = (toVC as? PushHeroPresentedDelegate)
                ?? ((toVC as? UINavigationController)?.topViewController as? PushHeroPresentedDelegate),
            let startIV = presentingDelegate?.pushHero_startingImageView(for: self),
            let destIV  = presented.pushHero_destinationImageView(for: self)
        else {
            E(TID, "delegates or image views not found → crossfade fallback")
            fallbackCrossfade(ctx: ctx, toVC: toVC)
            return
        }

        L(TID, "startIV found, destIV found")

        container.addSubview(toVC.view)
        toVC.view.frame = ctx.finalFrame(for: toVC)
        toVC.view.layoutIfNeeded()
        presented.pushHero_prepareForMeasurement()
        toVC.view.layoutIfNeeded()
        toVC.view.alpha = 0

        // Dimming
        let dimming = UIView(frame: container.bounds)
        dimming.backgroundColor = .black
        dimming.alpha = 0
        container.insertSubview(dimming, belowSubview: toVC.view)

        // Compute frames
        let startFrame = frameInContainer(of: startIV, container: container)
        let endFrame   = frameInContainer(of: destIV,  container: container)
        L(TID, "startFrame=\(startFrame.d) endFrame=\(endFrame.d)")

        // Defensive fallback
        if endFrame.isEmpty || endFrame.width < 4 || endFrame.height < 4 {
            E(TID, "endFrame invalid → crossfade fallback")
            dimming.removeFromSuperview()
            fallbackCrossfade(ctx: ctx, toVC: toVC)
            return
        }
        
        // Temporarily unhide start view
        let wasHidden = startIV.isHidden
        startIV.isHidden = false
        startIV.superview?.layoutIfNeeded()

        // Build flight snapshot
        let snap = UIImageView(frame: startFrame)
        if let img = startIV.image {
            snap.image = img
        } else {
            snap.image = snapshotImage(from: startIV)
        }
        
        if snap.image == nil {
            E(TID, "⚠️ Snapshot is nil! Falling back to crossfade")
            startIV.isHidden = wasHidden
            dimming.removeFromSuperview()
            fallbackCrossfade(ctx: ctx, toVC: toVC)
            return
        }
        
        snap.contentMode = .scaleAspectFill
        snap.clipsToBounds = true
        snap.layer.cornerRadius = startIV.layer.cornerRadius
        container.addSubview(snap)

        // Hide real views
        startIV.isHidden = true
        destIV.isHidden  = true

        // Animate
        UIView.animate(withDuration: duration,
                       delay: 0,
                       usingSpringWithDamping: 0.85,
                       initialSpringVelocity: 0.1,
                       options: .curveEaseInOut,
                       animations: {
            snap.frame = endFrame
            snap.layer.cornerRadius = destIV.layer.cornerRadius
            toVC.view.alpha = 1.0
            dimming.alpha = 0.7
            fromVC.view.alpha = 0.0

        }, completion: { _ in
            L(TID, "push: animation complete")

            guard let destSuper = destIV.superview else {
                E(TID, "destIV has no superview — cleanup & finish")
                startIV.isHidden = false
                snap.removeFromSuperview()
                dimming.removeFromSuperview()
                fromVC.view.alpha = 1.0
                ctx.completeTransition(!ctx.transitionWasCancelled)
                return
            }

            // Pin snapshot to destination
            snap.tag = self.snapshotTag
            destSuper.addSubview(snap)
            snap.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                snap.topAnchor.constraint(equalTo: destIV.topAnchor),
                snap.leadingAnchor.constraint(equalTo: destIV.leadingAnchor),
                snap.trailingAnchor.constraint(equalTo: destIV.trailingAnchor),
                snap.bottomAnchor.constraint(equalTo: destIV.bottomAnchor)
            ])

            let top = presented.pushHero_topViews(for: self)
            top.forEach { $0.superview?.bringSubviewToFront($0) }

            // Handoff: swap immediately or observe for image load
            if destIV.image != nil {
                L(TID, "dest already has image — swap immediately")
                destIV.isHidden = false
                snap.removeFromSuperview()
            } else {
                var obs: NSKeyValueObservation?
                obs = destIV.observe(\.image, options: [.new]) { [weak destIV, weak snap] _, change in
                    guard let iv = destIV, let pin = snap else { obs = nil; return }
                    if change.newValue as? UIImage != nil {
                        L(TID, "dest image arrived — reveal & remove snapshot")
                        iv.isHidden = false
                        pin.removeFromSuperview()
                        obs = nil
                    }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) { [weak destIV, weak snap] in
                    guard let iv = destIV, let pin = snap, pin.superview != nil else { return }
                    L(TID, "timeout — revealing dest & removing snapshot")
                    iv.isHidden = false
                    pin.removeFromSuperview()
                }
            }
            
            fromVC.view.alpha = 1.0
            startIV.isHidden = false
            dimming.removeFromSuperview()
            ctx.completeTransition(!ctx.transitionWasCancelled)
        })
    }

    // MARK: - POP

    private func animatePop(using ctx: UIViewControllerContextTransitioning) {
        let container = ctx.containerView
        let duration  = transitionDuration(using: ctx)
        let TID = shortTID()
        L(TID, "=== BEGIN POP ===")

        guard
            let fromVC = ctx.viewController(forKey: .from),
            let toVC   = ctx.viewController(forKey: .to)
        else { E(TID, "missing to/from VC"); ctx.completeTransition(false); return }

        // Get delegates - support both UIKit and SwiftUI
        guard
            let presented = (fromVC as? PushHeroPresentedDelegate)
                ?? ((fromVC as? UINavigationController)?.topViewController as? PushHeroPresentedDelegate),
            let destIV  = presented.pushHero_destinationImageView(for: self),
            let startIV = presentingDelegate?.pushHero_startingImageView(for: self)
        else {
            E(TID, "delegates or image views not found → fade fallback")
            fallbackFade(ctx: ctx, fromVC: fromVC)
            return
        }

        // Ensure toVC is in hierarchy
        if toVC.view.superview == nil {
            container.insertSubview(toVC.view, belowSubview: fromVC.view)
            toVC.view.frame = ctx.finalFrame(for: toVC)
        }
        toVC.view.layoutIfNeeded()

        // Find source for moving snapshot
        let pinned = destIV.superview?.viewWithTag(self.snapshotTag) as? UIImageView
        let sourceForFlight: UIView = pinned ?? destIV
        if pinned == nil && destIV.isHidden {
            destIV.isHidden = false
        }

        // Build moving snapshot
        let moving = UIImageView()
        moving.image = (sourceForFlight as? UIImageView)?.image ?? destIV.image
        moving.contentMode = .scaleAspectFill
        moving.clipsToBounds = true
        moving.layer.cornerRadius = sourceForFlight.layer.cornerRadius
        moving.layer.masksToBounds = true

        // Compute frames
        guard let srcSuper = sourceForFlight.superview else {
            E(TID, "sourceForFlight has no superview")
            fallbackFade(ctx: ctx, fromVC: fromVC)
            return
        }
        let startFrame = srcSuper.convert(sourceForFlight.frame, to: container)
        container.addSubview(moving)
        moving.frame = startFrame

        guard let startSuper = startIV.superview else {
            E(TID, "startIV has no superview → fade fallback")
            let dim = UIView(frame: container.bounds)
            dim.backgroundColor = .black
            dim.alpha = 0.7
            container.insertSubview(dim, belowSubview: fromVC.view)
            UIView.animate(withDuration: 0.25, animations: {
                fromVC.view.alpha = 0
                dim.alpha = 0
            }, completion: { _ in
                moving.removeFromSuperview()
                dim.removeFromSuperview()
                ctx.completeTransition(true)
            })
            return
        }
        let endFrame = startSuper.convert(startIV.frame, to: container)

        // Dimming
        let dimming = UIView(frame: container.bounds)
        dimming.backgroundColor = .black
        dimming.alpha = 0.7
        container.insertSubview(dimming, belowSubview: fromVC.view)

        // Hide reals
        startIV.isHidden = true
        destIV.isHidden  = true
        pinned?.isHidden = true

        // Animate
        UIView.animate(withDuration: duration,
                       delay: 0,
                       usingSpringWithDamping: 0.85,
                       initialSpringVelocity: 0.1,
                       options: .curveEaseInOut,
                       animations: {
            moving.frame = endFrame
            moving.layer.cornerRadius = startIV.layer.cornerRadius
            fromVC.view.alpha = 0.0
            dimming.alpha = 0.0
        }, completion: { _ in
            startIV.isHidden = false
            destIV.isHidden  = false
            pinned?.isHidden = false
            moving.removeFromSuperview()
            dimming.removeFromSuperview()
            ctx.completeTransition(!ctx.transitionWasCancelled)
            L(TID, "POP complete")
        })
    }
    
    // MARK: - Fallbacks
    
    private func fallbackCrossfade(ctx: UIViewControllerContextTransitioning, toVC: UIViewController) {
        let container = ctx.containerView
        if toVC.view.superview == nil {
            container.addSubview(toVC.view)
            toVC.view.frame = ctx.finalFrame(for: toVC)
        }
        toVC.view.alpha = 0
        
        UIView.animate(withDuration: 0.25, animations: {
            toVC.view.alpha = 1.0
        }, completion: { _ in
            ctx.completeTransition(true)
        })
    }
    
    private func fallbackFade(ctx: UIViewControllerContextTransitioning, fromVC: UIViewController) {
        UIView.animate(withDuration: 0.25, animations: {
            fromVC.view.alpha = 0
        }, completion: { _ in
            ctx.completeTransition(true)
        })
    }
}

// MARK: - Helpers

private func frameInContainer(of view: UIView, container: UIView) -> CGRect {
    guard let superview = view.superview else { return .zero }
    return superview.convert(view.frame, to: container)
}

private func snapshotImage(from view: UIView) -> UIImage? {
    if let iv = view as? UIImageView, let img = iv.image { return img }
    let bounds = view.bounds
    guard bounds.width > 0, bounds.height > 0 else { return nil }
    let renderer = UIGraphicsImageRenderer(bounds: bounds)
    return renderer.image { _ in
        view.drawHierarchy(in: bounds, afterScreenUpdates: true)
    }
}

// MARK: - Logging

private func shortTID() -> String { String(UUID().uuidString.prefix(6)) }

private func L(_ tid: String, _ msg: @autoclosure () -> String) {
    print("🧭 [Hero \(tid)] \(msg())")
}

private func E(_ tid: String, _ msg: @autoclosure () -> String) {
    print("🛑 [Hero \(tid)] \(msg())")
}

private extension CGRect {
    var d: String {
        "x:\(String(format: "%.1f", origin.x)) y:\(String(format: "%.1f", origin.y)) w:\(String(format: "%.1f", size.width)) h:\(String(format: "%.1f", size.height))"
    }
}


/*## 🎯 How to Use Hero Animation with ANY SwiftUI View
 
 ### Step 1: Create your SwiftUI view
 ```swift
 struct MyView: View {
     let data: MyData
     @ObservedObject var bridge: HeroAnimatorBridge
     let startingImage: UIImage?
     
     var body: some View {
         VStack {
             // Use HeroImageView for the animated image
             HeroImageView(
                 url: data.imageURL,
                 bridge: bridge,
                 startingImage: startingImage
             )
             .frame(height: 200)
             
             // Rest of your content
             Text("My Content")
         }
     }
 }
 ```
 
 ### Step 2: Navigate to it
 ```swift
 let vc = HeroHostingController.create { bridge, image in
     MyView(data: myData, bridge: bridge, startingImage: image)
 }
 navigationController?.pushViewController(vc, animated: true)
 ```
 
 ### That's it! ✨
 
 ## 📋 Checklist for New Views:
 
 1. ✅ Add `@ObservedObject var bridge: HeroAnimatorBridge` property
 2. ✅ Add `let startingImage: UIImage?` property
 3. ✅ Use `HeroImageView` for the image that animates
 4. ✅ Create with `HeroHostingController.create(...)`
 5. ✅ Make sure presenting VC conforms to `PushHeroPresentingDelegate`
 6. ✅ Make sure presenting VC implements navigation controller delegate
 
 ## 🔧 Components:
 
 - `HeroAnimatorBridge` - Holds the UIImageView reference (reusable)
 - `HeroHostingController` - Generic hosting controller (reusable)
 - `HeroImageView` - SwiftUI wrapper for UIImageView (reusable)
 - `CommunityPushHeroAnimator` - The actual animator (reusable)
 
 All components are 100% reusable across any SwiftUI view! 🎉
 
 */
