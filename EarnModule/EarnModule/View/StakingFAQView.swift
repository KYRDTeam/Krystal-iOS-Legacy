//
//  StakingFAQView.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 09/11/2022.
//

import Foundation
import UIKit
import Utilities

typealias FAQInput = (platform: String, token: String, chainID: Int)
// swiftlint:disable all
protocol StakingFAQViewDelegate: class {
  func viewShouldChangeHeight(height: CGFloat)
}

class FAQCellItem {
  let model: FAQModel
  var isExpand: Bool
  
  init(_ model: FAQModel) {
    self.model = model
    self.isExpand = false
  }
}

class StakingFAQViewModel {
  var dataSource: [FAQCellItem] = []
  var input: FAQInput?
  
  var fileName: String {
    guard let input = input else {
      return ""
    }

    var name = ""
    if input.platform == "ankr" && input.token == "matic" && input.chainID == 1 {
      name = "ankr-matic-eth"
    } else if input.platform == "ankr" && input.token == "matic" && input.chainID == 137 {
      name = "ankr-matic-matic"
    } else if input.platform == "ankr" && input.token == "eth" {
      name = "ankr-eth"
    } else if input.platform == "ankr" && input.token == "ftm" {
      name = "ankr-ftm"
    } else if input.platform == "ankr" && input.token == "bnb" {
      name = "ankr-bnb"
    } else if input.platform == "ankr" && input.token == "avax" {
      name = "ankr-avax"
    } else if input.platform == "lido" && input.token == "eth" {
        name = "lido-eth"
    } else if input.platform == "lido" && input.token == "matic" {
       name = "lido-matic"
    }
    
    return name
  }
  
  func reloadDataSource() {
    guard input != nil, !fileName.isEmpty else {
      dataSource = []
      return
    }
    let decoder = PropertyListDecoder()
    let bundle = Bundle(for: type(of: self))
    if let url = bundle.url(forResource: fileName, withExtension: "plist"),
        let data = try? Data(contentsOf: url),
        let models = try? decoder.decode([FAQModel].self, from: data) {
      dataSource = models.map { FAQCellItem($0) }
    } else {
      dataSource = []
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
  var currentHeight: CGFloat?
  
  let viewModel = StakingFAQViewModel()
  
  weak var delegate: StakingFAQViewDelegate?
  
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
  
  func updateFAQInput(_ input: FAQInput) {
    viewModel.input = input
    viewModel.reloadDataSource()
    contentTableView.reloadData()
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
      self.delegate?.viewShouldChangeHeight(height: self.getViewHeight())
      self.isHidden = self.viewModel.dataSource.isEmpty
    }
  }
}

extension StakingFAQView: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    guard !viewModel.dataSource.isEmpty else { return 0 }
    return viewModel.dataSource[section].isExpand ? 1 : 0
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(StakingFAQCell.self, indexPath: indexPath)!
    let cellModel = viewModel.dataSource[indexPath.section]
    cell.updateHTMLContent(cellModel.model.answer)
    return cell
  }
  
  func numberOfSections(in tableView: UITableView) -> Int {
    return viewModel.dataSource.count
  }
}

extension StakingFAQView: UITableViewDelegate {
  func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: "sectionHeader") as! SectionHeaderFAQView
    let cellModel = viewModel.dataSource[section]
    view.updateTitle(text: cellModel.model.question)
    view.section = section
    view.isExpand = cellModel.isExpand
    view.delegate = self
    return view
  }
  
  func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    let cm = viewModel.dataSource[section]
    return SectionHeaderFAQView.estimateHeightForSection(cm.model.question)
  }
}

extension StakingFAQView: SectionHeaderFAQViewDelegate {
  func didChangeExpandStatus(status: Bool, section: Int) {
    let cellModel = viewModel.dataSource[section]
    cellModel.isExpand = status
    contentTableView.reloadData()
    contentTableView.sizeToFit()
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
      let height = self.getViewHeight()
      self.delegate?.viewShouldChangeHeight(height: height)
      self.currentHeight = height
    }
  }
}
