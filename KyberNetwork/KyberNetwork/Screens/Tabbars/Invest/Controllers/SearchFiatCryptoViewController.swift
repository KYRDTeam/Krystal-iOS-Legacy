//
//  SearchFiatCryptoViewController.swift
//  KyberNetwork
//
//  Created by Com1 on 03/03/2022.
//

import UIKit

class SearchFiatCryptoViewModel {
  let dataSource: [FiatModel]?
  init(dataSource:[FiatModel]) {
    self.dataSource = dataSource
  }
  
  func numberOfRows() -> Int {
    guard let dataSource = dataSource else {
      return 0
    }
    return dataSource.count
  }
}

class SearchFiatCryptoViewController: KNBaseViewController {
  let transitor = TransitionDelegate()
  @IBOutlet weak var contentViewTopContraint: NSLayoutConstraint!
  @IBOutlet weak var contentView: UIView!
  @IBOutlet weak var tableView: UITableView!
  @IBOutlet weak var searchTextField: UITextField!
  @IBOutlet weak var noMatchingLabel: UILabel!
  @IBOutlet weak var outSideBackgroundView: UIView!

  let viewModel: SearchFiatCryptoViewModel
  override func viewDidLoad() {
    super.viewDidLoad()
    self.setupUI()
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    self.searchTextField.text = ""
    self.searchTextDidChange("")
  }
  
  init(viewModel: SearchFiatCryptoViewModel) {
    self.viewModel = viewModel
    super.init(nibName: SearchFiatCryptoViewController.className, bundle: nil)
    self.modalPresentationStyle = .custom
    self.transitioningDelegate = transitor
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  func setupUI() {
    let nib = UINib(nibName: CryptoFiatCell.className, bundle: nil)
    self.tableView.register(nib, forCellReuseIdentifier: CryptoFiatCell.kCryptoFiatCellID)
    self.tableView.rowHeight = 40
    self.noMatchingLabel.isHidden = true
    self.searchTextField.delegate = self
    self.searchTextField.setPlaceholder(text: "Search name".toBeLocalised(), color: UIColor(named: "normalTextColor")!)
    self.searchTextField.autocorrectionType = .no
    self.searchTextField.textContentType = .name
    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapOutside))
    self.outSideBackgroundView.addGestureRecognizer(tapGesture)
  }
  
  @objc func tapOutside() {
    self.dismiss(animated: true, completion:nil)
  }
  
  fileprivate func searchTextDidChange(_ newText: String) {
//    self.viewModel.searchedText = newText
//    self.updateUIDisplayedDataDidChange()
//    self.requestTokenInfoIfNeeded()
  }

}

extension SearchFiatCryptoViewController: UITextFieldDelegate {
  func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
    let text = ((textField.text ?? "") as NSString).replacingCharacters(in: range, with: string)
    textField.text = text
    self.searchTextDidChange(text)
    return false
  }
}

extension SearchFiatCryptoViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.viewModel.numberOfRows()
  }

  private func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
    return UIView()
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: CryptoFiatCell.kCryptoFiatCellID, for: indexPath) as! CryptoFiatCell
    if let dataSource = self.viewModel.dataSource {
      let model = dataSource[indexPath.row]
      cell.updateUI(model: model)
    }
    return cell
  }
}

extension SearchFiatCryptoViewController: BottomPopUpAbstract {
  func setTopContrainConstant(value: CGFloat) {
    self.contentViewTopContraint.constant = value
  }

  func getPopupHeight() -> CGFloat {
    return 550
  }

  func getPopupContentView() -> UIView {
    return self.contentView
  }
}
