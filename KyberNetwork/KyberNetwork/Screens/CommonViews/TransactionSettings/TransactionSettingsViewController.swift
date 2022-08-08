//
//  TransactionSettingsViewController.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 08/08/2022.
//

import UIKit

class TransactionSettingsViewController: KNBaseViewController {
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // Do any additional setup after loading the view.
  }
}

extension TransactionSettingsViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return 1
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    
    return UITableViewCell()
  }
}
