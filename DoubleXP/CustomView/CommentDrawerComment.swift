//
//  CommentDrawerComment.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 4/4/23.
//  Copyright © 2023 Peterson, Toussaint. All rights reserved.
//

import Foundation
import UIKit

class CommentDrawerComment: UITableViewCell {
    
    @IBOutlet weak var downVoteCount: UILabel!
    @IBOutlet weak var downVote: UIImageView!
    @IBOutlet weak var upVote: UIImageView!
    @IBOutlet weak var upVoteCount: UILabel!
    @IBOutlet weak var flagIcon: UIImageView!
    @IBOutlet weak var timeSince: UILabel!
    @IBOutlet weak var commentText: UITextView!
    @IBOutlet weak var commentGamer: UILabel!
}
