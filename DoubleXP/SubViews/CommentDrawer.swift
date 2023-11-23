//
//  CommentDrawer.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 3/24/23.
//  Copyright © 2023 Peterson, Toussaint. All rights reserved.
//

import Foundation
import UIKit
import Firebase
import Lottie

class CommentDrawer: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextViewDelegate, VideoHelperCallbacks {
    @IBOutlet weak var commentCount: UILabel!
    @IBOutlet weak var commentTable: UITableView!
    @IBOutlet weak var commentTVCover: UIView!
    @IBOutlet weak var commentTV: UITextView!
    @IBOutlet weak var postButton: UIButton!
    @IBOutlet weak var commentLoadingBlur: UIVisualEffectView!
    @IBOutlet weak var loadingAnimation: LottieAnimationView!
    @IBOutlet weak var commentBlur: UIVisualEffectView!
    @IBOutlet weak var upVoteCount: UILabel!
    @IBOutlet weak var downVoteCount: UILabel!
    @IBOutlet weak var upVoteButton: UIImageView!
    @IBOutlet weak var downVoteButton: UIImageView!
    @IBOutlet weak var commentCompleteAnimation: LottieAnimationView!
    var upVotes = [String]()
    var downVotes = [String]()
    var commentPayload = [VideoCommentObject]()
    var currentVideo: PostObject?
    var payload = [Any]()
    var dataSet = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if(currentVideo == nil){ return }
        if(self.commentPayload.count == 0){
            self.commentCount.text = "no comments"
        } else {
            if(self.commentPayload.count < 1000){
                self.commentCount.text = String(format: "%02d", commentPayload.count) + " comments"
            } else {
                self.commentCount.text = commentPayload.count.roundedWithAbbreviations + " comments"
            }
        }
        self.postButton.alpha = 0.3
        self.postButton.isUserInteractionEnabled = false
        
