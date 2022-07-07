//
//  ViewController.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 07/07/2022.
//

import Foundation
import UIKit

class ViewController: UIViewController {
  
  var viewModel: ViewModel?
  
  init(viewModel: ViewModel?) {
    self.viewModel = viewModel
    super.init(nibName: nil, bundle: nil)
  }
  
  required init?(coder aDecoder: NSCoder) {
    super.init(nibName: nil, bundle: nil)
  }
}
