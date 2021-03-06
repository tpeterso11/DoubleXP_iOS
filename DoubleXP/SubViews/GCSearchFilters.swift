//
//  GCSearchFilters.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 10/24/20.
//  Copyright © 2020 Peterson, Toussaint. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation
import SwiftLocation
import PopupDialog
import FirebaseDatabase
import GeoFire

struct filterCell {
    var opened = true
    var title: String!
    var options: [[String: String]]!
    var header = false
    var type: String!
    //question: answer/db_value
}

class GCSearchFilters: UIViewController, UITableViewDelegate, UITableViewDataSource, CLLocationManagerDelegate {
    @IBOutlet weak var table: UITableView!
    @IBOutlet weak var searchButton: UIButton!
    @IBOutlet weak var clearButton: UIButton!
    @IBOutlet weak var clear: UIButton!
    @IBOutlet weak var search: UIButton!
    var gcGame: GamerConnectGame!
    var basicFilterList = [filterCell]()
    var currentManager: SearchManager!
    var locationManager: CLLocationManager?
    var req: LocationRequest?
    var popup: PopupDialog?
    var locationShowing = false
    var locationCell: filterCell?
    var currentSelectedSender: DistanceGesture?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let delegate = UIApplication.shared.delegate as! AppDelegate
        currentManager = delegate.searchManager
        self.clear.alpha = 0.3
        
