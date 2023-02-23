//
//  AddChainViewController.swift
//  ChainModule
//
//  Created by Tung Nguyen on 20/02/2023.
//

import UIKit

class AddChainViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }

    @IBAction func backTapped(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
}
