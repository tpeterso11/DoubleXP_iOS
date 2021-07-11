//
//  FilterOptionDrawer.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 4/6/21.
//  Copyright © 2021 Peterson, Toussaint. All rights reserved.
//

import Foundation
import UIKit

class FilterOptionDrawer: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var table: UITableView!
    @IBOutlet weak var question: UILabel!
    var payload = [String]()
    var search: GamerConnectSearch?
    var searchManager: SearchManager?
    var questionText: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if(questionText == "age range"){
            self.question.text = "within which age range(s)?"
        } else {
            self.question.text = questionText
        }
        self.doneButton.addTarget(self, action: #selector(dismissDrawer), for: .touchUpInside)
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        search = appDelegate.currentGCSearchFrag
        searchManager = appDelegate.searchManager
        self.table.delegate = self
        self.table.dataSource = self
    }
    
    @objc private func dismissDrawer(){
        search?.dismissModal()
        self.dismiss(animated: true, completion: nil)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return payload.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let current = self.payload[indexPath.item]
        let cell = tableView.dequeueReusableCell(withIdentifier: "option", for: indexPath) as! FilterOptionCell
        cell.coverOption.text = current
        cell.option.text = current
        
        if(questionText == "age range"){
            var choice = ""
            if(current == "12 - 16"){
                choice = "12_16"
            } else if(current == "17 - 24"){
                choice = "17_24"
            } else if(current == "25 - 31"){
                choice = "25_31"
            } else if(current == "32 +"){
                choice = "32_over"
            }
            if(searchManager!.ageFilters.contains(choice)){
                cell.cover.alpha = 1
            } else {
                cell.cover.alpha = 0
            }
        } else {
            if(searchManager!.searchLookingFor.contains(current)){
                cell.cover.alpha = 1
            } else {
                cell.cover.alpha = 0
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let current = self.payload[indexPath.item]
        if(questionText == "age range"){
            var choice = ""
            if(current == "12 - 16"){
                choice = "12_16"
            } else if(current == "17 - 24"){
                choice = "17_24"
            } else if(current == "25 - 31"){
                choice = "25_31"
            } else if(current == "32 +"){
                choice = "32_over"
            }
            if(!choice.isEmpty && !searchManager!.ageFilters.contains(choice)){
                searchManager!.ageFilters.append(choice)
            } else if(!choice.isEmpty && searchManager!.ageFilters.contains(choice)){
                searchManager!.ageFilters.remove(at: searchManager!.ageFilters.index(of: choice)!)
            }
        } else {
            if(searchManager!.searchLookingFor.contains(current)){
                searchManager!.searchLookingFor.remove(at: searchManager!.searchLookingFor.index(of: current)!)
            } else {
                searchManager!.searchLookingFor.append(current)
            }
        }
        self.table.reloadData()
    }
}
