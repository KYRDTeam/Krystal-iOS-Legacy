//
//  EarnPoolViewCell.swift
//  KyberNetwork
//
//  Created by Com1 on 12/10/2022.
//

import UIKit

class EarnPoolViewCellViewModel {
  var isExpanse: Bool
  var earnPoolModel: EarnPoolModel
 
  init(earnPool: EarnPoolModel) {
    self.isExpanse = false
    self.earnPoolModel = earnPool
  }
  
  func height() -> CGFloat {
    return CGFloat(isExpanse ? 66 + 74 * earnPoolModel.platforms.count + 30 : 66)
  }
  
  func apyString() -> String {
    return NumberFormatUtils.percent(value: earnPoolModel.apy)
  }

  func tvlString() -> String {
    return "$" + NumberFormatUtils.volFormat(number: earnPoolModel.tvl)
  }
  
  func platFormDataSource() -> [EarnPlatform] {
    return earnPoolModel.platforms
  }
}

class EarnPoolViewCell: UITableViewCell {
  @IBOutlet weak var dashView: DashedLineView!
  @IBOutlet weak var tableView: UITableView!
  @IBOutlet weak var tableViewHeightConstraint: NSLayoutConstraint!
  @IBOutlet weak var tvlValueLabel: UILabel!
  @IBOutlet weak var apyValueLabel: UILabel!
  @IBOutlet weak var tokenLabel: UILabel!
  @IBOutlet weak var chainImage: UIImageView!
  @IBOutlet weak var tokenImage: UIImageView!
  @IBOutlet weak var tvlLabel: UILabel!
  @IBOutlet weak var apyLabel: UILabel!
  @IBOutlet weak var arrowUpImage: UIImageView!
  @IBOutlet weak var chainImageContaintView: UIView!
  var viewModel: EarnPoolViewCellViewModel?
  
  override func awakeFromNib() {
    super.awakeFromNib()
    tableViewHeightConstraint.constant = 0
    tableView.isHidden = true
    tableView.dataSource = self
    tableView.delegate = self
    tableView.registerCellNib(EarnPoolPlatformCell.self)
  }

  override func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)
  }
  
  func updateUI(viewModel: EarnPoolViewCellViewModel, shouldShowChainIcon: Bool) {
    self.viewModel = viewModel
    self.chainImageContaintView.isHidden = !shouldShowChainIcon
    self.updateUIExpanse(viewModel: viewModel)
    self.tokenLabel.text = viewModel.earnPoolModel.token.symbol
    self.tokenImage.setImage(urlString: viewModel.earnPoolModel.token.logo, symbol: viewModel.earnPoolModel.token.symbol)
    self.chainImage.setImage(urlString: viewModel.earnPoolModel.chainLogo, symbol: "")
    self.apyValueLabel.text = viewModel.apyString()
    self.tvlValueLabel.text = viewModel.tvlString()
    self.tableView.reloadData()
  }
    
  func updateUIExpanse(viewModel: EarnPoolViewCellViewModel) {
    DispatchQueue.main.async {
      self.tableViewHeightConstraint.constant = viewModel.isExpanse ? 246 : 0
      self.tableView.isHidden = !viewModel.isExpanse
      self.dashView.isHidden = !viewModel.isExpanse
      self.tvlValueLabel.isHidden = viewModel.isExpanse
      self.apyValueLabel.isHidden = viewModel.isExpanse
      self.tvlLabel.isHidden = viewModel.isExpanse
      self.apyLabel.isHidden = viewModel.isExpanse
      self.arrowUpImage.isHidden = !viewModel.isExpanse
    }
  }
}

extension EarnPoolViewCell: UITableViewDataSource {
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.viewModel?.platFormDataSource().count ?? 0
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(EarnPoolPlatformCell.self, indexPath: indexPath)!
    if let earnPlatform = self.viewModel?.platFormDataSource()[indexPath.row] {
      cell.updateUI(platform: earnPlatform)
    }
    return cell
  }
}

extension EarnPoolViewCell: UITableViewDelegate {
  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return 74.0
  }
}
