//
//  SelectNetworkViewController.swift
//  KyberNetwork
//
//  Created by Com1 on 04/03/2022.
//

import UIKit

protocol SelectNetworkViewControllerDelegate: class {
  func didSelectNetwork(chain: String)
}

class SelectNetworkViewController: KNBaseViewController {
  let transitor = TransitionDelegate()
  @IBOutlet weak var contentViewTopContraint: NSLayoutConstraint!
  @IBOutlet weak var contentView: UIView!
  @IBOutlet weak var tableView: UITableView!
  @IBOutlet weak var outSideBackgroundView: UIView!
  weak var delegate: SelectNetworkViewControllerDelegate?
  init() {
    super.init(nibName: SelectNetworkViewController.className, bundle: nil)
    self.modalPresentationStyle = .custom
    self.transitioningDelegate = transitor
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.setupUI()
  }
  
  func setupUI() {
    let nib = UINib(nibName: SelectNetworkCell.className, bundle: nil)
    self.tableView.register(nib, forCellReuseIdentifier: SelectNetworkCell.kSelectNetworkCellID)
    self.tableView.rowHeight = 52
    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapOutside))
    self.outSideBackgroundView.addGestureRecognizer(tapGesture)
  }
  
  @objc func tapOutside() {
    self.dismiss(animated: true, completion: nil)
  }
}

extension SelectNetworkViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return 6
  }

  private func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
    return UIView()
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: SelectNetworkCell.kSelectNetworkCellID, for: indexPath) as! SelectNetworkCell
    
    switch indexPath.row {
    case 0:
      cell.iconImageView.image = UIImage(named: "chain_eth_icon")
      cell.nameLabel.text = "Ethereum"
    case 1:
      cell.iconImageView.image = UIImage(named: "chain_bsc_big_icon")
      cell.nameLabel.text = "Binance Smart Chain (BSC)"
    case 2:
      cell.iconImageView.image = UIImage(named: "chain_polygon_big_icon")
      cell.nameLabel.text = "Polygon (Matic)"
    case 3:
      cell.iconImageView.image = UIImage(named: "chain_avax_icon")
      cell.nameLabel.text = "Avalanche"
    case 4:
      cell.iconImageView.image = UIImage(named: "chain_fantom_icon")
      cell.nameLabel.text = "Fantom"
    default:
      cell.iconImageView.image = UIImage(named: "chain_cronos_icon")
      cell.nameLabel.text = "Cronos"
    }
    return cell
  }
}

extension SelectNetworkViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    switch indexPath.row {
    case 0:
        self.delegate?.didSelectNetwork(chain: "ETH")
    case 1:
        self.delegate?.didSelectNetwork(chain: "Binance Smart Chain (BSC)")
    case 2:
        self.delegate?.didSelectNetwork(chain: "Polygon (Matic)")
    case 3:
        self.delegate?.didSelectNetwork(chain: "Avalanche")
    case 4:
        self.delegate?.didSelectNetwork(chain: "Fantom")
    default:
        self.delegate?.didSelectNetwork(chain: "Cronos")
    }
    self.dismiss(animated: true, completion: nil)
  }
}

extension SelectNetworkViewController: BottomPopUpAbstract {
  func setTopContrainConstant(value: CGFloat) {
    self.contentViewTopContraint.constant = value
  }

  func getPopupHeight() -> CGFloat {
    return 450
  }

  func getPopupContentView() -> UIView {
    return self.contentView
  }
}
