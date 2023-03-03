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
    var expandingRows: Set<Int> = .init([])
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if dataSource.count == 1 { expandingRows.insert(0) }
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
        animateCellHeight(cell: cell, indexPath: indexPath)
        return cell
    }
}

extension TipsViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if expandingRows.contains(indexPath.row) {
            expandingRows.remove(indexPath.row)
        } else {
            expandingRows.insert(indexPath.row)
        }
        self.tableView.beginUpdates()
        if let cell = self.tableView.cellForRow(at: indexPath) as? TipsCell {
            animateCellHeight(cell: cell, indexPath: indexPath)
        }
        self.tableView.endUpdates()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if let cell = self.tableView.cellForRow(at: indexPath) as? TipsCell {
            return expandingRows.contains(indexPath.row) ? cell.contentHeight : 80
        }
        return expandingRows.contains(indexPath.row) ? UITableView.automaticDimension : 80
    }

    func animateCellHeight(cell: TipsCell, indexPath: IndexPath) {
        self.view.layoutIfNeeded()
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.65, initialSpringVelocity: 0, options: .curveEaseInOut) {
            cell.updateUIExpanse(isExpand: self.expandingRows.contains(indexPath.row))
            self.view.layoutIfNeeded()
        }
    }
}
