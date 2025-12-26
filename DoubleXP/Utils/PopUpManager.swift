//
//  PopUpManager.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 6/28/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//

import SwiftEntryKit
import UIKit

enum PopupType {
    case normal
    case warning
    case error
}

enum PopupButtonStyle { case primary, secondary }

enum PopupHaptic { case none, success, warning, error }

struct PopupAction {
    let title: String
    let style: PopupButtonStyle
    let handler: () -> Void
}

// MARK: - Styles

enum PopupVisualStyle {
    case normal
    case warning
    case error
    case custom(background: UIColor, primary: UIColor, secondary: UIColor)

    var backgroundColor: UIColor {
        switch self {
        case .normal:  return UIColor(white: 0.12, alpha: 1)
        case .warning: return UIColor(white: 0.12, alpha: 1)
        case .error:   return UIColor(white: 0.12, alpha: 1)
        case .custom(let bg, _, _): return bg
        }
    }

    var primaryColor: UIColor {
        switch self {
        case .normal:  return UIColor(named: "gold") ?? .systemYellow
        case .warning: return .systemOrange
        case .error:   return .systemRed
        case .custom(_, let p, _): return p
        }
    }

    var secondaryColor: UIColor {
        switch self {
        case .normal, .warning, .error: return UIColor(white: 0.22, alpha: 1)
        case .custom(_, _, let s):      return s
        }
    }
}

// MARK: - Content & Actions

struct PopupContent {
    var title: String?
    var message: String?
    /// Provide either `image` OR `imageURL` (if both set, `image` wins)
    var image: UIImage?
    var imageURL: URL?

    init(title: String? = nil,
         message: String? = nil,
         image: UIImage? = nil,
         imageURL: URL? = nil) {
        self.title = title
        self.message = message
        self.image = image
        self.imageURL = imageURL
    }
}

struct PopupManager {

    static func show(
        title: String,
        message: String,
        okButtonText: String = "OK",
        cancelButtonText: String? = nil, // nil means don't show
        popupType: PopupType = .normal,
        okAction: @escaping () -> Void = {},
        cancelAction: @escaping () -> Void = {}
    ) {
        // MARK: - Haptic Feedback
        switch popupType {
        case .normal:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .warning:
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        case .error:
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }

        // MARK: - Entry Attributes
        var attributes = EKAttributes.centerFloat
        attributes.entryBackground = .color(color: EKColor(.white))
        attributes.shadow = .active(with: .init(color: .black, opacity: 0.3, radius: 8))
        attributes.roundCorners = .all(radius: 16)
        attributes.screenBackground = .color(color: EKColor(UIColor.black.withAlphaComponent(0.3)))
        attributes.entryInteraction = .absorbTouches
        attributes.screenInteraction = .dismiss
        attributes.displayDuration = .infinity

        // MARK: - View
        let popup = PopupView(
            title: title,
            message: message,
            okText: okButtonText,
            cancelText: cancelButtonText,
            popupType: popupType,
            okHandler: {
                SwiftEntryKit.dismiss()
                okAction()
            },
            cancelHandler: {
                SwiftEntryKit.dismiss()
                cancelAction()
            }
        )

        SwiftEntryKit.display(entry: popup, using: attributes)
    }
    
