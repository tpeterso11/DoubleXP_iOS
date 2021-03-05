//
//  SelfSizingTableView.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 3/2/21.
//  Copyright © 2021 Peterson, Toussaint. All rights reserved.
//
import UIKit

class SelfSizingTableView: UITableView {
  var maxHeight: CGFloat = UIScreen.main.bounds.size.height
  
  override func reloadData() {
    super.reloadData()
    self.invalidateIntrinsicContentSize()
    //heightConstraint.constant = tableView.contentSize.height
//    UIView.animate(withDuration: 0.2) {
//      self.layoutIfNeeded()
//    }
    
    self.layoutIfNeeded()
  }
  
  override var intrinsicContentSize: CGSize {
    let height = min(contentSize.height, maxHeight)
    return CGSize(width: contentSize.width, height: height)
  }
}
