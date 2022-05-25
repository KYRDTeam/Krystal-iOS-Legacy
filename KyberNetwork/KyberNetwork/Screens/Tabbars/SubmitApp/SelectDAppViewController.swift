//
//  SelectDAppViewController.swift
//  KyberNetwork
//
//  Created by Nguyen Tung on 25/05/2022.
//

import UIKit

class SelectDAppViewController: UIViewController {
  @IBOutlet weak var tableView: UITableView!
  
  var chains: [ChainType] = ChainType.allCases
  var selectedChains: Set<String> = .init()
  var didSelect: (([String]) -> ())?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    setupTableView()
  }
  
  func setupTableView() {
    tableView.delegate = self
    tableView.dataSource = self
    
    tableView.registerCellNib(SelectAppProtocolCell.self)
  }
  
  @IBAction func closeWasTapped(_ sender: Any) {
    navigationController?.popViewController(animated: true, completion: nil)
  }
  
  @IBAction func onTapSave(_ sender: Any) {
    didSelect?(Array(selectedChains))
    navigationController?.popViewController(animated: true, completion: nil)
  }
}

extension SelectDAppViewController: UITableViewDelegate, UITableViewDataSource {
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(SelectAppProtocolCell.self, indexPath: indexPath)!
    let chain = chains[indexPath.row]
    cell.configure(chain: chain, isSelected: selectedChains.contains(chain.chainName()))
    return cell
  }
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return chains.count
  }

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let chain = chains[indexPath.row]
    if selectedChains.contains(chain.chainName()) {
      selectedChains.remove(chain.chainName())
    } else {
      selectedChains.insert(chain.chainName())
    }
    tableView.reloadRows(at: [indexPath], with: .automatic)
  }
  
  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return 64
  }
  
}
