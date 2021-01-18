//
//  AdCell.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 11/17/20.
//  Copyright © 2020 Peterson, Toussaint. All rights reserved.
//

import Foundation
import UIKit
import GoogleMobileAds

class AdCell: UICollectionViewCell, GADBannerViewDelegate {
    @IBOutlet weak var banner: GADBannerView!
    //var bannerView: GADBannerView!
    
    func setAd(landingController: LandingActivity){
        //bannerView = GADBannerView(adSize: kGADAdSizeBanner)
        //addBannerViewToView(bannerView)
        
        banner.adUnitID = "ca-app-pub-4984936537203253/1233642732"
        #if DEBUG
            banner.adUnitID = "ca-app-pub-3940256099942544/2934735716"
        #endif
        
        banner.rootViewController = landingController
        banner.delegate = self
        banner.load(GADRequest())
    }
    
    func addBannerViewToView(_ bannerView: GADBannerView) {
        bannerView.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(bannerView)
        self.contentView.addConstraints(
          [NSLayoutConstraint(item: bannerView,
                              attribute: .bottom,
                              relatedBy: .equal,
                              toItem: self.contentView,
                              attribute: .top,
                              multiplier: 1,
                              constant: 0),
           NSLayoutConstraint(item: bannerView,
                              attribute: .centerX,
                              relatedBy: .equal,
                              toItem: self.contentView,
                              attribute: .centerX,
                              multiplier: 1,
                              constant: 0)
          ])
       }
    
    
    /// Tells the delegate an ad request loaded an ad.
    func adViewDidReceiveAd(_ bannerView: GADBannerView) {
      print("adViewDidReceiveAd")
    }

    /// Tells the delegate an ad request failed.
    func adView(_ bannerView: GADBannerView,
        didFailToReceiveAdWithError error: GADRequestError) {
      print("adView:didFailToReceiveAdWithError: \(error.localizedDescription)")
    }

    /// Tells the delegate that a full-screen view will be presented in response
    /// to the user clicking on an ad.
    func adViewWillPresentScreen(_ bannerView: GADBannerView) {
      print("adViewWillPresentScreen")
    }

    /// Tells the delegate that the full-screen view will be dismissed.
    func adViewWillDismissScreen(_ bannerView: GADBannerView) {
      print("adViewWillDismissScreen")
    }

    /// Tells the delegate that the full-screen view has been dismissed.
    func adViewDidDismissScreen(_ bannerView: GADBannerView) {
      print("adViewDidDismissScreen")
    }

    /// Tells the delegate that a user click will open another app (such as
    /// the App Store), backgrounding the current app.
    func adViewWillLeaveApplication(_ bannerView: GADBannerView) {
      print("adViewWillLeaveApplication")
    }
}
