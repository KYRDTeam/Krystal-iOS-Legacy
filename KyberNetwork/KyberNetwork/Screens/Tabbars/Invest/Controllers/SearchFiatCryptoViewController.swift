//
//  SearchFiatCryptoViewController.swift
//  KyberNetwork
//
//  Created by Com1 on 03/03/2022.
//

import UIKit
import BaseModule

protocol SearchFiatCryptoViewControllerDelegate: class {
  func didSelectCurrency(currency: FiatModel, type: SearchCurrencyType)
}

enum SearchCurrencyType {
  case fiat
  case crypto
}

class SearchFiatCryptoViewModel {
  let currencyType: SearchCurrencyType
  let dataSource: [FiatModel]?
  var displayDataSource: [FiatModel]?
  var searchedText: String = "" {
    didSet {
      if self.searchedText.isEmpty {
        self.displayDataSource = self.dataSource
      } else {
        var filteredDataSource: [FiatModel] = []
        self.dataSource?.forEach({ model in
          if model.currency.lowercased().contains(self.searchedText.lowercased()) {
            filteredDataSource.append(model)
          }
        })
        self.displayDataSource = filteredDataSource
      }
    }
  }
  init(dataSource: [FiatModel], currencyType: SearchCurrencyType) {
    self.dataSource = dataSource
    self.currencyType = currencyType
  }
  
  func numberOfRows() -> Int {
    guard let displayDataSource = self.displayDataSource else {
      return 0
    }
    return displayDataSource.count
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

  weak var delegate: SearchFiatCryptoViewControllerDelegate?
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
    self.dismiss(animated: true, completion: nil)
  }

  fileprivate func searchTextDidChange(_ newText: String) {
    self.viewModel.searchedText = newText
    self.tableView.reloadData()
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

  func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
    return UIView()
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: CryptoFiatCell.kCryptoFiatCellID, for: indexPath) as! CryptoFiatCell
    if let dataSource = self.viewModel.displayDataSource {
      let model = dataSource[indexPath.row]
      cell.updateUI(model: model)
    }
    return cell
  }
}

extension SearchFiatCryptoViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    if let dataSource = self.viewModel.displayDataSource {
      let model = dataSource[indexPath.row]
      self.delegate?.didSelectCurrency(currency: model, type: self.viewModel.currencyType)
      self.dismiss(animated: true, completion: nil)
    }
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