    /// Shows a specialized pop-up card for a game with a "pop" animation.
    static func showGameCard(
        game: GamerConnectGame,
        onSeeMore: @escaping () -> Void
    ) {
        // 1. Create content & actions from the game object
        let message = game.gameDescription.isEmpty ? (game.hook ?? "No description available.") : game.gameDescription
        let content = PopupContent(
            title: game.gameName,
            message: message,
            imageURL: URL(string: game.imageUrl ?? "")
        )
        let seeMoreAction = PopupAction(title: "See More", style: .primary) {
            SwiftEntryKit.dismiss()
            onSeeMore()
        }
        let dismissAction = PopupAction(title: "Dismiss", style: .secondary) {
            SwiftEntryKit.dismiss()
        }
        let actions = [seeMoreAction, dismissAction]

        // 2. Configure attributes specifically for the pop animation
        var attributes = EKAttributes.centerFloat
        attributes.displayDuration = .infinity
        attributes.shadow = .active(with: .init(color: .black, opacity: 0.35, radius: 12))
        attributes.roundCorners = .all(radius: 16)
        attributes.entryBackground = .color(color: EKColor(PopupVisualStyle.normal.backgroundColor))
        attributes.screenBackground = .color(color: EKColor(UIColor.black.withAlphaComponent(0.45)))
        attributes.entryInteraction = .absorbTouches
        attributes.screenInteraction = .dismiss
        attributes.positionConstraints.size = .init(width: .offset(value: 24), height: .intrinsic)
        
        attributes.entranceAnimation = .init(
            scale: .init(from: 0.8, to: 1, duration: 0.4, spring: .init(damping: 0.8, initialVelocity: 0)),
            fade: .init(from: 0, to: 1, duration: 0.3)
        )
        attributes.exitAnimation = .init(
            scale: .init(from: 1, to: 0.8, duration: 0.3),
            fade: .init(from: 1, to: 0, duration: 0.2)
        )
        attributes.popBehavior = .animated(animation: .init(
            translate: .init(duration: 0.2),
            scale: .init(from: 1, to: 0.8, duration: 0.4, spring: .init(damping: 0.7, initialVelocity: 0))
        ))
        
        // 3. Play haptic and display
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        let view = CardPopupView(content: content, actions: actions, style: .normal)
        SwiftEntryKit.display(entry: view, using: attributes)
    }
    
    static func showUnsavedProfileChangesPopup(
            onSaveAndExit: @escaping () -> Void,
            onDiscard: @escaping () -> Void,
            onCancel: @escaping () -> Void
        ) {
            let content = PopupContent(
                title: "Unsaved Changes",
                message: "You’ve made changes to your profile. What would you like to do?"
            )

            let saveAction = PopupAction(title: "Save & Exit", style: .primary) {
                SwiftEntryKit.dismiss()
                onSaveAndExit()
            }

            let discardAction = PopupAction(title: "Discard Changes", style: .secondary) {
                SwiftEntryKit.dismiss()
                onDiscard()
            }

            let keepEditingAction = PopupAction(title: "Keep Editing", style: .secondary) {
                SwiftEntryKit.dismiss()
                onCancel()
            }

            let actions = [saveAction, keepEditingAction, discardAction]

            showCard(
                content: content,
                actions: actions,
                style: .warning,
                haptic: .warning
            )
        }

    /// Shows a generic card with the default slide/float animation.
    static func showCard(
        content: PopupContent,
        actions: [PopupAction] = [],
        style: PopupVisualStyle = .normal,
        haptic: PopupHaptic = .success
    ) {
        // Haptics
        switch haptic {
        case .success: UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .warning: UINotificationFeedbackGenerator().notificationOccurred(.warning)
        case .error:   UINotificationFeedbackGenerator().notificationOccurred(.error)
        case .none:    break
        }

        // SwiftEntryKit attributes (uses the default centerFloat animation)
        var attributes = EKAttributes.centerFloat
        attributes.displayDuration = .infinity
        attributes.shadow = .active(with: .init(color: .black, opacity: 0.35, radius: 12))
        attributes.roundCorners = .all(radius: 16)
        attributes.entryBackground = .color(color: EKColor(style.backgroundColor))
        attributes.screenBackground = .color(color: EKColor(UIColor.black.withAlphaComponent(0.45)))
        attributes.entryInteraction = .absorbTouches
        attributes.screenInteraction = .dismiss
        attributes.positionConstraints.size = .init(width: .offset(value: 24), height: .intrinsic)
        
        // Build view
        let view = CardPopupView(content: content, actions: actions, style: style)
        SwiftEntryKit.display(entry: view, using: attributes)
    }
    
    // MARK: - View

    final class CardPopupView: UIView {
        private let imageView = UIImageView()
        private let titleLabel = UILabel()
        private let messageLabel = UILabel()
        private let buttonsStack = UIStackView()

