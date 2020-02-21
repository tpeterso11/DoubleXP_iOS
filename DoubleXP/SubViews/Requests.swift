//
//  Requests.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 11/17/19.
//  Copyright © 2019 Peterson, Toussaint. All rights reserved.
//

import UIKit
import Firebase
import ImageLoader
import moa
import MSPeekCollectionViewDelegateImplementation

class Requests: ParentVC, UITableViewDelegate, UITableViewDataSource, RequestsUpdate {
    var userRequests = [Any]()
    var cellHeights: [CGFloat] = []
    
    @IBOutlet weak var requestList: UITableView!
    enum Const {
           static let closeCellHeight: CGFloat = 83
           static let openCellHeight: CGFloat = 205
           static let rowsCount = 1
    }
    
    @IBOutlet weak var requestsSub: UILabel!
    @IBOutlet weak var requestsHeader: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let currentUser = delegate.currentUser
        
        let top = CGAffineTransform(translationX: 0, y: 30)
        UIView.animate(withDuration: 0.8, delay: 0.3, options:[], animations: {
            self.requestsHeader.alpha = 1
            self.requestsHeader.transform = top
            self.requestsSub.alpha = 1
            self.requestsSub.transform = top
        }, completion: { (finished: Bool) in
            UIView.animate(withDuration: 0.3, delay: 0.0, options: [], animations: {
                if(currentUser != nil){
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        self.buildRequests(user: currentUser!)
                    }
                }
                else{
                    return
                }
            }, completion: nil)
        })
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let currentLanding = appDelegate.currentLanding
        currentLanding?.removeBottomNav(showNewNav: false, hideSearch: true, searchHint: nil, searchButtonText: nil, isMessaging: false)
        
        appDelegate.navStack.append(self)
        
        self.pageName = "Requests"
    }
    
    private func animateView(){
        requestList.delegate = self
        requestList.dataSource = self
        
        let top = CGAffineTransform(translationX: 0, y: 30)
        UIView.animate(withDuration: 0.8, animations: {
            self.requestList.alpha = 1
            self.requestList.transform = top
        }, completion: nil)
    }
    
    private func buildRequests(user: User){
        if(!user.pendingRequests.isEmpty){
            for request in user.pendingRequests{
                self.userRequests.append(request)
            }
        }
        
        if(!user.teamInvites.isEmpty){
            for request in user.teamInvites{
                self.userRequests.append(request)
            }
        }
        
        cellHeights = Array(repeating: Const.closeCellHeight, count: self.userRequests.count)
        
        if(!userRequests.isEmpty){
            requestList.estimatedRowHeight = Const.closeCellHeight
            requestList.rowHeight = UITableView.automaticDimension
            requestList.backgroundColor = UIColor.white
            
            if #available(iOS 10.0, *) {
                requestList.refreshControl = UIRefreshControl()
                requestList.refreshControl?.addTarget(self, action: #selector(refreshHandler), for: .valueChanged)
            }
            
            animateView()
        }
        else{
            //show empty
        }
    }
    
    @objc func refreshHandler() {
        let deadlineTime = DispatchTime.now() + .seconds(1)
        DispatchQueue.main.asyncAfter(deadline: deadlineTime, execute: { [weak self] in
            if #available(iOS 10.0, *) {
                self?.requestList.refreshControl?.endRefreshing()
            }
            self?.requestList.reloadData()
        })
    }
    
    func tableView(_: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return cellHeights[indexPath.row]
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.userRequests.count
    }
    
    func tableView(_: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard case let cell as RequestsFoldingCell = cell else {
            return
        }

        cell.backgroundColor = .clear

        if cellHeights[indexPath.row] == Const.closeCellHeight {
            cell.unfold(false, animated: false, completion: nil)
        } else {
            cell.unfold(true, animated: false, completion: nil)
        }

        //cell.number = indexPath.row
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! RequestsFoldingCell
        
        let current = userRequests[indexPath.item]
        
        if(current is FriendRequestObject){
            cell.setUI(friendRequest: (current as! FriendRequestObject), team: nil)
        }
        else{
            cell.setUI(friendRequest: nil, team: (current as! TeamObject))
        }
        
        cell.layoutMargins = UIEdgeInsets.zero
        cell.separatorInset = UIEdgeInsets.zero
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        let cell = tableView.cellForRow(at: indexPath) as! RequestsFoldingCell

        if cell.isAnimating() {
            return
        }

        var duration = 0.0
        let cellIsCollapsed = cellHeights[indexPath.row] == Const.closeCellHeight
        if cellIsCollapsed {
            cellHeights[indexPath.row] = Const.openCellHeight
            cell.unfold(true, animated: true, completion: nil)
            duration = 0.6
        } else {
            cellHeights[indexPath.row] = Const.closeCellHeight
            cell.unfold(false, animated: true, completion: nil)
            duration = 0.3
        }

        UIView.animate(withDuration: duration, delay: 0, options: .curveEaseOut, animations: { () -> Void in
            tableView.beginUpdates()
            tableView.endUpdates()
            
            // fix https://github.com/Ramotion/folding-cell/issues/169
            if cell.frame.maxY > tableView.frame.maxY {
                tableView.scrollToRow(at: indexPath, at: UITableView.ScrollPosition.bottom, animated: true)
            }
        }, completion: nil)
    }
    
    func updateCell(indexPath: IndexPath) {
        self.requestList.deleteRows(at: [indexPath], with: .automatic)
    }
    
    struct Section {
        var name: String
        var items: [Any]
        
        init(name: String, items: [Any]?) {
            self.name = name
            self.items = [Any]()
        }
        
        func getCount() -> Int{
            return items.count
        }
    }
}
