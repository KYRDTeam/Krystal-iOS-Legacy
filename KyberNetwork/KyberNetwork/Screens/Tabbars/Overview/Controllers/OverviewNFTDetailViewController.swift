//
//  OverviewNFTDetailViewController.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 20/08/2021.
//

import UIKit
import TagListView

enum OverviewNFTDetailEvent {
  case sendItem(item: NFTItem, category: NFTSection)
  case favoriteItem(item: NFTItem, category: NFTSection, status: Bool)
}

struct OverviewNFTDetailViewModel {
  let item: NFTItem
  let category: NFTSection
  
  var iconURL: String {
    return self.item.externalData.image
  }
  
  var title: String {
    return self.item.externalData.name
  }
  
  var tags: [String] {
    var result = ["#\(self.item.tokenID)"]
    if !self.item.externalData.name.isEmpty {
      result.append(self.item.externalData.name)
    }
    return result
  }
  
  var description: String {
    return self.item.externalData.externalDataDescription
  }
  
  var isFaved: Bool {
    return self.item.favorite
  }
  
  var displayFavStatusImage: UIImage? {
    return self.isFaved ? UIImage(named: "fav_star_icon") : UIImage(named: "unFav_star_icon")
  }
  
  var subTitle: String {
    return self.category.collectibleName
  }
}

protocol OverviewNFTDetailViewControllerDelegate: class {
  func overviewNFTDetailViewController(_ controller: OverviewNFTDetailViewController, run event: OverviewNFTDetailEvent)
}

class OverviewNFTDetailViewController: KNBaseViewController {
  
  @IBOutlet weak var assetImageView: UIImageView!
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var subTitleLabel: UILabel!
  @IBOutlet weak var tagView: TagListView!
  @IBOutlet weak var descriptionLabel: UILabel!
  @IBOutlet weak var favButton: UIButton!
  var isLoadedImage: Bool = false
  
  let viewModel: OverviewNFTDetailViewModel
  weak var delegate: OverviewNFTDetailViewControllerDelegate?
  
  init(viewModel: OverviewNFTDetailViewModel) {
    self.viewModel = viewModel
    super.init(nibName: OverviewNFTDetailViewController.className, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    //trick fix
    KNGeneralProvider.shared.getDecimalsEncodeData { result in
    }
    self.titleLabel.text = self.viewModel.title
    self.subTitleLabel.text = self.viewModel.subTitle
    self.tagView.addTags(self.viewModel.tags)
    self.descriptionLabel.text = self.viewModel.description
    self.favButton.setImage(self.viewModel.displayFavStatusImage, for: .normal)
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    if !self.isLoadedImage {
      self.assetImageView.setImage(with: self.viewModel.iconURL, placeholder: UIImage(named: "placeholder_nft_item")!, fitSize: self.assetImageView.frame.size)
      self.isLoadedImage = true
    }
    
  }
  
  func coordinatorDidUpdateFavStatus(_ status: Bool) {
    self.viewModel.item.favorite = status
    self.favButton.setImage(self.viewModel.displayFavStatusImage, for: .normal)
  }
  
  @IBAction func tranferButtonTapped(_ sender: UIButton) {
    guard self.viewModel.category.chainType == KNGeneralProvider.shared.currentChain else {
      if let chain = self.viewModel.category.chainType {
        self.showSwitchChainAlert(chain)
      }
      
      return
    }
    self.delegate?.overviewNFTDetailViewController(self, run: .sendItem(item: self.viewModel.item, category: self.viewModel.category))
  }
  
  @IBAction func linkButtonTapped(_ sender: UIButton) {
    let viewModel = OverviewShareNFTViewModel(item: self.viewModel.item, category: self.viewModel.category.collectibleName)
    let vc = OverviewShareNFTViewController(viewModel: viewModel)
    self.navigationController?.pushViewController(vc, animated: true)
  }
  
  @IBAction func shareButtonTapped(_ sender: UIButton) {
    self.navigationController?.openSafari(with: "https://defi.krystal.app/nft?collectibleAddress=\(self.viewModel.category.collectibleAddress)&tokenID=\(self.viewModel.item.tokenID)?chainId=\(self.viewModel.category.chainType?.customRPC().chainID ?? 1)")
  }
  
  @IBAction func backButtonTapped(_ sender: UIButton) {
    self.navigationController?.popViewController(animated: true)
  }
  
  @IBAction func favoriteButtonTapped(_ sender: UIButton) {
    self.delegate?.overviewNFTDetailViewController(self, run: .favoriteItem(item: self.viewModel.item, category: self.viewModel.category, status: !self.viewModel.isFaved))
    MixPanelManager.track("nft_detail_favourite", properties: ["screenid": "nft_detail"])
  }
  
  @IBAction func etherscanButtonTapped(_ sender: UIButton) {
    self.navigationController?.openSafari(with: "\(self.viewModel.category.chainType?.customRPC().etherScanEndpoint ?? "")address/\(self.viewModel.category.collectibleAddress)")
  }
}
