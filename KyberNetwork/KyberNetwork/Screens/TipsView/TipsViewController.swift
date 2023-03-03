//
//  TipsViewController.swift
//  KyberNetwork
//
//  Created by Com1 on 28/02/2023.
//

import UIKit

struct TipModel {
    let title: String
    let detail: String
}

class TipsViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var titleLabel: UILabel!
    
    var dataSource: [TipModel] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.titleLabel.text = title
        self.navigationController?.setNavigationBarHidden(true, animated: true)        
        self.tableView.registerCellNib(TipsCell.self)
    }

    @IBAction func backButtonTapped(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
}

extension TipsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(TipsCell.self, indexPath: indexPath)!
        let tip = dataSource[indexPath.row]
        cell.titleLabel.text = tip.title
        cell.detailTipsLabel.text = tip.detail
        return cell
    }
}

extension TipsViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.tableView.beginUpdates()
        if let cell = self.tableView.cellForRow(at: indexPath) as? TipsCell {
            animateCellHeight(cell: cell)
        }
        self.tableView.endUpdates()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if let cell = self.tableView.cellForRow(at: indexPath) as? TipsCell {
            return cell.isExpand ? cell.contentHeight : 80
        }
        return 80
    }

    func animateCellHeight(cell: TipsCell) {
        self.view.layoutIfNeeded()
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.65, initialSpringVelocity: 0, options: .curveEaseInOut) {
            cell.updateUIExpanse()
            self.view.layoutIfNeeded()
        }
    }
}
