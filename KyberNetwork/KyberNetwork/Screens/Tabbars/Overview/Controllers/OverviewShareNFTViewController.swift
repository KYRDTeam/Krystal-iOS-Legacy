//
//  OverviewShareNFTViewController.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 23/08/2021.
//

import UIKit

struct OverviewShareNFTViewModel {
  let item: NFTItem
  let category: String
  
  var iconURL: String {
    return self.item.externalData.image
  }
  
  var name: String {
    return self.item.externalData.name
  }
}

class OverviewShareNFTViewController: KNBaseViewController {
  
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var assetImageView: UIImageView!
  @IBOutlet weak var nameLabel: UILabel!
  @IBOutlet weak var subNameLabel: UILabel!
  @IBOutlet weak var assetContainer: UIView!
  @IBOutlet weak var imageContainer: UIView!
  
  
  let viewModel: OverviewShareNFTViewModel
  
  init(viewModel: OverviewShareNFTViewModel) {
    self.viewModel = viewModel
    super.init(nibName: OverviewShareNFTViewController.className, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.titleLabel.text = self.viewModel.name
    self.nameLabel.text = self.viewModel.name
    self.subNameLabel.text = self.viewModel.category
    self.imageContainer.backgroundColor = UIColor(patternImage: UIImage(named: "background_share_nft")!)
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    self.assetImageView.setImage(with: self.viewModel.iconURL, placeholder: UIImage(named: "placeholder_nft_item")!, fitSize: self.assetImageView.frame.size)
  }
  
  @IBAction func backButtonTapped(_ sender: UIButton) {
    self.navigationController?.popViewController(animated: true)
  }
  
  @IBAction func downloadButtonTapped(_ sender: UIButton) {
    if let image = self.assetContainer.toImage() {
      UIImageWriteToSavedPhotosAlbum(image, self, #selector(OverviewShareNFTViewController.image(image:didFinishSavingWithError:contextInfo:)), nil);
    }
  }

  @IBAction func shareButtonTapped(_ sender: UIButton) {
    if let image = self.assetContainer.toImage() {
      let activityViewController = UIActivityViewController(activityItems: [image], applicationActivities: nil)
      activityViewController.popoverPresentationController?.sourceView = self.view
      self.present(activityViewController, animated: true, completion: nil)
    }
    
  }

  @objc func image(image: UIImage, didFinishSavingWithError error: NSError?, contextInfo:UnsafePointer<Void>) {
    guard error == nil else {
      self.showErrorTopBannerMessage()
      return
    }
    self.showTopBannerView(message: "Image saved")
  }
}
