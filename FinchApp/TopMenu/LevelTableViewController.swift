//
//  LevelTableViewController.swift
//  FinchApp
//
//  Created by Kristina Lauwers on 4/8/18.
//  Copyright © 2018 none. All rights reserved.
//

import UIKit

protocol LevelTableViewControllerDelegate {
    func selectLevel(_ level: Int)
}

class LevelTableViewController: UITableViewController {
    
    var levelSelected: Int?
    var delegate: LevelTableViewControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let levelSelected = levelSelected else {
            fatalError("Must specify level before opening level table.")
        }
        
        self.tableView.selectRow(at: IndexPath.init(row: levelSelected - 1, section: 0), animated: false, scrollPosition: UITableViewScrollPosition.none)

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "levelCell", for: indexPath)

        cell.textLabel?.text = "Level \(indexPath.row + 1)"
        cell.textLabel?.textAlignment = .center

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        levelSelected = indexPath.row + 1
        self.delegate?.selectLevel(indexPath.row + 1)
        self.presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    

}