        init(content: PopupContent,
             actions: [PopupAction],
             style: PopupVisualStyle = .normal) {
                super.init(frame: .zero)
                translatesAutoresizingMaskIntoConstraints = false
                layer.cornerRadius = 16
                clipsToBounds = true
                backgroundColor = style.backgroundColor

                // Header image
                imageView.translatesAutoresizingMaskIntoConstraints = false
                imageView.contentMode = .scaleAspectFill
                imageView.clipsToBounds = true
                imageView.backgroundColor = UIColor(white: 0.2, alpha: 1)
                imageView.heightAnchor.constraint(equalToConstant: 220).isActive = true
                if let img = content.image { imageView.image = img }
                else if let url = content.imageURL {
                    // Assuming you have an ImageLoader class as referenced in your original code
                    imageView.loadImage(from: url)
                }

                // Title / Message
                titleLabel.translatesAutoresizingMaskIntoConstraints = false
                titleLabel.text = content.title
                titleLabel.numberOfLines = 0
                titleLabel.textAlignment = .center
                titleLabel.textColor = .white
                titleLabel.font = UIFont(name: "Moon-Bold", size: 20) ?? .boldSystemFont(ofSize: 20)

                messageLabel.translatesAutoresizingMaskIntoConstraints = false
                messageLabel.text = content.message
                messageLabel.numberOfLines = 0
                messageLabel.textAlignment = .center
                messageLabel.textColor = UIColor(white: 0.85, alpha: 1)
                messageLabel.font = UIFont(name: "Moon-Light", size: 15) ?? .systemFont(ofSize: 15)

                let textStack = UIStackView(arrangedSubviews: [titleLabel, messageLabel])
                textStack.axis = .vertical
                textStack.spacing = 12
                textStack.isLayoutMarginsRelativeArrangement = true
                textStack.layoutMargins = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
                textStack.translatesAutoresizingMaskIntoConstraints = false

                // Scroll container for text
                let scroll = UIScrollView()
                scroll.translatesAutoresizingMaskIntoConstraints = false
                scroll.addSubview(textStack)
                NSLayoutConstraint.activate([
                    textStack.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor),
                    textStack.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor),
                    textStack.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor),
                    textStack.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor),
                    textStack.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor)
                ])

                // Buttons
                buttonsStack.axis = .vertical
                buttonsStack.spacing = 10
                buttonsStack.isLayoutMarginsRelativeArrangement = true
                buttonsStack.layoutMargins = UIEdgeInsets(top: 0, left: 16, bottom: 16, right: 16)
                buttonsStack.translatesAutoresizingMaskIntoConstraints = false

                actions.forEach { action in
                    buttonsStack.addArrangedSubview(makeButton(for: action, using: style))
                }

                // Add subviews
                addSubview(imageView)
                addSubview(scroll)
                addSubview(buttonsStack)

                // ---- FIXES: keep text area visible; don’t let buttons crush it ----
                scroll.heightAnchor.constraint(greaterThanOrEqualToConstant: 120).isActive = true
                buttonsStack.setContentCompressionResistancePriority(.required, for: .vertical)
                buttonsStack.setContentHuggingPriority(.required, for: .vertical)
                scroll.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
                // ------------------------------------------------------------------

                NSLayoutConstraint.activate([
                    imageView.topAnchor.constraint(equalTo: topAnchor),
                    imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
                    imageView.trailingAnchor.constraint(equalTo: trailingAnchor),

                    scroll.topAnchor.constraint(equalTo: imageView.bottomAnchor),
                    scroll.leadingAnchor.constraint(equalTo: leadingAnchor),
                    scroll.trailingAnchor.constraint(equalTo: trailingAnchor),

                    buttonsStack.topAnchor.constraint(equalTo: scroll.bottomAnchor, constant: 12),
                    buttonsStack.leadingAnchor.constraint(equalTo: leadingAnchor),
                    buttonsStack.trailingAnchor.constraint(equalTo: trailingAnchor),
                    buttonsStack.bottomAnchor.constraint(equalTo: bottomAnchor)
                ])
            }

            private func makeButton(for action: PopupAction, using style: PopupVisualStyle) -> UIButton {
                let b = UIButton(type: .system)
                b.setTitle(action.title.uppercased(), for: .normal)
                b.titleLabel?.font = UIFont(name: "Moon-Bold", size: 16) ?? .boldSystemFont(ofSize: 16)
                b.heightAnchor.constraint(equalToConstant: 46).isActive = true
                b.layer.cornerRadius = 10
                switch action.style {
                case .primary:
                    b.backgroundColor = style.primaryColor; b.setTitleColor(.black, for: .normal)
                case .secondary:
                    b.backgroundColor = style.secondaryColor; b.setTitleColor(.white, for: .normal)
                }
                b.addAction(UIAction { _ in action.handler() }, for: .touchUpInside)
                return b
            }

        required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    }

    /// Convenience: “OK” only
    static func alert(
        title: String,
        message: String,
        image: UIImage? = nil,
        imageURL: URL? = nil,
        okTitle: String = "OK",
        onOK: @escaping () -> Void = {}
    ) {
        let content = PopupContent(title: title, message: message, image: image, imageURL: imageURL)
        showCard(content: content, actions: [PopupAction(title: okTitle, style: .primary, handler: onOK)])
    }
}

