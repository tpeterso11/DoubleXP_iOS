//
//  ArticleFrag.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 2/26/20.
//  Copyright © 2020 Peterson, Toussaint. All rights reserved.
//

import Foundation
import UIKit
import Hero

class ArticleFrag: UIViewController{
    var panGR: UIPanGestureRecognizer!
    var article: NewsObject?
    @IBOutlet weak var image: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.image.heroID = "image"
        self.image.heroModifiers = [.zPosition(2)]
        //Hero cocopods
        //first, register PanGestureRecognizer in receiving VC
        panGR = UIPanGestureRecognizer(target: self, action: #selector(handlePan(gestureRecognizer:)))
        view.addGestureRecognizer(panGR)
        
    }
    
    @objc func handlePan(gestureRecognizer:UIPanGestureRecognizer) {
        let translation = panGR.translation(in: nil)
        let progress = translation.y / 2 / view.bounds.height

      switch panGR.state {
      case .began:
        // begin the transition as normal
        dismiss(animated: true, completion: nil)
      case .changed:
        // calculate the progress based on how far the user moved
        let translation = panGR.translation(in: nil)
        let progress = translation.y / 2 / view.bounds.height
        Hero.shared.update(progress)
        
        Hero.shared.apply(modifiers: [.position(CGPoint(x:image.center.x, y:translation.y + image.center.y))], to: image)
      default:
        // end the transition when user ended their touch
        if progress + panGR.velocity(in: nil).y / view.bounds.height > 0.3 {
          Hero.shared.finish()
        } else {
          Hero.shared.cancel()
        }
      }
    }
    
}
