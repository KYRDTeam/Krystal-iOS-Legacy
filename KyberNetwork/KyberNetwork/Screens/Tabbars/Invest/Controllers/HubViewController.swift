//
//  HubViewController.swift
//  KyberNetwork
//
//  Created by Com1 on 23/05/2022.
//

import UIKit
import Moya

let FEATURE_CATEGORY = "Feature"

protocol HubViewControllerDelegate: class {
  func dAppCoordinatorDidSelectAddWallet()
  func dAppCoordinatorDidSelectWallet(_ wallet: Wallet)
  func dAppCoordinatorDidSelectManageWallet()
  func dAppCoordinatorDidSelectAddChainWallet(chainType: ChainType)
}

class HubViewController: KNBaseViewController {
  @IBOutlet weak var searchViewLeading: NSLayoutConstraint!
  @IBOutlet weak var tableView: UITableView!
  @IBOutlet weak var searchTextField: UITextField!
  @IBOutlet weak var backButton: UIButton!
  weak var delegate: HubViewControllerDelegate?
  var session: KNSession
  var isSearching: Bool = false
  var dataSource: [MiniApp] = []
  var displayDataSource: [MiniApp] = []
  var category: [String] = []
  
  init(session: KNSession) {
    self.session = session
    super.init(nibName: HubViewController.className, bundle: nil)
    self.modalPresentationStyle = .custom
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.tableView.delegate = self
    self.tableView.registerCellNib(MiniAppsCell.self)
    self.tableView.registerCellNib(MiniAppDetailCell.self)
    self.searchTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    self.getData()
  }
  
  @objc func textFieldDidChange(_ textField: UITextField) {
    let keyword = textField.text
    self.displayDataSource = self.dataSource.filter { element in
      if let keyword = keyword {
        return element.name.lowercased().contains(keyword.lowercased())
      } else {
        return true
      }
    }
    self.tableView.reloadData()
  }
  
  @IBAction func backButtonTapped(_ sender: Any) {
    self.searchTextField.text = ""
    self.view.endEditing(true)
    self.searchViewLeading.constant = 40
    self.backButton.isHidden = true
    self.isSearching = false
    self.displayDataSource = self.dataSource
    self.tableView.reloadData()
  }
}

extension HubViewController: UITextFieldDelegate {
  func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
    self.isSearching = true
    self.tableView.reloadData()
    self.searchViewLeading.constant = 80
    self.backButton.isHidden = false
    return true
  }
}

extension HubViewController: UITableViewDataSource {
  func numberOfSections(in tableView: UITableView) -> Int {
    return self.isSearching ? 1 : self.category.count + 1
  }
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.isSearching ? self.displayDataSource.count : 1
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    if self.isSearching {
      return self.searchingCell(indexPath: indexPath)
    } else {
      return self.normalCell(indexPath: indexPath)
    }
  }
  
  func searchingCell(indexPath: IndexPath) -> UITableViewCell {
    let cell = self.tableView.dequeueReusableCell(MiniAppDetailCell.self, indexPath: indexPath)!
    let miniApp = self.displayDataSource[indexPath.row]
    cell.titleLabel.text = miniApp.name
    if let url = URL(string: miniApp.icon) {
      cell.icon.setImage(with: url, placeholder: nil)
    }
    
    return cell
  }
  
  func normalCell(indexPath: IndexPath) -> UITableViewCell {
    let cell = self.tableView.dequeueReusableCell(MiniAppsCell.self, indexPath: indexPath)!
    cell.isSpecialApp = indexPath.section == 0
    cell.selectCompletion = { miniApp in
      let detailVC = MiniAppDetailViewController(miniApp: miniApp, session: self.session)
      detailVC.delegate = self
      self.navigationController?.show(detailVC, sender: nil)
    }
    if indexPath.section == 0 {
      let miniApps = self.displayDataSource.filter { $0.category == FEATURE_CATEGORY }
      cell.dataSource = miniApps
    } else {
      let category = self.category[indexPath.section - 1]
      let miniApps = self.displayDataSource.filter { $0.category == category }
      cell.dataSource = miniApps
    }
    
    cell.collectionView.reloadData()
    return cell
  }
}