class PopupView: UIView {

    init(
        title: String,
        message: String,
        okText: String,
        cancelText: String? = nil,
        popupType: PopupType = .normal,
        okHandler: @escaping () -> Void,
        cancelHandler: @escaping () -> Void
    ) {
        super.init(frame: .zero)

        // MARK: - Visuals
        backgroundColor = .white
        layer.cornerRadius = 16
        clipsToBounds = true
        if popupType == .error {
            layer.borderWidth = 2
            layer.borderColor = UIColor.red.cgColor
        }

        // MARK: - Title
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont(name: "Moon-Bold", size: 18)
        titleLabel.textColor = popupType == .error ? .red : .black
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0

        // MARK: - Message
        let messageLabel = UILabel()
        messageLabel.text = message
        messageLabel.font = UIFont(name: "Moon-Light", size: 14)
        messageLabel.textColor = .darkGray
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0

        // MARK: - Buttons
        let okButton = UIButton(type: .system)
        okButton.setTitle(okText, for: .normal)
        okButton.setTitleColor(.white, for: .normal)
        okButton.titleLabel?.font = UIFont(name: "Moon-Bold", size: 16)
        okButton.backgroundColor = .systemBlue
        okButton.layer.cornerRadius = 8
        okButton.addAction(UIAction { _ in okHandler() }, for: .touchUpInside)

        let buttonStack = UIStackView()
        buttonStack.axis = .vertical
        buttonStack.spacing = 8

        if let cancelText = cancelText {
            let cancelButton = UIButton(type: .system)
            cancelButton.setTitle(cancelText, for: .normal)
            cancelButton.setTitleColor(.systemGray, for: .normal)
            cancelButton.titleLabel?.font = UIFont(name: "Moon-Light", size: 16)
            cancelButton.backgroundColor = .clear
            cancelButton.addAction(UIAction { _ in cancelHandler() }, for: .touchUpInside)
            buttonStack.addArrangedSubview(cancelButton)
        }

        buttonStack.addArrangedSubview(okButton)

        // MARK: - Layout
        let stack = UIStackView(arrangedSubviews: [titleLabel, messageLabel, buttonStack])
        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false

        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -20)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

struct TooltipHelper {
    static func showTooltip(
        title: String,
        message: String,
        image: UIImage,
        imageOnRight: Bool = false,
        duration: TimeInterval = 5
    ) {
        var attributes = EKAttributes.bottomFloat
        attributes.displayDuration = duration
        attributes.entryBackground = .color(color: .white)
        attributes.screenBackground = .color(color: .clear)
        attributes.shadow = .active(with: .init(color: .black, opacity: 0.1, radius: 6))
        attributes.roundCorners = .all(radius: 18)
        attributes.entryInteraction = .dismiss
        attributes.screenInteraction = .dismiss
        attributes.positionConstraints.verticalOffset = 12
        attributes.positionConstraints.safeArea = .overridden
        attributes.positionConstraints.size = .init(width: .offset(value: 20), height: .intrinsic)

        // MARK: Manual custom view
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.backgroundColor = .white
        container.layer.cornerRadius = 18
        container.clipsToBounds = true

        // ImageView
        let imageView = UIImageView(image: image)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.widthAnchor.constraint(equalToConstant: 40).isActive = true
        imageView.heightAnchor.constraint(equalToConstant: 40).isActive = true

        // Labels
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = title
        titleLabel.font = UIFont.boldSystemFont(ofSize: 16)
        titleLabel.textColor = .black
        titleLabel.numberOfLines = 0

        let descriptionLabel = UILabel()
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.text = message
        descriptionLabel.font = UIFont.systemFont(ofSize: 14)
        descriptionLabel.textColor = .darkGray
        descriptionLabel.numberOfLines = 0

        // Label stack (vertical)
        let labelStack = UIStackView(arrangedSubviews: [titleLabel, descriptionLabel])
        labelStack.axis = .vertical
        labelStack.spacing = 4

        // Main horizontal stack
        let rowStack = UIStackView()
        rowStack.translatesAutoresizingMaskIntoConstraints = false
        rowStack.axis = .horizontal
        rowStack.spacing = 12
        rowStack.alignment = .center

        if imageOnRight {
            rowStack.addArrangedSubview(labelStack)
            rowStack.addArrangedSubview(imageView)
        } else {
            rowStack.addArrangedSubview(imageView)
            rowStack.addArrangedSubview(labelStack)
        }

        container.addSubview(rowStack)
        NSLayoutConstraint.activate([
            rowStack.topAnchor.constraint(equalTo: container.topAnchor, constant: 12),
            rowStack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            rowStack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            rowStack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -12)
        ])

