//
//  MultiOptionCell.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 8/11/20.
//  Copyright © 2020 Peterson, Toussaint. All rights reserved.
//

import Foundation
import UIKit

class MultiOptionCell: UITableViewCell, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet weak var question: UILabel!
    @IBOutlet weak var answerTable: UITableView!
    
    
    private var payload = [String]()
    
    func setPayload(payload: [String]){
        self.payload = payload
        self.answerTable.delegate = self
        self.answerTable.dataSource = self
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.payload.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "option", for: indexPath) as! QuizOptionCell
        let current = payload[indexPath.item]
        cell.optionLabel.text = current
        
        return cell
    }
}
