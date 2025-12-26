//
//  CommunityHostingController.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 10/17/25.
//  Copyright © 2025 Peterson, Toussaint. All rights reserved.
//
import SwiftUI

final class HeroAnimatorBridge: ObservableObject {
    weak var heroImageView: UIImageView?
}

class HeroHostingController<Content: View>: UIHostingController<Content>, PushHeroPresentedDelegate {
    
    let animatorBridge: HeroAnimatorBridge
    
    init(rootView: Content, bridge: HeroAnimatorBridge) {
        self.animatorBridge = bridge
        super.init(rootView: rootView)
        self.view.backgroundColor = .clear
    }
    
    @MainActor @objc required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - PushHeroPresentedDelegate
    
    func pushHero_destinationImageView(for transition: CommunityPushHeroAnimator) -> UIImageView? {
        return animatorBridge.heroImageView
    }
    
    func pushHero_topViews(for transition: CommunityPushHeroAnimator) -> [UIView] {
        return []
    }
    
    func pushHero_prepareForMeasurement() {
        view.setNeedsLayout()
        view.layoutIfNeeded()
    }
}

extension HeroHostingController {
    static func create<V: View>(
        startingImage: UIImage? = nil,
        @ViewBuilder content: (HeroAnimatorBridge, UIImage?) -> V
    ) -> HeroHostingController<V> {
        let bridge = HeroAnimatorBridge()
        let view = content(bridge, startingImage)
        return HeroHostingController<V>(rootView: view, bridge: bridge)
    }
}
