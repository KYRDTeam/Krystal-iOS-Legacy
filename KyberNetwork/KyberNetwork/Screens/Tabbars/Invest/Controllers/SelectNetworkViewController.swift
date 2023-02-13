//
//  SelectNetworkViewController.swift
//  KyberNetwork
//
//  Created by Com1 on 04/03/2022.
//

import UIKit

protocol SelectNetworkViewControllerDelegate: class {
  func didSelectNetwork(network: FiatNetwork)
}

class SelectNetworkViewModel {
  var networks: [FiatNetwork]
  init(networks: [FiatNetwork]) {
    self.networks = networks
  }
}

class SelectNetworkViewController: KNBaseViewController {
  let transitor = TransitionDelegate()
  @IBOutlet weak var contentViewTopContraint: NSLayoutConstraint!
  @IBOutlet weak var contentView: UIView!
  @IBOutlet weak var tableView: UITableView!
  @IBOutlet weak var outSideBackgroundView: UIView!
  weak var delegate: SelectNetworkViewControllerDelegate?
  var viewModel: SelectNetworkViewModel
  init(viewModel: SelectNetworkViewModel) {
    self.viewModel = viewModel
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
    return self.viewModel.networks.count
  }

  func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
    return UIView()
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: SelectNetworkCell.kSelectNetworkCellID, for: indexPath) as! SelectNetworkCell
    
    let model = self.viewModel.networks[indexPath.row]
    cell.iconImageView.setImage(with: model.logo, placeholder: UIImage(named: "default_token"))
    cell.nameLabel.text = model.name
    return cell
  }
}

extension SelectNetworkViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let model = self.viewModel.networks[indexPath.row]
    self.delegate?.didSelectNetwork(network: model)
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
