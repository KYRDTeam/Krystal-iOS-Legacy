//
//  MiniAppListController.swift
//  KyberNetwork
//
//  Created by Com1 on 24/05/2022.
//

import UIKit

class MiniAppListController: KNBaseViewController {
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var tableView: UITableView!

  override func viewDidLoad() {
    super.viewDidLoad()
    self.tableView.registerCellNib(MiniAppDetailCell.self)
  }

  @IBAction func onBackButtonTapped(_ sender: Any) {
    self.navigationController?.popViewController(animated: true)
  }
}

extension MiniAppListController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return 10
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(MiniAppDetailCell.self, indexPath: indexPath)!
    
    return cell
  }
}
