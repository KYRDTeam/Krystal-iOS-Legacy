//
//  PlatformFilterViewController.swift
//  EarnModule
//
//  Created by Ta Minh Quan on 22/11/2022.
//

import UIKit
import Services

protocol PlatformFilterViewControllerDelegate: class {
    func didSelectPlatform(_ selected: EarnPlatform?)
}

class PlatformFilterViewModel {
    var dataSource: [EarnPlatform]
    var selected: EarnPlatform?
    
    init(dataSource: [EarnPlatform], selected: EarnPlatform?) {
        self.dataSource = dataSource
        self.selected = selected
    }
    
    func platformForRow(row: Int) -> EarnPlatform? {
        if row == 0 {
            return nil
        }
        let index = row - 1
        return dataSource[index]
    }
    
    func totalRow() -> Int {
        return dataSource.count + 1
    }
}

class PlatformFilterViewController: KNBaseViewController {
    
    @IBOutlet weak var platformTableView: UITableView!
    
    var viewModel: PlatformFilterViewModel!
    weak var delegate: PlatformFilterViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        registerCell()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        platformTableView.reloadData()
    }
    
    private func registerCell() {
        platformTableView.registerCellNib(PlatformCell.self)
    }
    
}

extension PlatformFilterViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.totalRow()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(PlatformCell.self, indexPath: indexPath)!
        let platform = viewModel.platformForRow(row: indexPath.row)
        cell.updateCell(platform: platform, isSelected: platform == viewModel.selected)
        return cell
    }
}

extension PlatformFilterViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let platform = viewModel.platformForRow(row: indexPath.row)
        delegate?.didSelectPlatform(platform)
    }
}
