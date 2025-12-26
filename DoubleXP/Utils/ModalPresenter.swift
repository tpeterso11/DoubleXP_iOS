//
//  ModalPresenter.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 6/22/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//

import UIKit

enum HapticMoment {
    case willPresent
    case didPresent
    case willDismiss
    case didDismiss
}

class ModalPresenter: NSObject, UIAdaptivePresentationControllerDelegate {
    var willDismiss: (() -> Void)?
    var didDismiss: (() -> Void)?
    var hapticMoments: [HapticMoment] = []

    private weak var sheet: UISheetPresentationController?
    private var allowedDismissDetents: [UISheetPresentationController.Detent.Identifier]?

    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        guard let sheet = sheet else { return true }
        guard let current = sheet.selectedDetentIdentifier else { return true }

        if let allowed = allowedDismissDetents {
            return allowed.contains(current)
        }

        return true
    }

    func presentationControllerWillDismiss(_ presentationController: UIPresentationController) {
        if hapticMoments.contains(.willDismiss) {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
        willDismiss?()
    }

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        if hapticMoments.contains(.didDismiss) {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
        didDismiss?()
    }

    func registerSheet(_ sheet: UISheetPresentationController) {
        self.sheet = sheet
    }
}

extension ModalPresenter {
    
    /// Presents a draggable drawer-style modal with configurable custom height.
    static func presentCustomHeightDrawer<T: UIViewController>(
        _ viewControllerType: T.Type,
        from presenter: UIViewController,
        storyboardId: String? = nil,
        storyboardName: String = "Main",
        customHeight: CGFloat = 300,
        prefersGrabberVisible: Bool = true,
        hapticMoments: [HapticMoment] = [],
        willDismiss: (() -> Void)? = nil,
        didDismiss: (() -> Void)? = nil
    ) {
        let id = storyboardId ?? String(describing: T.self)
        let storyboard = UIStoryboard(name: storyboardName, bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: id) as! T
        let nav = UINavigationController(rootViewController: viewController)
        nav.modalPresentationStyle = .pageSheet

        let delegate = ModalPresenter()
        delegate.hapticMoments = hapticMoments
        delegate.willDismiss = willDismiss
        delegate.didDismiss = didDismiss
        delegate.allowedDismissDetents = [.init("low")]

        if let sheet = nav.sheetPresentationController {
            if #available(iOS 16.0, *) {
                let low = UISheetPresentationController.Detent.custom(identifier: .init("low")) { _ in customHeight }
                var detents: [UISheetPresentationController.Detent] = [low]
                var selectedDetent = low.identifier
                var largestUndimmed = low.identifier

                // Add a mid-level detent (e.g. 700) only if custom height is significantly smaller
                if customHeight < 600 {
                    let mid = UISheetPresentationController.Detent.custom(identifier: .init("mid")) { _ in 700 }
                    detents.append(mid)
                    largestUndimmed = mid.identifier
                }

                // Always include full-screen detent
                let full = UISheetPresentationController.Detent.large()
                detents.append(full)

                sheet.detents = detents
                sheet.selectedDetentIdentifier = selectedDetent
                sheet.largestUndimmedDetentIdentifier = largestUndimmed
                sheet.prefersGrabberVisible = prefersGrabberVisible
                sheet.prefersScrollingExpandsWhenScrolledToEdge = true
                sheet.prefersEdgeAttachedInCompactHeight = false
                sheet.widthFollowsPreferredContentSizeWhenEdgeAttached = true

                delegate.registerSheet(sheet)
            } else {
                sheet.detents = [.medium(), .large()]
            }
        }

        nav.presentationController?.delegate = delegate
        objc_setAssociatedObject(nav, "modalDelegate", delegate, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

        if hapticMoments.contains(.willPresent) {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }

        presenter.present(nav, animated: true) {
            if hapticMoments.contains(.didPresent) {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
        }
    }
    
    /// Presents a full-screen modal with swipe-to-dismiss enabled.
    static func presentFullScreenModal<T: UIViewController>(
        _ viewControllerType: T.Type,
        from presenter: UIViewController,
        storyboardId: String? = nil,
        storyboardName: String = "Main",
        hapticMoments: [HapticMoment] = [],
        willDismiss: (() -> Void)? = nil,
        didDismiss: (() -> Void)? = nil
    ) {
        let id = storyboardId ?? String(describing: T.self)
        let storyboard = UIStoryboard(name: storyboardName, bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: id) as! T
        let nav = UINavigationController(rootViewController: viewController)
        nav.modalPresentationStyle = .pageSheet

        let delegate = ModalPresenter()
        delegate.hapticMoments = hapticMoments
        delegate.willDismiss = willDismiss
        delegate.didDismiss = didDismiss

        nav.presentationController?.delegate = delegate
        objc_setAssociatedObject(nav, "modalDelegate", delegate, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

        if hapticMoments.contains(.willPresent) {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }

        presenter.present(nav, animated: true) {
            if hapticMoments.contains(.didPresent) {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
        }
    }
    
    /// Presents a full-page modal using `.large()` detent, allowing swipe-to-dismiss.
    static func presentFullPageModal<T: UIViewController>(
        _ viewControllerType: T.Type,
        from presenter: UIViewController,
        storyboardId: String? = nil,
        storyboardName: String = "Main",
        prefersGrabberVisible: Bool = true,
        hapticMoments: [HapticMoment] = [],
        willDismiss: (() -> Void)? = nil,
        didDismiss: (() -> Void)? = nil
    ) {
        let id = storyboardId ?? String(describing: T.self)
        let storyboard = UIStoryboard(name: storyboardName, bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: id) as! T
        let nav = UINavigationController(rootViewController: viewController)
        nav.modalPresentationStyle = .pageSheet

        let delegate = ModalPresenter()
        delegate.hapticMoments = hapticMoments
        delegate.willDismiss = willDismiss
        delegate.didDismiss = didDismiss
        delegate.allowedDismissDetents = [.large]

        if let sheet = nav.sheetPresentationController {
            if #available(iOS 16.0, *) {
                // Use only the system `.large()` detent to enable swipe-to-dismiss
                sheet.detents = [.large()]
                sheet.selectedDetentIdentifier = .large
                sheet.prefersGrabberVisible = prefersGrabberVisible
                sheet.prefersScrollingExpandsWhenScrolledToEdge = true
                sheet.prefersEdgeAttachedInCompactHeight = false
                sheet.widthFollowsPreferredContentSizeWhenEdgeAttached = true

                delegate.registerSheet(sheet)
            } else {
                sheet.detents = [.large()]
            }
        }

        nav.presentationController?.delegate = delegate
        objc_setAssociatedObject(nav, "modalDelegate", delegate, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

        if hapticMoments.contains(.willPresent) {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }

        presenter.present(nav, animated: true) {
            if hapticMoments.contains(.didPresent) {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
        }
    }
}

extension UIStoryboard {
    static func instantiate<T: UIViewController>(_ type: T.Type, from name: String = "Main") -> T {
        let storyboard = UIStoryboard(name: name, bundle: nil)
        return storyboard.instantiateViewController(withIdentifier: String(describing: T.self)) as! T
    }
}
