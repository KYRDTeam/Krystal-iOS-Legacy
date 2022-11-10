//
//  StakingFAQView.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 09/11/2022.
//

import Foundation
import UIKit

@IBDesignable
class StakingFAQView: BaseXibView {
  
  @IBOutlet weak var mainTitleLabel: UILabel!
  @IBOutlet weak var mainExpandButton: UIButton!
  @IBOutlet weak var contentTableView: UITableView!
  @IBOutlet weak var lineView: UIView!
  
  var isExpand: Observable<Bool> = .init(false)
  
  override func commonInit() {
    super.commonInit()
    
    registerCell()
    mainExpandButton.addTarget(self, action: #selector(pressed), for: .touchUpInside)
  }
  
  private func registerCell() {
    contentTableView.registerCellNib(StakingFAQCell.self)
    contentTableView.register(SectionHeaderFAQView.self,
                              forHeaderFooterViewReuseIdentifier: "sectionHeader")
  }
  
  @IBAction func expandButtonTapped(_ sender: UIButton) {
  }

  @objc func pressed() {
    isExpand.value = !isExpand.value
    UIView.animate(withDuration: 0.25) {
      if self.isExpand.value {
        self.mainExpandButton.transform = CGAffineTransform(rotationAngle: CGFloat.pi)
        self.lineView.isHidden = true
      } else {
        self.mainExpandButton.transform = CGAffineTransform(rotationAngle: 0)
        self.lineView.isHidden = false
      }
    }
  }
}

extension StakingFAQView: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return 1
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(StakingFAQCell.self, indexPath: indexPath)!
    
    return cell
  }
  
  func numberOfSections(in tableView: UITableView) -> Int {
    return 9
  }
}

extension StakingFAQView: UITableViewDelegate {
  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return 50
  }
  
  func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: "sectionHeader") as! SectionHeaderFAQView
    view.updateTitle(text: "[Firebase/Installations][I-FIS002001] -[FIRInstallationsIDController installationWithValidAuthTokenForcingRefresh:0]")
    return view
  }
  
  func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    return 44.0
  }
}