        self.searchButton.addTarget(self, action: #selector(searchFromButton), for: .touchUpInside)
        
        if(delegate.currentUser!.userLat != 0.0){
            updateLocation()
        }
        
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
        
        locationCell = filterCell()
        locationCell?.header = true
        locationCell?.title = "location"
        locationCell?.type = "activate"
        locationCell?.opened = true
        locationCell?.options = [["": ""]]
        self.basicFilterList.append(locationCell!)
        
        let baby = ["12 - 16": "12_16"]
        let young = ["17 - 24": "17_24"]
        let mid = ["25 - 31": "25_31"]
        let grown = ["32 +": "32_over"]
        let ageChoices = [baby, young, mid, grown]
        var opened = !self.currentManager.ageFilters.isEmpty
        let age = filterCell(opened: opened, title: "age range", options: ageChoices, type: "age")
        self.basicFilterList.append(age)
        
        /*let english = ["english": "english"]
        let spanish = ["spanish": "spanish"]
        let french = ["french": "french"]
        let chinese = ["chinese": "chinese"]
        let languageChoices = [english, spanish, french, chinese]
        opened = !self.currentManager.langaugeFilters.isEmpty
        let language = filterCell(opened: opened, title: "language", options: languageChoices, type: "language")
        self.basicFilterList.append(language)*/
        
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
                        cell.switch.addTarget(self, action: #selector(locationSwitchTriggered), for: UIControl.Event.valueChanged)
                    }
                    return cell
                } else {
                    let cell = tableView.dequeueReusableCell(withIdentifier: "category", for: indexPath) as! FilterCategory
                    cell.title.text = self.basicFilterList[indexPath.section].title
                    return cell
                }
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
        } else {
            if(self.basicFilterList[indexPath.section].header == true){
                if(self.basicFilterList[indexPath.section].title == "location"){
                    let cell = tableView.dequeueReusableCell(withIdentifier: "distance", for: indexPath) as! DistanceCell
                    
                    let fiftyTap = DistanceGesture(target: self, action: #selector(distanceChosen))
                    fiftyTap.tag = "fifty_miles"
                    fiftyTap.section = indexPath.section
                    cell.fifty.isUserInteractionEnabled = true
                    cell.fifty.addGestureRecognizer(fiftyTap)
                    
                    if(self.currentManager.locationFilter == "fifty_miles"){
                        cell.fiftyCover.alpha = 1
                    } else {
                        cell.fiftyCover.alpha = 0
                    }
                    
                    let hundredTap = DistanceGesture(target: self, action: #selector(distanceChosen))
                    hundredTap.tag = "hundred_miles"
                    hundredTap.section = indexPath.section
                    cell.hundred.isUserInteractionEnabled = true
                    cell.hundred.addGestureRecognizer(hundredTap)
                    
                    if(self.currentManager.locationFilter == "hundred_miles"){
                        cell.hundredCover.alpha = 1
                    } else {
                        cell.hundredCover.alpha = 0
                    }
                    
                    let timezoneTap = DistanceGesture(target: self, action: #selector(distanceChosen))
                    timezoneTap.tag = "timezone"
                    timezoneTap.section = indexPath.section
                    cell.timezoneButton.isUserInteractionEnabled = true
                    cell.timezoneButton.addGestureRecognizer(timezoneTap)
                    
                    if(self.currentManager.locationFilter == "timezone"){
                        cell.timezoneCover.alpha = 1
                    } else {
                        cell.timezoneCover.alpha = 0
                    }
                    
                    let noneTap = DistanceGesture(target: self, action: #selector(distanceChosen))
                    noneTap.tag = "none"
                    noneTap.section = indexPath.section
                    cell.globalButton.isUserInteractionEnabled = true
                    cell.globalButton.addGestureRecognizer(noneTap)
                    
                    if(self.currentManager.locationFilter == "none"){
                        cell.globalCover.alpha = 1
                    } else {
                        cell.globalCover.alpha = 0
                    }
                    
                    let delegate = UIApplication.shared.delegate as! AppDelegate
                    if(delegate.currentUser!.userLat != 0.0){
                        cell.cover.alpha = 0
                    } else {
                        cell.cover.alpha = 1
                    }
                    
                    return cell
                } else {
                    let cell = tableView.dequeueReusableCell(withIdentifier: "empty", for: indexPath) as! EmptyCell
                    return cell
                }
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
            let type = self.basicFilterList[indexPath.section].type
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
                if(self.basicFilterList[indexPath.section].title == "location"){
                    return CGFloat(220)
                } else{
                    return CGFloat(10)
                }
            }
            else {
                return CGFloat(60)
            }
        }
    }
    
    @objc private func searchFromButton(){
        let delegate = UIApplication.shared.delegate as! AppDelegate
        delegate.currentGCSearchFrag?.dismissModal()
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc private func clearFilters(){
        self.currentManager.advancedFilters = [[String: String]]()
        self.currentManager.ageFilters = [String]()
        self.currentManager.langaugeFilters = [String]()
        self.table.reloadData()
        self.checkClearButton()
    }
    
    @objc private func distanceChosen(sender: DistanceGesture){
        self.currentManager.locationFilter = sender.tag
        self.table.reloadData()
    }
    
    @objc private func locationSwitchTriggered(sender: UISwitch) {
        let delegate = UIApplication.shared.delegate as! AppDelegate
        if(delegate.currentUser!.userLat != 0.0){
            delegate.currentUser!.userLat = 0.0
            delegate.currentUser!.userLong = 0.0
            self.sendLocationInfo()
            self.table.reloadData()
        } else {
            locationManager = CLLocationManager()
            locationManager?.delegate = self
            if #available(iOS 14.0, *) {
                locationManager?.desiredAccuracy = kCLLocationAccuracyReduced
            } else {
                locationManager?.desiredAccuracy = 5000
            }
            locationManager?.requestWhenInUseAuthorization()
        }
    }
    
    private func updateLocation(){
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        if #available(iOS 14.0, *) {
            locationManager?.desiredAccuracy = kCLLocationAccuracyReduced
        } else {
            locationManager?.desiredAccuracy = 5000
        }
        locationManager?.requestWhenInUseAuthorization()
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
            //manager.startUpdatingLocation()
            self.req = LocationManager.shared.locateFromGPS(.continous, accuracy: .city) { result in
              switch result {
                case .failure(let error):
                  debugPrint("Received error: \(error)")
                    self.popup?.dismiss()
                    self.table.reloadData()
                case .success(let location):
                    let delegate = UIApplication.shared.delegate as! AppDelegate
                    delegate.currentUser!.userLat = location.coordinate.latitude
                    delegate.currentUser!.userLong = location.coordinate.longitude
                    
                    var localTimeZoneAbbreviation: String { return TimeZone.current.abbreviation() ?? "" }
                    delegate.currentUser!.timezone = localTimeZoneAbbreviation
                    
                    self.sendLocationInfo()
                    self.popup?.dismiss()
                    self.table.reloadData()
              }
            }
            self.req?.start()
        } else if(status == .denied){
            showLocationDialog()
        } else if(status == .notDetermined){
            if(self.currentSelectedSender != nil){
                //locationSwitchTriggered(sender: 0)
            }
        }
    }
    
    private func sendLocationInfo(){
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let ref = Database.database().reference().child("Users").child(delegate.currentUser!.uId)
        ref.child("userLat").setValue(delegate.currentUser!.userLat)
        ref.child("userLong").setValue(delegate.currentUser!.userLong)
        ref.child("timezone").setValue(delegate.currentUser!.timezone)
        
        if(delegate.currentUser!.userLat != 0.0){
            let geofireRef = Database.database().reference().child("geofire")
            let geoFire = GeoFire(firebaseRef: geofireRef)
            geoFire.setLocation(CLLocation(latitude: delegate.currentUser!.userLat, longitude: delegate.currentUser!.userLong), forKey: delegate.currentUser!.uId)
            self.req?.stop()
        }
    }
    
    private func showLocationDialog(){
        let title = "DoubleXP needs your permission."
        let message = "we only use your location to find users near you."

        popup = PopupDialog(title: title, message: message)
        let buttonOne = CancelButton(title: "cancel.") {
            print("dang it.")
            self.table.reloadData()
        }

        // This button will not the dismiss the dialog
        let buttonTwo = DefaultButton(title: "go to settings.", dismissOnTap: false) {
            guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                        return
            }
            if UIApplication.shared.canOpenURL(settingsUrl) {
                UIApplication.shared.open(settingsUrl, completionHandler: { (success) in })
            }
        }
        popup!.addButtons([buttonOne, buttonTwo])//, buttonTwo, buttonThree])
        self.present(popup!, animated: true, completion: nil)
    }
}

class DistanceGesture: UITapGestureRecognizer {
    var tag: String!
    var section: Int!
}
