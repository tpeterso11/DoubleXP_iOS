//
//  GCSearchFilters.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 10/24/20.
//  Copyright © 2020 Peterson, Toussaint. All rights reserved.
//

import Foundation
import UIKit

struct filterCell {
    var opened = true
    var title: String!
    var options: [[String: String]]!
    var header = false
    var type: String!
    //question: answer/db_value
}

class GCSearchFilters: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var table: UITableView!
    @IBOutlet weak var searchButton: UIButton!
    @IBOutlet weak var clearButton: UIButton!
    @IBOutlet weak var clear: UIButton!
    @IBOutlet weak var search: UIButton!
    var gcGame: GamerConnectGame!
    var basicFilterList = [filterCell]()
    var currentManager: SearchManager!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let delegate = UIApplication.shared.delegate as! AppDelegate
        currentManager = delegate.searchManager
        self.clear.alpha = 0.3
        
        self.search.addTarget(self, action: #selector(searchFromButton), for: .touchUpInside)
        
        buildFilterList()
    }
    
    private func checkClearButton(){
        if(!currentManager.advancedFilters.isEmpty || !currentManager.ageFilters.isEmpty || !currentManager.langaugeFilters.isEmpty){
            self.clear.alpha = 1.0
            self.clear.isUserInteractionEnabled = true
            self.clear.addTarget(self, action: #selector(clearFilters), for: .touchUpInside)
        } else {
            self.clear.alpha = 0.3
            self.clear.isUserInteractionEnabled = false
        }
    }
    
    private func buildFilterList(){
        self.basicFilterList = [filterCell]()
        
        var header = filterCell()
        header.header = true
        header.title = "basic"
        header.options = [["": ""]]
        self.basicFilterList.append(header)
        var locationSwitch = filterCell()
        locationSwitch.header = true
        locationSwitch.title = "location"
        locationSwitch.type = "activate"
        locationSwitch.options = [["": ""]]
        self.basicFilterList.append(locationSwitch)
        let baby = ["12 - 16": "12_16"]
        let young = ["17 - 24": "17_24"]
        let mid = ["25 - 31": "25_31"]
        let grown = ["32 +": "32_over"]
        let ageChoices = [baby, young, mid, grown]
        let age = filterCell(opened: false, title: "age range", options: ageChoices, type: "age")
        self.basicFilterList.append(age)
        
        let english = ["english": "english"]
        let spanish = ["spanish": "spanish"]
        let french = ["french": "french"]
        let chinese = ["chinese": "chinese"]
        let languageChoices = [english, spanish, french, chinese]
        let language = filterCell(opened: false, title: "language", options: languageChoices, type: "language")
        self.basicFilterList.append(language)
        
        if(!gcGame.filterQuestions.isEmpty){
            var advancedHeader = filterCell()
            advancedHeader.header = true
            advancedHeader.title = "advanced filters"
            advancedHeader.options = [["": ""]]
            self.basicFilterList.append(advancedHeader)
            
            for question in gcGame.filterQuestions {
                let key = Array(question.keys)[0]
                var options = [[String: String]]()
                let answers = question[key] as? [[String: String]]
                for answer in answers! {
                    let answerKey = Array(answer.keys)[0]
                    let option = [key: answer[answerKey]!]
                    options.append(option)
                }
                let filter = filterCell(opened: false, title: key, options: options, type: "advanced")
                self.basicFilterList.append(filter)
            }
        }
        
        self.table.dataSource = self
        self.table.delegate = self
        self.table.reloadData()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.basicFilterList.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if(self.basicFilterList[section].opened == true){
            return self.basicFilterList[section].options.count + 1
        } else {
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if(indexPath.row == 0){
            if(self.basicFilterList[indexPath.section].header == true){
                let cell = tableView.dequeueReusableCell(withIdentifier: "category", for: indexPath) as! FilterCategory
                cell.title.text = self.basicFilterList[indexPath.section].title
                return cell
            } else {
                if(self.basicFilterList[indexPath.section].type == "activate"){
                    let cell = tableView.dequeueReusableCell(withIdentifier: "activate", for: indexPath) as! FilterActivateCell
                    cell.label.text = self.basicFilterList[indexPath.section].title
                    
                    if(self.basicFilterList[indexPath.section].title == "location"){
                        let delegate = UIApplication.shared.delegate as! AppDelegate
                        if(delegate.currentUser!.userLat != 0.0){
                            cell.switch.isOn = true
                        } else {
                            cell.switch.isOn = false
                        }
                    }
                    return cell
                } else {
                    let cell = tableView.dequeueReusableCell(withIdentifier: "header", for: indexPath) as! FilterHeader
                    cell.header.text = self.basicFilterList[indexPath.section].title
                    
                    if(self.basicFilterList[indexPath.section].opened == true){
                        cell.arrow.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi));
                    } else {
                        cell.arrow.transform = CGAffineTransform(rotationAngle: CGFloat(0));
                    }
                    return cell
                }
            }
        } else {
            if(self.basicFilterList[indexPath.section].header == true){
                let cell = tableView.dequeueReusableCell(withIdentifier: "empty", for: indexPath) as! EmptyCell
                return cell
            }
            else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "option", for: indexPath) as! FilterOption
                let current = self.basicFilterList[indexPath.section].options[indexPath.row - 1] as? [String: String]
                let key = Array(current!.keys)[0]
                
                let currentFilter = self.basicFilterList[indexPath.section]
                if(currentFilter.type != "advanced"){
                    cell.option.text = key
                    cell.coverLabel.text = key
                    
                    if(self.currentManager.ageFilters.contains(current![key] ?? "") || self.currentManager.langaugeFilters.contains(current![key] ?? "")){
                        cell.cover.alpha = 1
                    } else {
                        cell.cover.alpha = 0
                    }
                } else {
                    cell.option.text = current![key]
                    cell.coverLabel.text = current![key]
                    
                    var contained = false
                    for option in self.currentManager.advancedFilters {
                        let thisKey = Array(option.keys)[0]
                        let thisValue = option[thisKey]
                        if(key == thisKey && thisValue == current![key]){
                            contained = true
                            break
                        }
                    }
                    if(contained){
                        cell.cover.alpha = 1
                    } else {
                        cell.cover.alpha = 0
                    }
                }
                return cell
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if(indexPath.row == 0){
            if(self.basicFilterList[indexPath.section].header != true){
                if(self.basicFilterList[indexPath.section].opened == true){
                    self.basicFilterList[indexPath.section].opened = false
                    let sections = IndexSet.init(integer: indexPath.section)
                    tableView.reloadSections(sections, with: .none)
                } else {
                    self.basicFilterList[indexPath.section].opened = true
                    let sections = IndexSet.init(integer: indexPath.section)
                    tableView.reloadSections(sections, with: .none)
                }
            }
        } else {
            let currentFilter = self.basicFilterList[indexPath.section]
            if(currentFilter.type != "advanced"){
                let current = self.basicFilterList[indexPath.section].options[indexPath.row - 1] as? [String: String]
                let key = Array(current!.keys)[0]
                if(currentFilter.type == "age"){
                    let value = current![key]!
                    if(self.currentManager.ageFilters.contains(value)){
                        self.currentManager.ageFilters.remove(at: self.currentManager.ageFilters.index(of: value)!)
                    } else {
                        self.currentManager.ageFilters.append(value)
                    }
                } else {
                    let value = current![key] ?? ""
                    if(self.currentManager.langaugeFilters.contains(value)){
                        self.currentManager.langaugeFilters.remove(at: self.currentManager.langaugeFilters.index(of:value)!)
                    } else {
                        if(!value.isEmpty){
                            self.currentManager.langaugeFilters.append(value)
                        }
                    }
                }
                checkClearButton()
                self.table.reloadData()
            } else {
                let current = self.basicFilterList[indexPath.section].options[indexPath.row - 1] as? [String: String]
                let selectedKey = Array(current!.keys)[0]
                var contained = false
                
                for array in self.currentManager.advancedFilters {
                    let arrayKey = Array(array.keys)[0]
                    let value = array[arrayKey]
                    if(arrayKey == selectedKey && value == current![selectedKey]){
                        self.currentManager.advancedFilters.remove(at: self.currentManager.advancedFilters.index(of: array)!)
                        contained = true
                        break
                    }
                }
                
                if(!contained){
                    self.currentManager.advancedFilters.append(current!)
                }
                
                checkClearButton()
                self.table.reloadData()
            }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if(indexPath.row == 0){
            if(self.basicFilterList[indexPath.section].header == true){
                return CGFloat(50)
            } else {
                return CGFloat(80)
            }
        } else {
            if(self.basicFilterList[indexPath.section].header == true){
                return CGFloat(10)
            }
            else {
                return CGFloat(60)
            }
        }
    }
    
    @objc private func searchFromButton(){
        let delegate = UIApplication.shared.delegate as! AppDelegate
        delegate.currentGCSearchFrag?.dismissModal()
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func clearFilters(){
        self.currentManager.advancedFilters = [[String: String]]()
        self.currentManager.ageFilters = [String]()
        self.currentManager.langaugeFilters = [String]()
        self.table.reloadData()
        self.checkClearButton()
    }
}
