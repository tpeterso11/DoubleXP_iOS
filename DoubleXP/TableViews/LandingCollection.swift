//
//  LandingCollection.swift
//  DoubleXP
//
//  Created by Toussaint Peterson on 4/17/19.
//  Copyright © 2019 Peterson, Toussaint. All rights reserved.
//

import UIKit

class LandingCollection: UITableViewController{
    var currentNews: [NewsObject]!
    
    override func viewDidLoad() {
        //currentNews = getInfoFromDelegate()
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        print("toto")
    }
    
    //func getInfoFromDelegate() -> [NewsObject]{
    //    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    //    return appDelegate.homepageNews
    //}
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // return the number of sections
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // return the number of rows
        return currentNews.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! NewsCell
        
        //cell.textLabel?.text = numbers[indexPath.row]

        return cell
    }
}