        SwiftEntryKit.display(entry: container, using: attributes)
    }
}

class GameDetailPresentAnimator: NSObject, UIViewControllerAnimatedTransitioning {

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        // We'll use a slightly longer duration to make the overshoot effect feel smooth.
        return 0.5
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let toViewController = transitionContext.viewController(forKey: .to) else { return }
        
        let containerView = transitionContext.containerView
        let finalFrame = transitionContext.finalFrame(for: toViewController)
        let toView = toViewController.view!
        
        toView.frame = finalFrame
        toView.center = containerView.center
        containerView.addSubview(toView)

        // Start with the view controller scaled down and transparent, just like before.
        toView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        toView.alpha = 0.0
        
        // --- NEW: Use a keyframe animation for the overshoot effect ---
        UIView.animateKeyframes(withDuration: transitionDuration(using: transitionContext),
                                delay: 0,
                                options: .calculationModeCubic,
                                animations: {
            
            // Keyframe 1: Animate the view to be slightly LARGER than its final size and fade it in.
            // This is the "grow bigger" step.
            UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.75) {
                toView.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
                toView.alpha = 1.0
            }
            
            // Keyframe 2: Animate the view back down to its final, normal size.
            // This makes it "settle" into place.
            UIView.addKeyframe(withRelativeStartTime: 0.75, relativeDuration: 0.25) {
                toView.transform = .identity
            }
            
        }, completion: { _ in
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        })
    }
}


// Announcement Info Card Example
// this is the card that shows if a user taps "More Info" on he Announcement Card in the feed.

/*PopupManager.showCard(
    content: .init(
        title: "Patch 1.2.3",
        message: """
- Weapon balancing
- New map: Neon Docks
- Stability & crash fixes
""",
        imageURL: URL(string: "https://www.cnet.com/a/img/resize/c551b62eb45cdab9f07a09d06be39cb674b0256a/hub/2024/11/07/0e371edc-6276-4063-9869-ff85b2ac81a1/bo6-season-01-announcement-001.jpg?auto=webp&fit=crop&height=675&width=1200")
    ),
    actions: [
        PopupAction(title: "More Info", style: .primary) {
            // push detail screen
        },
        PopupAction(title: "Dismiss", style: .secondary) {
            // remember dismissal if needed
        }
    ],
    style: .normal,      // or .warning / .error / .custom(...)
    haptic: .success
)
*/
