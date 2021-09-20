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
  
  var dataSource: [ChooseRateCellViewModel] = []
  
  init(from: TokenObject, to: TokenObject, data: [Rate], gasPrice: BigInt, isDeposit: Bool = false) {
    self.data = data
    self.from = from.toTokenData()
    self.to = to.toTokenData()
    self.gasPrice = gasPrice
    self.isDeposit = isDeposit
  }
  
  init(from: TokenData, to: TokenData, data: [Rate], gasPrice: BigInt, isDeposit: Bool = false) {
    self.data = data
    self.from = from
    self.to = to
    self.gasPrice = gasPrice
    self.isDeposit = isDeposit
  }
  
  func reloadDataSource() {
    self.dataSource = self.data.map({ rate in
      return ChooseRateCellViewModel(rate: rate, from: self.from, to: self.to, gasPrice: self.gasPrice)
    })
    
  }
  
  var popupHeight: CGFloat {
    let height = CGFloat(125 + self.data.count * 115)
    return height < 600.0 ? height : 600.0
  }

//  var uniRateText: String {
//    let key = KNGeneralProvider.shared.isEthereum ? "Uniswap" : "PancakeSwap v2"
//    return rateStringFor(platform: key)
//  }
//
//  var kyberRateText: String {
//    let key = KNGeneralProvider.shared.isEthereum ? "Kyber Network" : "PancakeSwap v1"
//    return rateStringFor(platform: key)
//  }
//
//  var uniFeeText: String {
//    let key = KNGeneralProvider.shared.isEthereum ? "Uniswap" : "PancakeSwap v2"
//    return feeStringFor(platform: key)
//  }
//
//  var kyberFeeText: String {
//    let key = KNGeneralProvider.shared.isEthereum ? "Kyber Network" : "PancakeSwap v1"
//    return feeStringFor(platform: key)
//  }
//
//  fileprivate func rateStringFor(platform: String) -> String {
//    let dict = self.data.first { (element) -> Bool in
//      if let platformString = element["platform"] as? String {
//        return platformString == platform
//      } else {
//        return false
//      }
//    }
//    if let rateString = dict?["rate"] as? String, let rate = BigInt(rateString) {
//      return rate.isZero ? "---" : "1 \(self.from.symbol) = \(rate.displayRate(decimals: 18)) \(self.to.symbol)"
//    } else {
//      return "---"
//    }
//  }
//
//  fileprivate func feeStringFor(platform: String) -> String {
//    let dict = self.data.first { (element) -> Bool in
//      if let platformString = element["platform"] as? String {
//        return platformString == platform
//      } else {
//        return false
//      }
//    }
//    if let estGasString = dict?["estimatedGas"] as? NSNumber, let estGas = BigInt(estGasString.stringValue) {
//      let rate = KNTrackerRateStorage.shared.getETHPrice()
//      let rateUSDDouble = rate?.usd ?? 0
//      let fee = estGas * gasPrice
//      let rateBigInt = BigInt(rateUSDDouble * pow(10.0, 18.0))
//      let feeUSD = fee * rateBigInt / BigInt(10).power(18)
//      return "\(fee.displayRate(decimals: 18)) \(KNGeneralProvider.shared.quoteToken) ~ $\(feeUSD.displayRate(decimals: 18))"
//    } else {
//      return "---"
//    }
//  }
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
    return cell
  }
}

extension ChooseRateViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
  }
}
