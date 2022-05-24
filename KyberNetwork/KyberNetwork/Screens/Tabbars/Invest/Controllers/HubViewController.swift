//
//  HubViewController.swift
//  KyberNetwork
//
//  Created by Com1 on 23/05/2022.
//

import UIKit

class HubViewController: KNBaseViewController {
  @IBOutlet weak var tableView: UITableView!

  override func viewDidLoad() {
    super.viewDidLoad()
    self.tableView.registerCellNib(MiniAppsCell.self)
  }
}

extension HubViewController: UITableViewDataSource {
  func numberOfSections(in tableView: UITableView) -> Int {
    return 10
  }
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return 1
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(MiniAppsCell.self, indexPath: indexPath)!
    cell.isSpecialApp = indexPath.section == 0
    cell.collectionView.reloadData()
    return cell
  }
}

extension HubViewController: UITableViewDelegate {
  
  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return indexPath.section == 0 ? 220 : 156
  }
  func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    return 50
  }
  
  func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
    return CGFloat(0.01)
  }
  
  func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    let view = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 50))
    
    let titleLabel = UILabel(frame: CGRect(x: 18, y: 18, width: UIScreen.main.bounds.size.width - 130, height: 24))
    titleLabel.text = "Top Trending"
    titleLabel.textColor = UIColor(named: "textWhiteColor")!
    titleLabel.font = UIFont.Kyber.bold(with: 18)
    view.addSubview(titleLabel)
    
    let detailButton = UIButton(frame: CGRect(x: UIScreen.main.bounds.size.width - 65, y: 20, width: 65, height: 20))
    detailButton.setTitle("See all", for: .normal)
    detailButton.setTitleColor(UIColor(named: "buttonBackgroundColor")!, for: .normal)
    detailButton.titleLabel?.font = UIFont.Kyber.bold(with: 14)
    detailButton.tag = section
    detailButton.addTarget(self, action: #selector(seeAllButtonTapped(_:)), for: .touchUpInside)
    view.addSubview(detailButton)
    
    view.backgroundColor = UIColor(named: "mainViewBgColor")!
    return view
  }
  
  @objc func seeAllButtonTapped(_ sender: UIButton) {
    print("hehe")
    let detailVC = MiniAppListController()
    self.navigationController?.show(detailVC, sender: nil)
  }
}
