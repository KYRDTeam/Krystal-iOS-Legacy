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
    
  var appInfo: DappInfo = .init()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
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
    let picker = ImagePicker(presentationController: self, delegate: self)
    picker.present(from: imageButton)
  }
  
  func resetViews() {
    appInfo.image = UIImage(named: "add-image")
    nameField.text = nil
    categoryField.text = nil
  }
  
}

extension SubmitAppViewController: ImagePickerDelegate {
  
  func didSelect(image: UIImage?) {
    appInfo.image = image ?? UIImage(named: "add-image")
    imageButton.setImage(image, for: .normal)
  }
  
}
