//
//  KNActionSheetAlertViewController.swift
//  KyberNetwork
//
//  Created by Com1 on 20/09/2021.
//

import UIKit

// height or info view + padding for view = 42 + 24
let rowHeight = 66
let headerHeight = 46
typealias AlertHandler = @convention(block) (UIAlertAction) -> Void

class KNActionSheetAlertViewController: KNBaseViewController {
    /// Array contain actions which will be displayed
    let actions: [UIAlertAction]
    let maintitle: String
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tableViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var backgroundView: UIView!
    
    init(title: String, actions: [UIAlertAction]) {
        self.maintitle = title
        self.actions = actions
        super.init(nibName: KNActionSheetAlertViewController.className, bundle: nil)
        self.modalPresentationStyle = .custom
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configUI()
    }
    
    func configUI() {
        self.tableView.rounded(radius: 16)
        tableView.isScrollEnabled = false
        self.tableViewHeightConstraint.constant = CGFloat(self.actions.count * rowHeight + headerHeight * 2)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapOutside))
        backgroundView.addGestureRecognizer(tapGesture)
    }

    @objc func tapOutside() {
        self.dismiss(animated: true, completion: nil)
    }

}

extension KNActionSheetAlertViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let action = actions[indexPath.row]
        return actionInfoCell(action: action)
    }

    func actionInfoCell(action: UIAlertAction) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "actionInfoCell")
        let containViewWidth = UIScreen.main.bounds.size.width - 37*2
        let containWiew = UIView(frame: CGRect(x: 37, y: 12, width: containViewWidth, height: 42))
        containWiew.backgroundColor = UIColor(named: "navButtonBgColor")!
        containWiew.rounded(radius: 16)
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: containViewWidth, height: 42))
        label.textColor = UIColor(named: "textWhiteColor")!
        label.textAlignment = .center
        label.text = action.title
        containWiew.addSubview(label)
        cell.addSubview(containWiew)
        cell.backgroundColor = UIColor(named: "investButtonBgColor")!
        cell.selectionStyle = .none
        return cell
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return actions.count
    }
}

extension KNActionSheetAlertViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return CGFloat(rowHeight)
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat(headerHeight)
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: CGFloat(headerHeight)))
        view.backgroundColor = UIColor(named: "investButtonBgColor")!
        return view
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let action = actions[indexPath.row]
        self.dismiss(animated: true) {
            guard let block = action.value(forKey: "handler") else { return }
            let handler = unsafeBitCast(block as AnyObject, to: AlertHandler.self)
            handler(action)
        }
    }
}
