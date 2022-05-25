//
//  SubmitAppViewController.swift
//  KyberNetwork
//
//  Created by Nguyen Tung on 25/05/2022.
//

import UIKit

struct DappInfo {
  var image: UIImage? = nil
  var name: String = ""
  var category: String = ""
  var website: String = ""
  var shorDescription: String = ""
  var tags: String = ""
  var protocols: [String] = []
}

class SubmitAppViewController: UIViewController {
  @IBOutlet weak var imageButton: UIButton!
  @IBOutlet weak var nameField: UITextField!
  @IBOutlet weak var categoryField: UITextField!
  @IBOutlet weak var websiteField: UITextField!
  @IBOutlet weak var shortDescriptionLabel: UITextField!
  @IBOutlet weak var tagsField: UITextField!
  @IBOutlet weak var protocolsLabel: UILabel!
  
  var imagePicker: ImagePicker!
  var appInfo: DappInfo = .init()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    imagePicker = ImagePicker(presentationController: self, delegate: self)
    
    navigationController?.setNavigationBarHidden(true, animated: true)
    
    let protocolTap = UITapGestureRecognizer(target: self, action: #selector(selectProtocols))
    protocolsLabel.isUserInteractionEnabled = true
    protocolsLabel.addGestureRecognizer(protocolTap)
  }
  
  @objc func selectProtocols() {
    let vc = SelectDAppViewController.instantiateFromNib()
    vc.didSelect = { [weak self] chains in
      self?.appInfo.protocols = chains
      self?.protocolsLabel.text = chains.joined(separator: "\n")
    }
    vc.selectedChains = Set(appInfo.protocols)
    vc.hidesBottomBarWhenPushed = true
    navigationController?.pushViewController(vc, animated: true)
  }
  
  @IBAction func backWasTapped(_ sender: Any) {
    navigationController?.popViewController(animated: true, completion: nil)
  }
  @IBAction func imageWasTapped(_ sender: Any) {
    imagePicker.present(from: imageButton)
  }
  
  @IBAction func submitWasTapped(_ sender: Any) {
    navigationController?.showTopBannerView(message: "Submit DApp successfully")
    navigationController?.popViewController(animated: true, completion: nil)
  }
  
  
  func resetViews() {
    appInfo.image = UIImage(named: "add-image")
    nameField.text = nil
    categoryField.text = nil
  }
  
}

extension SubmitAppViewController: ImagePickerDelegate {
  
  func didSelect(image: UIImage?) {
    appInfo.image = image
    if let image = image {
      imageButton.setImage(image, for: .normal)
      imageButton.imageEdgeInsets = .zero
    } else {
      imageButton.setImage(UIImage(named: "add-image"), for: .normal)
      imageButton.imageEdgeInsets = .init(top: 20, left: 20, bottom: 20, right: 20)
    }
  }
  
}
