//
//  PromoCodeListViewController.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 11/03/2022.
//

import UIKit

class PromoCodeListViewModel {
  var items: [PromoCodeItem] = []
  var unusedDataSource: [PromoCodeCellModel] = []
  var usedDataSource: [PromoCodeCellModel] = []
  
  func reloadDataSource() {
    unusedDataSource.removeAll()
    usedDataSource.removeAll()
    self.items.forEach { element in
      let cm = PromoCodeCellModel(item: element)
      if element.type == .claimed {
        self.usedDataSource.append(cm)
      } else {
        self.unusedDataSource.append(cm)
      }
    }
  }
  
  var numberOfSection: Int {
    return self.usedDataSource.isEmpty ? 1 : 2
  }
}

class PromoCodeListViewController: KNBaseViewController {
  
  @IBOutlet weak var promoCodeTableView: UITableView!
  
  let viewModel: PromoCodeListViewModel
  var cachedCell: [IndexPath: PromoCodeCell] = [:]
  
  init(viewModel: PromoCodeListViewModel) {
    self.viewModel = viewModel
    super.init(nibName: PromoCodeListViewController.className, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    let nib = UINib(nibName: PromoCodeCell.className, bundle: nil)
    self.promoCodeTableView.register(nib, forCellReuseIdentifier: PromoCodeCell.cellID)
    self.promoCodeTableView.rowHeight = UITableView.automaticDimension;
    self.promoCodeTableView.estimatedRowHeight = 200
    
  }
  
  @IBAction func backButtonTapped(_ sender: UIButton) {
    self.navigationController?.popViewController(animated: true, completion: nil)
  }
  
  func coordinatorDidUpdatePromoCodeItems(_ items: [PromoCodeItem]) {
    self.viewModel.items = items
    self.viewModel.reloadDataSource()
    guard self.isViewLoaded else { return }
    
    self.promoCodeTableView.reloadData()
  }
}


extension PromoCodeListViewController: UITableViewDataSource {
  func numberOfSections(in tableView: UITableView) -> Int {
    return self.viewModel.numberOfSection
  }
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if section == 0 {
      return self.viewModel.unusedDataSource.count
    } else {
      return self.viewModel.usedDataSource.count
    }
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(
      withIdentifier: PromoCodeCell.cellID,
      for: indexPath
    ) as! PromoCodeCell
    
    if indexPath.section == 0 {
      let cm = self.viewModel.unusedDataSource[indexPath.row]
      cell.updateCellModel(cm)
    } else {
      let cm = self.viewModel.usedDataSource[indexPath.row]
      cell.updateCellModel(cm)
    }
    self.cachedCell[indexPath] = cell
    return cell
  }
}

extension PromoCodeListViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    if let cell = self.cachedCell[indexPath] {
      
      let value = self.calculateHeightForConfiguredSizingCell(cell: cell)
      print("[Promo]  has cell \(value)")
      return value
    } else {
      print("[Promo]  no cell")
    }
    
//    if indexPath.section == 0 {
//      let txt = self.viewModel.unusedDataSource[indexPath.row].displayTitle
//
//    } else {
//      let txt = self.viewModel.usedDataSource[indexPath.row].displayTitle
//
//    }

    return 170 //TODO: calculate row height
  }

  func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    guard section == 1 else { return UIView(frame: CGRect.zero) }
    let view = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 40))
    view.backgroundColor = .clear
    let titleLabel = UILabel(frame: CGRect(x: 31, y: 0, width: 200, height: 40))
    titleLabel.center.y = view.center.y
    titleLabel.text = "Promo Code Used"
    titleLabel.font = UIFont.Kyber.bold(with: 16)
    titleLabel.textColor = UIColor.Kyber.SWWhiteTextColor
    view.addSubview(titleLabel)
    
    return view
  }
  
  func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
    if section == 0 {
      return 0
    } else {
      return 40
    }
  }
  
  func calculateHeightForConfiguredSizingCell(cell: UITableViewCell) -> CGFloat {
      cell.setNeedsLayout()
      cell.layoutIfNeeded()
    let height = cell.contentView.systemLayoutSizeFitting(UIView.layoutFittingExpandedSize).height + 1.0
      return height
  }
}
