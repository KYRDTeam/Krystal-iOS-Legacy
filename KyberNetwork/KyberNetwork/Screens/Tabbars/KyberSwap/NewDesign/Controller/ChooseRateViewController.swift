//
//  ChooseRateViewController.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 12/22/20.
//

import UIKit
import BigInt

class ChooseRateViewModel {
  var data: [Rate]
  fileprivate(set) var from: TokenData
  fileprivate(set) var to: TokenData
  fileprivate(set) var gasPrice: BigInt
  fileprivate(set) var isDeposit: Bool
  fileprivate(set) var amountFrom: String? = ""

  var dataSource: [ChooseRateCellViewModel] = []

  init(from: TokenObject, to: TokenObject, data: [Rate], gasPrice: BigInt, isDeposit: Bool = false, amountFrom: String) {
    self.data = data
    self.from = from.toTokenData()
    self.to = to.toTokenData()
    self.gasPrice = gasPrice
    self.isDeposit = isDeposit
    self.amountFrom = amountFrom
  }

  init(from: TokenData, to: TokenData, data: [Rate], gasPrice: BigInt, isDeposit: Bool = false, amountFrom: String) {
    self.data = data
    self.from = from
    self.to = to
    self.gasPrice = gasPrice
    self.isDeposit = isDeposit
    self.amountFrom = amountFrom
  }

  func reloadDataSource() {
    var max = BigInt(0)
    if let firstData = self.data.first {
      max = BigInt.bigIntFromString(value: firstData.rate)
    }
    //If there are platforms which is significantly worse than the best, hide them (> 50% worse in term of rate)
    let filterData = self.data.filter { rate in
      return BigInt.bigIntFromString(value: rate.rate) >= max * BigInt(0.5 * pow(10.0, 18.0)) / BigInt(10).power(18)
    }
    
    self.dataSource = filterData.map({ rate in
      return ChooseRateCellViewModel(rate: rate, from: self.from, to: self.to, gasPrice: self.gasPrice)
    })
  }

  var popupHeight: CGFloat {
    let height = CGFloat(125 + self.data.count * 115)
    return height < 600.0 ? height : 600.0
  }
}

protocol ChooseRateViewControllerDelegate: class {
  func chooseRateViewController(_ controller: ChooseRateViewController, didSelect rate: String)
}

class ChooseRateViewController: KNBaseViewController {
  @IBOutlet weak var contentViewTopContraint: NSLayoutConstraint!
  @IBOutlet weak var contentView: UIView!
  @IBOutlet weak var platformTableView: UITableView!
  @IBOutlet weak var popupHeightContraint: NSLayoutConstraint!

  weak var delegate: ChooseRateViewControllerDelegate?
  let viewModel: ChooseRateViewModel
  let transitor = TransitionDelegate()

  init(viewModel: ChooseRateViewModel) {
    self.viewModel = viewModel
    super.init(nibName: ChooseRateViewController.className, bundle: nil)
    self.modalPresentationStyle = .custom
    self.transitioningDelegate = transitor
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    
    let nib = UINib(nibName: ChooseRateTableViewCell.className, bundle: nil)
    self.platformTableView.register(
      nib,
      forCellReuseIdentifier: ChooseRateTableViewCell.kCellID
    )
    self.platformTableView.rowHeight = ChooseRateTableViewCell.kCellHeight
    
    self.viewModel.reloadDataSource()
    self.popupHeightContraint.constant = self.viewModel.popupHeight
  }

  @IBAction func tapOutsidePopup(_ sender: UITapGestureRecognizer) {
    self.dismiss(animated: true, completion: nil)
  }
}

extension ChooseRateViewController: BottomPopUpAbstract {
  func setTopContrainConstant(value: CGFloat) {
    self.contentViewTopContraint.constant = value
  }

  func getPopupHeight() -> CGFloat {
    return self.viewModel.popupHeight
  }

  func getPopupContentView() -> UIView {
    return self.contentView
  }
}

extension ChooseRateViewController: UITableViewDataSource {
  func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.viewModel.dataSource.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(
      withIdentifier: ChooseRateTableViewCell.kCellID,
      for: indexPath
    ) as! ChooseRateTableViewCell

    let cellModel = self.viewModel.dataSource[indexPath.row]
    cellModel.completionHandler = { rate in
      self.delegate?.chooseRateViewController(self, didSelect: rate.platform)
      self.dismiss(animated: true, completion: nil)
    }
    cellModel.isDeposit = self.viewModel.isDeposit
    cell.updateCell(cellModel)
    cell.saveLabel.isHidden = true
    if self.viewModel.dataSource.count >= 2 {
      cell.saveLabel.isHidden = indexPath.row != 0
      let firstData = self.viewModel.dataSource[0]
      let secondData = self.viewModel.dataSource[1]
      
      let firstRateBigInt = BigInt.bigIntFromString(value: firstData.rate.rate)
      let secondRateBigInt = BigInt.bigIntFromString(value: secondData.rate.rate)
      
      if firstRateBigInt.displayRate(decimals: 18) == secondRateBigInt.displayRate(decimals: 18) {
        // incase first rate and second rate is equal then show "best"
        cell.saveLabel.text = "Best"
        cell.saveLabelWidthConstraint.constant = 40
      } else if let amountFrom = self.viewModel.amountFrom, !amountFrom.isEmpty {
        let amountFromBigInt = amountFrom.shortBigInt(decimals: 18) ?? BigInt(0)
        if let rate = KNTrackerRateStorage.shared.getPriceWithAddress(self.viewModel.to.address) {
          let savedAmountBigInt = (firstRateBigInt - secondRateBigInt) * amountFromBigInt / BigInt(10).power(18)
          let usd = savedAmountBigInt * BigInt(rate.usd * pow(10.0, 18.0)) / BigInt(10).power(18)
          let usdDoubleValue = Double(usd.string(decimals: 18, minFractionDigits: 0, maxFractionDigits: 2)) ?? 0.0
          if usdDoubleValue < 0.01 {
            cell.saveLabel.text = "Best"
          } else {
            cell.saveLabel.text = "Save $\(usd.string(decimals: 18, minFractionDigits: 0, maxFractionDigits: 2))"
          }
          cell.saveLabelWidthConstraint.constant = 79
        } else {
          // incase can not get the price show "Best"
          cell.saveLabel.text = "Best"
          cell.saveLabelWidthConstraint.constant = 40
        }
      }
    }

    return cell
  }
}

extension ChooseRateViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
  }
}
