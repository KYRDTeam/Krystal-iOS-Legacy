//
//  PortfolioViewController.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 07/07/2022.
//

import UIKit
import RxDataSources

class PortfolioViewController: UIViewController {
  @IBOutlet weak var tableView: UITableView!
  @IBOutlet weak var collectionView: UICollectionView!
  
  var viewModel: PortfolioViewModel!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    setupTableView()
    bindViewModel()
  }
  
  func setupTableView() {
    tableView.registerCellNib(PortfolioAssetCell.self)
  }
  
  func bindViewModel() {
    let input = PortfolioViewModel.Input()
    let output = viewModel.transform(input: input)
    
    output.sections
      .bind(to: tableView.rx.items(dataSource: viewModel.dataSource))
      .disposed(by: rx.disposeBag)
  }
  
}
