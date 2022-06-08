//
//  SwitchChainViewController.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 5/21/21.
//

import UIKit

class SwitchChainViewController: KNBaseViewController {
  @IBOutlet weak var contentViewTopContraint: NSLayoutConstraint!
  @IBOutlet weak var contentView: UIView!
  @IBOutlet weak var tableView: UITableView!
  @IBOutlet weak var nextButton: UIButton!
  @IBOutlet weak var cancelButton: UIButton!
  @IBOutlet weak var outsideBackgroundView: UIView!
  let transitor = TransitionDelegate()
  var dataSource:[ChainType] = []
  var nextButtonTitle: String = "Next"
  var selectedChain: ChainType
  var completionHandler: (ChainType) -> Void = { selected in }

  init() {
    self.selectedChain = KNGeneralProvider.shared.currentChain
    super.init(nibName: SwitchChainViewController.className, bundle: nil)
    self.modalPresentationStyle = .custom
    self.transitioningDelegate = transitor
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.initializeData()
    self.setupUI()
  }
  
  func setupUI() {
    self.updateSelectedChainUI()
    self.cancelButton.rounded(radius: 16)
    self.nextButton.rounded(radius: 16)
    self.nextButton.setTitle(self.nextButtonTitle, for: .normal)
    self.tableView.registerCellNib(SwitchChainCell.self)
    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapOutside))
    self.outsideBackgroundView.addGestureRecognizer(tapGesture)
  }

  func initializeData() {
    if self.dataSource.isEmpty {
      self.dataSource = ChainType.getAllChain()
    }
  }

  fileprivate func updateSelectedChainUI() {
    let enableNextButton = self.selectedChain != KNGeneralProvider.shared.currentChain
    self.nextButton.isEnabled = enableNextButton
    self.nextButton.alpha = enableNextButton ? 1.0 : 0.5
  }

  @IBAction func nextButtonTapped(_ sender: UIButton) {
    self.dismiss(animated: true, completion: {
      self.completionHandler(self.selectedChain)
    })
  }

  @IBAction func cancelButtonTapped(_ sender: UIButton) {
    self.dismiss(animated: true, completion: nil)
  }

  @objc func tapOutside() {
    self.dismiss(animated: true, completion: nil)
  }
}

extension SwitchChainViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.dataSource.count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(SwitchChainCell.self, indexPath: indexPath)!
    let chain = self.dataSource[indexPath.row]
    cell.configCell(chain: chain, isSelected: self.selectedChain == chain)
    return cell
  }
}

extension SwitchChainViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let chain = self.dataSource[indexPath.row]
    self.selectedChain = chain
    self.updateSelectedChainUI()
    self.tableView.reloadData()
  }
}

extension SwitchChainViewController: BottomPopUpAbstract {
  func setTopContrainConstant(value: CGFloat) {
    self.contentViewTopContraint.constant = value
  }

  func getPopupHeight() -> CGFloat {
    return 601
  }

  func getPopupContentView() -> UIView {
    return self.contentView
  }
}
