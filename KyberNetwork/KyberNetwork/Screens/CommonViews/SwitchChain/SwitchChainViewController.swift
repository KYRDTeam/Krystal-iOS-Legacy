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
  @IBOutlet weak var outsideBackgroundView: UIView!
  let transitor = TransitionDelegate()
  var dataSource: [ChainType] = []
  var nextButtonTitle: String = "Next"
  var selectedChain: ChainType
  var currentChain: ChainType
  var completionHandler: (ChainType) -> Void = { selected in }
  let isIncludedAllOption: Bool
  
  var displayingChains: [ChainType] {
    if dataSource.isEmpty {
      return ChainType.getAllChain(includeAll: self.isIncludedAllOption)
    } else if let chain = dataSource.first, chain == .all {
        return ChainType.getAllChain(includeAll: self.isIncludedAllOption)
    }
    return dataSource
  }

  init(includedAll: Bool = false, selected: ChainType = KNGeneralProvider.shared.currentChain) {
    self.isIncludedAllOption = includedAll
    self.selectedChain = selected
    self.currentChain = selected
    super.init(nibName: SwitchChainViewController.className, bundle: nil)
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
    self.tableView.registerCellNib(SwitchChainCell.self)
    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapOutside))
    self.outsideBackgroundView.addGestureRecognizer(tapGesture)
  }

  @objc func tapOutside() {
    self.dismiss(animated: true, completion: nil)
  }
}

extension SwitchChainViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.displayingChains.count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(SwitchChainCell.self, indexPath: indexPath)!
    let chain = self.displayingChains[indexPath.row]
    cell.configCell(chain: chain, isSelected: self.selectedChain == chain)
    return cell
  }
}

extension SwitchChainViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let chain = self.displayingChains[indexPath.row]
    self.selectedChain = chain
    self.tableView.reloadData()
    DispatchQueue.main.async {
      self.dismiss(animated: true, completion: {
        self.completionHandler(self.selectedChain)
      })
    }
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
