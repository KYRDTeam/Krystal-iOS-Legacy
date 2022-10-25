//
//  ApprovalListViewController.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 25/10/2022.
//

import UIKit
import BaseModule
import DesignSystem

class ApprovalListViewController: BaseWalletOrientedViewController {
    
    @IBOutlet weak var searchField: UITextField!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var riskAmountLabel: UILabel!
    
    var viewModel: ApprovalListViewModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupViews()
    }
    
    func setupViews() {
        setupTableView()
        setupSearchField()
    }
    
    func setupSearchField() {
        searchField.delegate = self
        searchField.setPlaceholder(text: Strings.approvalSearchPlaceholder, color: AppTheme.current.secondaryTextColor)
    }
    
    func setupTableView() {
        tableView.contentInset = .init(top: -16, left: 0, bottom: 0, right: 0)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableHeaderView = .init(frame: .init(x: 0, y: 0, width: 0, height: CGFloat.leastNonzeroMagnitude))
        tableView.registerCellNib(ApprovedTokenCell.self)
    }
    
    @IBAction func backWasTapped(_ sender: Any) {
        viewModel.onTapBack()
    }

}

extension ApprovalListViewController: UITextFieldDelegate {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let text = ((textField.text ?? "") as NSString).replacingCharacters(in: range, with: string)
        viewModel.searchText = text
        return true
    }
    
}

extension ApprovalListViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 20 // viewModel.filteredApprovedTokens.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(ApprovedTokenCell.self, indexPath: indexPath)!
        cell.selectionStyle = .none
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 84
    }
    
}
