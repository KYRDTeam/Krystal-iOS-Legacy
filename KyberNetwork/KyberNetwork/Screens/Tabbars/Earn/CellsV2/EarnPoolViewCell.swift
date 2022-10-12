//
//  EarnPoolViewCell.swift
//  KyberNetwork
//
//  Created by Com1 on 12/10/2022.
//

import UIKit

class EarnPoolViewCellViewModel {
  var isExpanse: Bool
  var numberOfPlatForm: Int
  
  init(isExpanse: Bool, numberOfPlatForm: Int) {
    self.isExpanse = isExpanse
    self.numberOfPlatForm = numberOfPlatForm
  }
  
  func height() -> CGFloat {
    return isExpanse ? 241 : 58
  }
}

class EarnPoolViewCell: UITableViewCell {

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
  
  func updateUI(viewModel: EarnPoolViewCellViewModel) {
    
  }
    
  func updateUIExpanse(viewModel: EarnPoolViewCellViewModel) {
    tableViewHeightConstraint.constant = viewModel.isExpanse ? 150 : 0
    tableView.isHidden = !viewModel.isExpanse
    
    tvlValueLabel.isHidden = viewModel.isExpanse
    apyValueLabel.isHidden = viewModel.isExpanse
    tvlLabel.isHidden = viewModel.isExpanse
    apyLabel.isHidden = viewModel.isExpanse
    arrowUpImage.isHidden = !viewModel.isExpanse
  }
}

extension EarnPoolViewCell: UITableViewDataSource {
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return 3
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(EarnPoolPlatformCell.self, indexPath: indexPath)!

    return cell
  }
}

extension EarnPoolViewCell: UITableViewDelegate {
  
}
