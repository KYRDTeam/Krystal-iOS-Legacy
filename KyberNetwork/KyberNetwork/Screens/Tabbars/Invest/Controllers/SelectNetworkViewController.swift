//
//  SelectNetworkViewController.swift
//  KyberNetwork
//
//  Created by Com1 on 04/03/2022.
//

import UIKit

class SelectNetworkViewController: KNBaseViewController {
  let transitor = TransitionDelegate()
  @IBOutlet weak var contentViewTopContraint: NSLayoutConstraint!
  @IBOutlet weak var contentView: UIView!
  @IBOutlet weak var tableView: UITableView!
  @IBOutlet weak var outSideBackgroundView: UIView!

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
    self.tableView.rowHeight = 40
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
//    if let dataSource = self.viewModel.displayDataSource {
//      let model = dataSource[indexPath.row]
//      cell.updateUI(model: model)
//    }
    return cell
  }
}

extension SelectNetworkViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

  }
}

extension SelectNetworkViewController: BottomPopUpAbstract {
  func setTopContrainConstant(value: CGFloat) {
    self.contentViewTopContraint.constant = value
  }

  func getPopupHeight() -> CGFloat {
    return 500
  }

  func getPopupContentView() -> UIView {
    return self.contentView
  }
}
