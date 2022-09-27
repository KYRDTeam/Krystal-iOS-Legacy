//
//  NotificationDetailViewController.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 26/09/2022.
//

import UIKit

class NotificationDetailViewController: UIViewController {
  
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var contentLabel: UILabel!
  @IBOutlet weak var timeLabel: UILabel!
  @IBOutlet weak var viewMoreButton: UIButton!
  
  override var preferredStatusBarStyle: UIStatusBarStyle { return .lightContent }
  
  var viewModel: NotificationItemViewModel!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    configureViews()
  }
  
  func configureViews() {
    titleLabel.text = viewModel.title
    contentLabel.text = viewModel.content
    timeLabel.text = viewModel.timeString
    viewMoreButton.isHidden = viewModel.url.isEmpty
  }
  
  @IBAction func backWasTapped(_ sender: Any) {
    navigationController?.popViewController(animated: true, completion: nil)
  }
  
  @IBAction func viewMoreWasTapped(_ sender: Any) {
    openSafari(with: viewModel.url)
  }
  
}
