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
  var dataSource: [MiniApp]
  var session: KNSession
  
  init(dataSource: [MiniApp], session: KNSession) {
    self.dataSource = dataSource
    self.session = session
    super.init(nibName: MiniAppListController.className, bundle: nil)
    self.modalPresentationStyle = .custom
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.tableView.registerCellNib(MiniAppDetailCell.self)
    if let miniApp = self.dataSource.first {
      self.titleLabel.text = miniApp.category
    }
  }

  @IBAction func onBackButtonTapped(_ sender: Any) {
    self.navigationController?.popViewController(animated: true)
  }
}

extension MiniAppListController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.dataSource.count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(MiniAppDetailCell.self, indexPath: indexPath)!
    let miniApp = self.dataSource[indexPath.row]
    cell.titleLabel.text = miniApp.name
    if let url = URL(string: miniApp.icon) {
      cell.icon.setImage(with: url, placeholder: nil)
    }
    
    return cell
  }
}

extension MiniAppListController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let miniApp = self.dataSource[indexPath.row]
    let detaiVC = MiniAppDetailViewController(miniApp: miniApp, session: self.session)
    self.show(detaiVC, sender: nil)
  }
}
