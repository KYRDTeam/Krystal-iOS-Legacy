//
//  SecurityTipsViewController.swift
//  KyberNetwork
//
//  Created by Com1 on 28/02/2023.
//

import UIKit

struct TipModel {
    let title: String
    let detail: String
}

class SecurityTipsViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    var dataSource: [TipModel] = []
    override func viewDidLoad() {
        super.viewDidLoad()
        initializeData()
        self.tableView.registerCellNib(TipsCell.self)
    }
    
    func initializeData() {
        let seedPhase = TipModel(title: Strings.seedPhaseTip, detail: Strings.seedPhaseTipDetail)
        let privateKey = TipModel(title: Strings.privateKeyTip, detail: Strings.privateKeyTipDetail)
        dataSource = [seedPhase, privateKey]
    }

    @IBAction func backButtonTapped(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
}

extension SecurityTipsViewController: UITableViewDataSource {
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

extension SecurityTipsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.tableView.beginUpdates()
        if let cell = self.tableView.cellForRow(at: indexPath) as? TipsCell {
            animateCellHeight(cell: cell)
        }
        self.tableView.endUpdates()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if let cell = self.tableView.cellForRow(at: indexPath) as? TipsCell {
            return cell.isExpand ? 120 : 80
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
