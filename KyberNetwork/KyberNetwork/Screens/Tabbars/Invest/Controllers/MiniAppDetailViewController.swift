//
//  MiniAppDetailViewController.swift
//  KyberNetwork
//
//  Created by Com1 on 24/05/2022.
//

import UIKit
import Moya

class MiniAppDetailViewController: KNBaseViewController {
  @IBOutlet weak var fiveStarButton: UIButton!
  @IBOutlet weak var fourStarButton: UIButton!
  @IBOutlet weak var threeStarButton: UIButton!
  @IBOutlet weak var twoStarButton: UIButton!
  @IBOutlet weak var oneStarButton: UIButton!
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var reviewsLabel: UILabel!
  @IBOutlet weak var nameLabel: UILabel!
  @IBOutlet weak var icon: UIImageView!
  @IBOutlet weak var detailLabel: UILabel!
  @IBOutlet weak var chainLabel: UILabel!
  @IBOutlet weak var favoriteButton: UIButton!
  var currentMiniApp: MiniApp
  var isFavorite: Bool = false
  var favoriteData: [String: Bool]? = UserDefaults.standard.value(forKey: "MiniAppData") as? [String: Bool]
  init(miniApp: MiniApp) {
    self.currentMiniApp = miniApp
    super.init(nibName: MiniAppDetailViewController.className, bundle: nil)
    self.modalPresentationStyle = .custom
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.titleLabel.text = self.currentMiniApp.category
    self.nameLabel.text = self.currentMiniApp.name
    if let url = URL(string: self.currentMiniApp.icon) {
      self.icon.setImage(with: url, placeholder: nil)
    }
    self.reviewsLabel.text = "\(self.currentMiniApp.numberOfReviews) Ratings"
    self.chainLabel.text = "Available on: \(self.currentMiniApp.chains)"
    self.detailLabel.text = self.currentMiniApp.description
    
    let rate = self.currentMiniApp.rating
    self.updateRateUI(rate: rate)
    self.favoriteButton.setImage(self.isFavorite ? UIImage(named: "heart_icon_red") : UIImage(named: "heart_icon"), for: .normal)
    
    if let favoriteData = self.favoriteData, let favorite = favoriteData[self.currentMiniApp.url], favorite == true {
      self.favoriteButton.setImage(UIImage(named: "heart_icon_red"), for: .normal)
    } else {
      self.favoriteButton.setImage(UIImage(named: "heart_icon"), for: .normal)
    }
  }
  
  func updateRateUI(rate: Double) {
    self.oneStarButton.configStarRate(isHighlight: rate >= 0.5)
    self.twoStarButton.configStarRate(isHighlight: rate >= 1.5)
    self.threeStarButton.configStarRate(isHighlight: rate >= 2.5)
    self.fourStarButton.configStarRate(isHighlight: rate >= 3.5)
    self.fiveStarButton.configStarRate(isHighlight: rate >= 4.5)
  }

  @IBAction func favoriteButtonTapped(_ sender: Any) {
    self.isFavorite = !self.isFavorite
    if var favoriteData = self.favoriteData {
      favoriteData[self.currentMiniApp.url] = self.isFavorite
      UserDefaults.standard.set(favoriteData, forKey: "MiniAppData")
    }
    self.favoriteButton.setImage(self.isFavorite ? UIImage(named: "heart_icon_red") : UIImage(named: "heart_icon"), for: .normal)
    if self.isFavorite {
      let provider = MoyaProvider<KrytalService>(plugins: [NetworkLoggerPlugin(verbose: true)])
      self.showLoadingHUD()
      provider.request(.addFavorite(address: "0x8D61aB7571b117644A52240456DF66EF846cd999", url: self.currentMiniApp.url)) { (result) in
        DispatchQueue.main.async {
          self.hideLoading()
        }
        if case .success(let resp) = result {
          print("Success")
        } else {
          print("Error")
        }
      }
    }
  }
  
  @IBAction func backButtonTapped(_ sender: Any) {
    self.navigationController?.popViewController(animated: true)
  }

  @IBAction func onOpenDappTapped(_ sender: Any) {
    if let url = URL(string: self.currentMiniApp.url) {
      self.navigationController?.openSafari(with: url)
    }
  }
  
  @IBAction func rateButtonTapped(_ sender: UIButton) {
    self.updateRateUI(rate: Double(sender.tag))
    let vc = RateTransactionPopupViewController(currentRate: sender.tag, txHash: "")
    vc.delegate = self
    self.present(vc, animated: true, completion: nil)
  }
}

extension MiniAppDetailViewController: RateTransactionPopupDelegate {
  func didUpdateRate(rate: Int) {
    
  }

  func didSendRate() {
    
  }
  
  func didSendRate(rate: Int, comment: String) {
    let provider = MoyaProvider<KrytalService>(plugins: [NetworkLoggerPlugin(verbose: true)])
    self.showLoadingHUD()
    provider.request(.addReview(address: "0x8D61aB7571b117644A52240456DF66EF846cd999", url: self.currentMiniApp.url, rating: Double(rate), comment: comment)) { (result) in
      DispatchQueue.main.async {
        self.hideLoading()
      }
      if case .success(let resp) = result {
        print("Success")
      } else {
        print("Error")
      }
    }
  }
}