extension HubViewController: UITableViewDelegate {
  
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    if self.isSearching {
      let miniApp = self.displayDataSource[indexPath.row]
      let detailVC = MiniAppDetailViewController(miniApp: miniApp, session: self.session)
      detailVC.delegate = self
      self.navigationController?.show(detailVC, sender: nil)
    }
  }
  
  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    if self.isSearching {
      return 76
    } else {
      return indexPath.section == 0 ? 220 : 156
    }
  }
  func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    return self.isSearching ? 0.01 : 50
  }
  
  func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
    return CGFloat(0.01)
  }
  
  func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    if self.isSearching {
      return nil
    }
    let view = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 50))
    
    let title = section == 0 ? FEATURE_CATEGORY : self.category[section - 1]
    let titleLabel = UILabel(frame: CGRect(x: 18, y: 18, width: UIScreen.main.bounds.size.width - 130, height: 24))
    titleLabel.text = title
    titleLabel.textColor = UIColor(named: "textWhiteColor")!
    titleLabel.font = UIFont.Kyber.bold(with: 18)
    view.addSubview(titleLabel)
    
    let detailButton = UIButton(frame: CGRect(x: UIScreen.main.bounds.size.width - 65, y: 20, width: 65, height: 20))
    detailButton.setTitle("See all", for: .normal)
    detailButton.setTitleColor(UIColor(named: "buttonBackgroundColor")!, for: .normal)
    detailButton.titleLabel?.font = UIFont.Kyber.bold(with: 14)
    detailButton.tag = section
    detailButton.addTarget(self, action: #selector(seeAllButtonTapped(_:)), for: .touchUpInside)
    view.addSubview(detailButton)
    
    view.backgroundColor = UIColor(named: "mainViewBgColor")!
    return view
  }
  
  @objc func seeAllButtonTapped(_ sender: UIButton) {
    var data: [MiniApp] = []
    if sender.tag == 0 {
      
    } else {
      let category = self.category[sender.tag - 1]
      data = self.dataSource.filter { $0.category == category }
      
    }
    let detailVC = MiniAppListController(dataSource: data, session: self.session)
    detailVC.delegate = self
    self.navigationController?.show(detailVC, sender: nil)
  }
}

extension HubViewController: MiniAppListControllerDelegate {
  func didSelectAddWallet() {
    self.delegate?.dAppCoordinatorDidSelectAddWallet()
  }
  
  func didSelectWallet(_ wallet: Wallet) {
    self.delegate?.dAppCoordinatorDidSelectWallet(wallet)
  }
  
  func didSelectManageWallet() {
    self.delegate?.dAppCoordinatorDidSelectManageWallet()
  }
  
  func didSelectAddChainWallet(chainType: ChainType) {
    self.delegate?.dAppCoordinatorDidSelectAddChainWallet(chainType: chainType)
  }
}

extension HubViewController: MiniAppDetailDelegate {
  func dAppCoordinatorDidSelectAddWallet() {
    self.delegate?.dAppCoordinatorDidSelectAddWallet()
  }
  
  func dAppCoordinatorDidSelectWallet(_ wallet: Wallet) {
    self.delegate?.dAppCoordinatorDidSelectWallet(wallet)
  }
  
  func dAppCoordinatorDidSelectManageWallet() {
    self.delegate?.dAppCoordinatorDidSelectManageWallet()
  }
  
  func dAppCoordinatorDidSelectAddChainWallet(chainType: ChainType) {
    self.delegate?.dAppCoordinatorDidSelectAddChainWallet(chainType: chainType)
  }
}

extension HubViewController {
  func getData() {
    let provider = MoyaProvider<KrytalService>(plugins: [NetworkLoggerPlugin(verbose: true)])
    self.showLoadingHUD()
    provider.request(.getDappList) { (result) in
      self.hideLoading()
      switch result {
      case .success(let resp):
        let decoder = JSONDecoder()
        do {
          let data = try decoder.decode(MiniAppResponse.self, from: resp.data)
          self.category = []
          self.dataSource = []
          data.dapps.forEach { miniApp in
            if !self.category.contains(miniApp.category) && miniApp.category != FEATURE_CATEGORY {
              self.category.append(miniApp.category)
            }
            self.dataSource.append(miniApp)
          }
          self.displayDataSource = self.dataSource
          self.tableView.reloadData()
        } catch let error {
          print("[Krytal] \(error.localizedDescription)")
        }
      case .failure(let error):
        print("[Krytal] \(error.localizedDescription)")
      }
    }
  }
}

struct MiniAppResponse: Codable {
    let dapps: [MiniApp]
}

struct MiniApp: Codable {
  let url: String
  let icon: String
  let name: String
  let chains: String
  let description: String
  let category: String
  let rating: Double
  let numberOfReviews: Int
  let numberOfFavourites: Int
  let socialLinks: [String: String]
  let status: String
}
