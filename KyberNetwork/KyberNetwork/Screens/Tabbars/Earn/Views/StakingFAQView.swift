//
//  StakingFAQView.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 09/11/2022.
//

import Foundation
import UIKit
// swiftlint:disable all
class FAQCellItem {
  let model: FAQModel
  var isExpand: Bool
  
  init(_ model: FAQModel) {
    self.model = model
    self.isExpand = true
  }
}

class StakingFAQViewModel {
  var dataSource: [FAQCellItem] = []
  
  func reloadDataSource() {
    let decoder = PropertyListDecoder()
    if let url = Bundle.main.url(forResource: "Ankr-matic-eth", withExtension: "plist"),
        let data = try? Data(contentsOf: url),
        let models = try? decoder.decode([FAQModel].self, from: data) {
      dataSource = models.map { FAQCellItem($0) }
    }
  }
}

@IBDesignable
class StakingFAQView: BaseXibView {
  
  @IBOutlet weak var mainTitleLabel: UILabel!
  @IBOutlet weak var mainExpandButton: UIButton!
  @IBOutlet weak var contentTableView: UITableView!
  @IBOutlet weak var lineView: UIView!
  
  var isExpand: Observable<Bool> = .init(false)
  
  let viewModel = StakingFAQViewModel()
  
  override func commonInit() {
    super.commonInit()
    contentTableView.rowHeight = UITableView.automaticDimension
    contentTableView.estimatedRowHeight = 300
    registerCell()
    mainExpandButton.addTarget(self, action: #selector(pressed), for: .touchUpInside)
    viewModel.reloadDataSource()
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
    contentTableView.reloadData()
  }
  
  func getViewHeight() -> CGFloat {
    return 52 + contentTableView.contentSize.height
  }
}

extension StakingFAQView: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return viewModel.dataSource[section].isExpand ? 1 : 0
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(StakingFAQCell.self, indexPath: indexPath)!
    let cm = viewModel.dataSource[indexPath.section]
    cell.updateHTMLContent(cm.model.answer)
    return cell
  }
  
  func numberOfSections(in tableView: UITableView) -> Int {
    return 9
  }
}

extension StakingFAQView: UITableViewDelegate {
  func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: "sectionHeader") as! SectionHeaderFAQView
    let cm = viewModel.dataSource[section]
    view.updateTitle(text: cm.model.question)
    return view
  }
  
  func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    let cm = viewModel.dataSource[section]
    return SectionHeaderFAQView.estimateHeightForSection(cm.model.question)
  }
}
