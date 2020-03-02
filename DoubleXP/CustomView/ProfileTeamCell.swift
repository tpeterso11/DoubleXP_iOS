//
//  ProfileTeamCell.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 3/1/20.
//  Copyright © 2020 Peterson, Toussaint. All rights reserved.
//
import UIKit
import FoldingCell

class ProfileTeamCell: FoldingCell {

    
    override func animationDuration(_ itemIndex: NSInteger, type _: FoldingCell.AnimationType) -> TimeInterval {
        let durations = [0.15, 0.25, 0.15]
        return durations[itemIndex]
    }
}
