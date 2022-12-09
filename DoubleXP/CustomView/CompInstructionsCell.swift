//
//  CompInstructionsCell.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 5/6/22.
//  Copyright © 2022 Peterson, Toussaint. All rights reserved.
//

import Foundation
import UIKit

class CompInstructionsCell: UITableViewCell, UITableViewDelegate, UITableViewDataSource {
    var payload = [String]()
    var dataSet = false
    @IBOutlet weak var instructionsTable: UITableView!
    
    func setTable(payload: [String]){
        self.payload = payload
        if(!dataSet){
            self.dataSet = true
            self.instructionsTable.delegate = self
            self.instructionsTable.dataSource = self
        } else {
            self.instructionsTable.reloadData()
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.payload.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "instruction", for: indexPath) as! IndividualInstructionCell
        cell.instructionLabel.text = payload[indexPath.item]
        return cell
    }
}
