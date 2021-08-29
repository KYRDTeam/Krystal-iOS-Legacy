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
    return ["#\(self.item.tokenID)", self.item.externalData.name]
  }
  
  var description: String {
    return self.item.externalData.externalDataDescription
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
    
    
    self.titleLabel.text = self.viewModel.title
    self.subTitleLabel.text = self.viewModel.title
    self.tagView.addTags(self.viewModel.tags)
    self.descriptionLabel.text = self.viewModel.description
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    self.assetImageView.setImage(with: self.viewModel.iconURL, placeholder: nil, fitSize: self.assetImageView.frame.size)
  }
  
  @IBAction func tranferButtonTapped(_ sender: UIButton) {
    self.delegate?.overviewNFTDetailViewController(self, run: .sendItem(item: self.viewModel.item, category: self.viewModel.category))
  }
  
  @IBAction func linkButtonTapped(_ sender: UIButton) {
  }
  
  @IBAction func shareButtonTapped(_ sender: UIButton) {
    let viewModel = OverviewShareNFTViewModel(item: self.viewModel.item, category: self.viewModel.category.collectibleName)
    let vc = OverviewShareNFTViewController(viewModel: viewModel)
    self.navigationController?.pushViewController(vc, animated: true)
  }
  
  @IBAction func backButtonTapped(_ sender: UIButton) {
    self.navigationController?.popViewController(animated: true)
  }
}
