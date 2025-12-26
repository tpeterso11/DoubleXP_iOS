//
//  LottieView.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 6/22/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//

import UIKit
import Lottie

class LottieView: UIView {

    private var animationView: LottieAnimationView?

    @IBInspectable var animationName: String = "" {
        didSet {
            setupAnimation()
        }
    }

    @IBInspectable var shouldLoop: Bool = true {
        didSet {
            animationView?.loopMode = shouldLoop ? .loop : .playOnce
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        setupAnimation()
    }

    private func setupAnimation() {
        animationView?.removeFromSuperview()

        guard !animationName.isEmpty else { return }

        guard let animation = LottieAnimation.named(animationName) else {
            print("❌ Could not find animation named \(animationName)")
            return
        }

        let view = LottieAnimationView(animation: animation)
        view.loopMode = shouldLoop ? .loop : .playOnce
        view.contentMode = .scaleAspectFit
        view.translatesAutoresizingMaskIntoConstraints = false

        addSubview(view)

        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: topAnchor),
            view.bottomAnchor.constraint(equalTo: bottomAnchor),
            view.leadingAnchor.constraint(equalTo: leadingAnchor),
            view.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])

        animationView = view
    }

    // MARK: - Public controls

    func play() {
        animationView?.play()
    }

    func pause() {
        animationView?.pause()
    }

    func resume() {
        animationView?.play()
    }

    func stop() {
        animationView?.stop()
    }

    func playOnce(completion: (() -> Void)? = nil) {
        animationView?.loopMode = .playOnce
        animationView?.play { _ in
            completion?()
        }
    }

    func play(fromProgress: AnimationProgressTime, toProgress: AnimationProgressTime, loop: Bool = false) {
        animationView?.loopMode = loop ? .loop : .playOnce
        animationView?.play(fromProgress: fromProgress, toProgress: toProgress)
    }

    func setProgress(to progress: AnimationProgressTime) {
        animationView?.currentProgress = progress
    }

    func setSpeed(to speed: CGFloat) {
        animationView?.animationSpeed = speed
    }
}
