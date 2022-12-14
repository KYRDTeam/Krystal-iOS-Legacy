//
//  PlatformFilterViewController.swift
//  EarnModule
//
//  Created by Ta Minh Quan on 22/11/2022.
//

import UIKit
import Services

protocol PlatformFilterViewControllerDelegate: class {
    func didSelectPlatform(viewController: PlatformFilterViewController, selected: Set<EarnPlatform>)
}

class PlatformFilterViewModel {
    var dataSource: [EarnPlatform]
    var selected: Set<EarnPlatform>
    
    init(dataSource: Set<EarnPlatform>, selected: Set<EarnPlatform>) {
        self.dataSource = Array(dataSource).sorted { (left, right) -> Bool in
            return left.name < right.name
        }
        
        self.selected = dataSource.intersection(selected)
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
    
    var isSelectAll: Bool {
        return dataSource.count == selected.count
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
    
    @IBAction func doneButtonTapped(_ sender: UIButton) {
        dismiss(animated: true) {
            guard !self.viewModel.selected.isEmpty else { return }
            self.delegate?.didSelectPlatform(viewController: self, selected: self.viewModel.selected)
        }
    }
    
    @IBAction func cancelButtonTapped(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
}

extension PlatformFilterViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.totalRow()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(PlatformCell.self, indexPath: indexPath)!
        
        if let platform = viewModel.platformForRow(row: indexPath.row) {
            let isSelect = viewModel.isSelectAll ? false : viewModel.selected.contains(platform)
            cell.updateCell(platform: platform, isSelected: isSelect)
        } else {
            cell.updateCell(platform: nil, isSelected: viewModel.isSelectAll)
        }
        
        return cell
    }
}

extension PlatformFilterViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if let platform = viewModel.platformForRow(row: indexPath.row) {
            if viewModel.isSelectAll {
                viewModel.selected.removeAll()
            }
            if viewModel.selected.contains(platform) {
                viewModel.selected.remove(platform)
            } else {
                viewModel.selected.insert(platform)
            }
        } else {
            if viewModel.isSelectAll {
                viewModel.selected.removeAll()
            } else {
                viewModel.dataSource.forEach { element in
                    viewModel.selected.insert(element)
                }
            }
        }
        platformTableView.reloadData()
        
    }
}