        let postComment = UITapGestureRecognizer(target: self, action: #selector(self.postComment))
        self.postButton.isUserInteractionEnabled = false
        self.postButton.addGestureRecognizer(postComment)
        
        let commentTap = UITapGestureRecognizer(target: self, action: #selector(self.hideCommentCover))
        self.commentTVCover.isUserInteractionEnabled = true
        self.commentTVCover.addGestureRecognizer(commentTap)
        
        self.commentTV.returnKeyType = UIReturnKeyType.done
        self.commentTV.delegate = self
        
        let upVoteTap = VideoUpVoteGesture(target: self, action: #selector(upVotePost))
        upVoteTap.postId = currentVideo!.postId
        self.upVoteButton.isUserInteractionEnabled = true
        self.upVoteButton.addGestureRecognizer(upVoteTap)
        
        let downVoteTap = VideoUpVoteGesture(target: self, action: #selector(downVotePost))
        downVoteTap.postId = currentVideo!.postId
        self.downVoteButton.isUserInteractionEnabled = true
        self.downVoteButton.addGestureRecognizer(downVoteTap)
        
        VideoHelper().getCurrentVideoComments(currentPostId: currentVideo!.postId, videoOwnerUid: currentVideo!.videoOwnerUid, videoHelperCallback: self)
    }
    
    func getCommentsSuccessful(comments: [VideoCommentObject], upVotes: [String], downVotes: [String]){
        commentPayload.append(contentsOf: comments)
        self.commentCount.text = String(commentPayload.count) + " comments"
        
        self.upVotes = upVotes
        self.downVotes = downVotes
        self.upVoteCount.text =  String(format: "%02d", self.upVotes.count)
        self.downVoteCount.text =  String(format: "%02d", self.downVotes.count)
        
        let delegate = UIApplication.shared.delegate as! AppDelegate
        if(self.upVotes.contains(delegate.currentUser!.uId)){
            self.upVoteButton.tintColor = .systemGreen
            self.downVoteButton.tintColor = UIColor(named: "darkToWhite")
        } else if(self.downVotes.contains(delegate.currentUser!.uId)){
            self.upVoteButton.tintColor = UIColor(named: "darkToWhite")
            self.downVoteButton.tintColor = .systemRed
        } else {
            self.upVoteButton.tintColor = UIColor(named: "darkToWhite")
            self.downVoteButton.tintColor = UIColor(named: "darkToWhite")
        }
        setPayload()
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if(text == "\n") {
            textView.resignFirstResponder()
            
            if(textView.text.isEmpty){
                self.commentTVCover.alpha = 1
            } else {
                self.commentTVCover.alpha = 0
            }
            return false
        }
        return true
    }
    
    func textViewDidChange(_ textView: UITextView) {
        checkTextView()
    }
    
    @objc private func hideCommentCover() {
        UIView.animate(withDuration: 0.5, animations: {
            self.commentTVCover.alpha = 0
        }, completion: { (finished: Bool) in
            self.commentTV.becomeFirstResponder()
        })
    }
    
    @objc private func checkTextView(){
        if(self.commentTV.text.isEmpty){
            self.commentTVCover.alpha = 1
            self.postButton.alpha = 0.3
            self.commentTVCover.isUserInteractionEnabled = true
            self.postButton.isUserInteractionEnabled = false
            self.postButton.backgroundColor = .clear
            self.postButton.setTitleColor(UIColor(named: "darkToWhite"), for: .normal)
            self.postButton.borderColor = UIColor(named: "darkToWhite")
        } else {
            self.commentTVCover.alpha = 0
            self.commentTVCover.isUserInteractionEnabled = false
            self.postButton.alpha = 1
            self.postButton.setTitleColor(UIColor(named: "stayWhite"), for: .normal)
            self.postButton.backgroundColor = UIColor(named: "greenAlpha")
            self.postButton.isUserInteractionEnabled = true
            self.postButton.borderColor = .systemGreen
        }
    }
    
    @objc private func postComment(){
        if(!self.commentTV.text.isEmpty){
            self.commentLoadingBlur.isHidden = false
            self.loadingAnimation.loopMode = .loop
            self.loadingAnimation.play()
            UIView.animate(withDuration: 0.8, animations: {
                self.commentLoadingBlur.alpha = 1
            }, completion: { (finished: Bool) in
                let delegate = UIApplication.shared.delegate as! AppDelegate
                let videoHelper = VideoHelper()
                var videoGame: String? = nil
                if(!self.currentVideo!.game.isEmpty){
                    videoGame = self.currentVideo!.game
                }
                if(self.currentVideo!.publicPost == "true"){
                    videoHelper.addCommentPublicPost(postingUserId: delegate.currentUser!.uId, postingGamerTag: delegate.currentUser!.gamerTag, currentPostId: self.currentVideo!.postId, postVideoGame: videoGame, videoOwnerUid: self.currentVideo!.videoOwnerUid, commentText: self.commentTV.text, callback: self)
                } else {
                    videoHelper.addCommentPrivatePost(postingUserId: delegate.currentUser!.uId, postingGamerTag: delegate.currentUser!.gamerTag, currentPostId: self.currentVideo!.postId, postVideoGame: videoGame, videoOwnerUid: self.currentVideo!.videoOwnerUid, commentText: self.commentTV.text, commentId: nil, callback: self)
                }
            })
        }
    }
    
    func onCommentPosted(comments: [VideoCommentObject]){
        self.commentPayload = comments
        self.commentTV.text = ""
        self.checkTextView()
        if(self.commentPayload.count == 0){
            self.commentCount.text = "no comments"
        } else {
            if(self.commentPayload.count < 1000){
                self.commentCount.text = String(format: "%02d", commentPayload.count) + " comments"
            } else {
                self.commentCount.text = commentPayload.count.roundedWithAbbreviations + " comments"
            }
        }
        self.setPayload()
        
        self.commentCompleteAnimation.loopMode = .playOnce
        self.commentBlur.isHidden = false
        UIView.animate(withDuration: 0.8, delay: 0.5, options: [], animations: {
            self.commentBlur.alpha = 1
        }, completion: { (finished: Bool) in
            self.commentCompleteAnimation.play()
            UIView.animate(withDuration: 0.8, delay: 1.5, options: [], animations: {
                self.commentLoadingBlur.alpha = 0
                self.commentBlur.alpha = 0
            }, completion: { (finished: Bool) in
                self.commentBlur.isHidden = true
                self.commentLoadingBlur.isHidden = true
            })
        })
    }
    
    private func setPayload(){
        payload = [Any]()
        if(commentPayload.isEmpty){
            payload.append("empty")
        } else {
            let sortedPayload = commentPayload.sorted(by: {Int64($0.timeStamp)! < Int64($1.timeStamp)!} )
            payload.append(contentsOf: sortedPayload)
        }
        
        if(!dataSet){
            self.dataSet = true
            self.commentTable.delegate = self
            self.commentTable.dataSource = self
            self.commentTable.reloadData()
        } else {
            self.commentTable.reloadData()
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.payload.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let current = self.payload[indexPath.item]
        if(current is String){
            let cell = tableView.dequeueReusableCell(withIdentifier: "empty", for: indexPath) as! CommentDrawerEmptyCell
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "comment", for: indexPath) as! CommentDrawerComment
            let currentComment = current as! VideoCommentObject
            cell.commentGamer.text = currentComment.senderGamerTag
            cell.commentText.text = currentComment.message
            
            if(!currentComment.timeStamp.isEmpty){
                cell.timeSince.alpha = 1
                let milisecond = Int64(currentComment.timeStamp)
                if(milisecond != nil){
                    let dateVar = Date.init(timeIntervalSince1970: TimeInterval(milisecond!)/1000)
                    cell.timeSince.text = dateVar.timeAgoSinceDate()
                } else {
                    cell.timeSince.alpha = 0
                }
            } else {
                cell.timeSince.alpha = 0
            }
            
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let degrees: CGFloat = 180.0 //the value in degrees
            let radians: CGFloat = degrees * (.pi / 180)
            cell.downVote.transform = CGAffineTransform(rotationAngle: radians)
            cell.downVoteCount.text = String(currentComment.downVotes.count)
            cell.upVoteCount.text = String(currentComment.upvotes.count)
            
            if(currentComment.upvotes.contains(appDelegate.currentUser!.uId)){
                cell.upVote.tintColor = .systemGreen
                cell.upVote.isUserInteractionEnabled = false
            } else {
                cell.upVote.tintColor = UIColor(named: "darkToWhite")
                
                let upVoteTap = CommentVoteGesture(target: self, action: #selector(self.registerUpVote))
                upVoteTap.commentId = currentComment.commentId
                cell.upVote.isUserInteractionEnabled = true
                cell.upVote.addGestureRecognizer(upVoteTap)
            }
            
            if(currentComment.downVotes.contains(appDelegate.currentUser!.uId)){
                cell.downVote.tintColor = .systemRed
                cell.downVote.isUserInteractionEnabled = false
            } else {
                cell.downVote.tintColor = UIColor(named: "darkToWhite")
                
                let downVoteTap = CommentVoteGesture(target: self, action: #selector(self.registerDownVote))
                downVoteTap.commentId = currentComment.commentId
                cell.downVote.isUserInteractionEnabled = true
                cell.downVote.addGestureRecognizer(downVoteTap)
            }
            return cell
        }
    }
    
    @objc private func registerUpVote(sender: CommentVoteGesture){
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        for obj in self.commentPayload {
            if(obj.commentId == sender.commentId){
                var upVotes = obj.upvotes
                var downVotes = obj.downVotes
                if(downVotes.contains(appDelegate.currentUser!.uId)){
                    downVotes.remove(at: downVotes.firstIndex(of: appDelegate.currentUser!.uId)!)
                }
                if(!upVotes.contains(appDelegate.currentUser!.uId)){
                    upVotes.append(appDelegate.currentUser!.uId)
                }
                obj.downVotes = downVotes
                obj.upvotes = upVotes
                self.setPayload()
                VideoHelper().addUpVotePublicPostComment(currentUserUid: appDelegate.currentUser!.uId, videoOwnerUid: currentVideo!.videoOwnerUid, currentPostId: currentVideo!.postId, postVideoGame: currentVideo!.game, currentCommentId: sender.commentId)
                break
            }
        }
    }
    
    @objc func upVotePost(sender: VideoUpVoteGesture){
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        if(self.downVotes.contains(appDelegate.currentUser!.uId)){
            self.downVotes.remove(at: self.downVotes.firstIndex(of: appDelegate.currentUser!.uId)!)
        }
        self.upVotes.append(appDelegate.currentUser!.uId)
        self.upVoteCount.text =  String(format: "%02d", self.upVotes.count)
        self.downVoteCount.text =  String(format: "%02d", self.downVotes.count)
        self.upVoteButton.tintColor = .systemGreen
        self.downVoteButton.tintColor = UIColor(named: "darkToWhite")
        
        var currentGame: String? = nil
        if(!self.currentVideo!.game.isEmpty){
            currentGame = self.currentVideo!.game
        }
        VideoHelper().addUpVotePublicPost(currentUserUid: appDelegate.currentUser!.uId, videoOwnerUid: self.currentVideo!.videoOwnerUid, currentPostId: self.currentVideo!.postId, postVideoGame: currentGame)
    }
    
    @objc func downVotePost(sender: VideoUpVoteGesture){
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        if(self.upVotes.contains(appDelegate.currentUser!.uId)){
            self.upVotes.remove(at: self.upVotes.firstIndex(of: appDelegate.currentUser!.uId)!)
        }
        self.downVotes.append(appDelegate.currentUser!.uId)
        self.upVoteCount.text =  String(format: "%02d", self.upVotes.count)
        self.downVoteCount.text =  String(format: "%02d", self.downVotes.count)
        self.upVoteButton.tintColor = UIColor(named: "darkToWhite")
        self.downVoteButton.tintColor = .systemRed
        
        var currentGame: String? = nil
        if(!self.currentVideo!.game.isEmpty){
            currentGame = self.currentVideo!.game
        }
        VideoHelper().addDownVotePublicPost(currentUserUid: appDelegate.currentUser!.uId, videoOwnerUid: self.currentVideo!.videoOwnerUid, currentPostId: self.currentVideo!.postId, postVideoGame: currentGame)
    }
    
    @objc private func registerDownVote(sender: CommentVoteGesture){
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        for obj in self.commentPayload {
            if(obj.commentId == sender.commentId){
                var upVotes = obj.upvotes
                var downVotes = obj.downVotes
                if(upVotes.contains(appDelegate.currentUser!.uId)){
                    upVotes.remove(at: upVotes.firstIndex(of: appDelegate.currentUser!.uId)!)
                }
                if(!downVotes.contains(appDelegate.currentUser!.uId)){
                    downVotes.append(appDelegate.currentUser!.uId)
                }
                obj.downVotes = downVotes
                obj.upvotes = upVotes
                self.setPayload()
                VideoHelper().addDownVotePublicPostComment(currentUserUid: appDelegate.currentUser!.uId, videoOwnerUid: currentVideo!.videoOwnerUid, currentPostId: currentVideo!.postId, postVideoGame: currentVideo!.game, currentCommentId: sender.commentId)
                break
            }
        }
    }
}

extension Int {
    var roundedWithAbbreviations: String {
        let number = Double(self)
        let thousand = number / 1000
        let million = number / 1000000
        if million >= 1.0 {
            return "\(round(million*10)/10)M"
        }
        else if thousand >= 1.0 {
            return "\(round(thousand*10)/10)K"
        }
        else {
            return "\(self)"
        }
    }
}

class CommentVoteGesture: UITapGestureRecognizer {
    var commentId: String!
}
