//
//  MultiSendViewController.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 09/02/2022.
//

import UIKit
import SwipeCellKit

enum MultiSendViewControllerEvent {
  case searchToken(selectedToken: Token)
}

protocol MultiSendViewControllerDelegate: class {
  func multiSendViewController(_ controller: MultiSendViewController, run event: MultiSendViewControllerEvent)
}

class MultiSendViewModel {
  var cellModels = [MultiSendCellModel()]
  var updatingIndex = 0
}
class MultiSendViewController: KNBaseViewController {
  @IBOutlet weak var inputTableView: UITableView!
  @IBOutlet weak var inputTableViewHeight: NSLayoutConstraint!
  
  let viewModel = MultiSendViewModel()
  weak var delegate: MultiSendViewControllerDelegate?
  
  init() {
    super.init(nibName: MultiSendViewController.className, bundle: nil)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    let nib = UINib(nibName: MultiSendCell.className, bundle: nil)
    self.inputTableView.register(nib, forCellReuseIdentifier: MultiSendCell.cellID)
    self.inputTableView.rowHeight = MultiSendCell.cellHeight
    

  }
  
  @IBAction func backButtonTapped(_ sender: UIButton) {
    self.navigationController?.popViewController(animated: true)
  }
  
  func coordinatorDidUpdateSendToken(_ from: Token) {
    let cm = self.viewModel.cellModels[self.viewModel.updatingIndex]
    cm.from = from
    self.inputTableView.reloadData()
    self.viewModel.updatingIndex = 0
  }
}

extension MultiSendViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.viewModel.cellModels.count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(
      withIdentifier: MultiSendCell.cellID,
      for: indexPath
    ) as! MultiSendCell
    cell.cellDelegate = self
    cell.delegate = self
    let cm = self.viewModel.cellModels[indexPath.row]
    cell.updateCellModel(cm)
    return cell
  }
}

extension MultiSendViewController: UITableViewDelegate {
  
}

extension MultiSendViewController: MultiSendCellDelegate {
  func multiSendCell(_ cell: MultiSendCell, run event: MultiSendCellEvent) {
    switch event {
    case .add:
      let element = MultiSendCellModel()
      element.index = self.viewModel.cellModels.count
      element.addButtonEnable = true
      self.viewModel.cellModels.forEach { e in
        e.addButtonEnable = false
      }
      self.viewModel.cellModels.append(element)
      self.inputTableViewHeight.constant = CGFloat(self.viewModel.cellModels.count) * MultiSendCell.cellHeight
      self.inputTableView.reloadData()
    
    case .searchToken(selectedToken: let selectedToken, cellIndex: let cellIndex):
      self.viewModel.updatingIndex = cellIndex
      self.delegate?.multiSendViewController(self, run: .searchToken(selectedToken: selectedToken))
    }
  }
}

extension MultiSendViewController: SwipeTableViewCellDelegate {
  func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
    guard indexPath.row > 0 else { return nil }

    let delete = SwipeAction(style: .destructive, title: nil) { _, _ in
      self.viewModel.cellModels.remove(at: indexPath.row)
      self.viewModel.cellModels.last?.addButtonEnable = true
      self.inputTableView.reloadData()
    }
    delete.title = "delete".toBeLocalised().uppercased()
    delete.textColor = UIColor(named: "textWhiteColor")
    delete.font = UIFont.Kyber.medium(with: 12)

    return [delete]
  }
  
  func tableView(_ tableView: UITableView, editActionsOptionsForRowAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> SwipeOptions {
    var options = SwipeOptions()
    options.expansionStyle = .selection
    options.minimumButtonWidth = 90
    options.maximumButtonWidth = 90

    return options
  }
}
