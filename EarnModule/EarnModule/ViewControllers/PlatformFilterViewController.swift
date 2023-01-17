//
//  PlatformFilterViewController.swift
//  EarnModule
//
//  Created by Ta Minh Quan on 22/11/2022.
//

import UIKit
import Services
import DesignSystem

protocol PlatformFilterViewControllerDelegate: class {
    func didSelectPlatform(viewController: PlatformFilterViewController, selected: Set<EarnPlatform>, types: [EarningType])
}

class PlatformFilterViewModel {
    var dataSource: [EarnPlatform]
    var selected: Set<EarnPlatform>
    var shouldShowType: Bool = false
    var selectedType: [EarningType]?
    
    init(dataSource: Set<EarnPlatform>, selected: Set<EarnPlatform>) {
        self.dataSource = Array(dataSource).sorted { (left, right) -> Bool in
            return left.name < right.name
        }
        if selected.isEmpty {
            self.selected = dataSource
        } else {
            self.selected = dataSource.intersection(selected)
        }
    }
    
    func platformForRow(row: Int) -> EarnPlatform? {
        if row == 0 {
            return nil
        }
        let index = row - 1
        return dataSource[index]
    }
    
    func totalRow(section: Int) -> Int {
        if section == 0 {
            return dataSource.count + 1
        } else {
            return 1
        }
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
        platformTableView.registerCellNib(EarningTypeCell.self)
    }
    
    @IBAction func doneButtonTapped(_ sender: UIButton) {
        dismiss(animated: true) {
            self.delegate?.didSelectPlatform(viewController: self, selected: self.viewModel.selected, types: self.viewModel.selectedType ?? [])
        }
    }
    
    @IBAction func cancelButtonTapped(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
}

extension PlatformFilterViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.shouldShowType ? 2 : 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.totalRow(section: section)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(PlatformCell.self, indexPath: indexPath)!
            if let platform = viewModel.platformForRow(row: indexPath.row) {
                let isSelect = viewModel.isSelectAll ? false : viewModel.selected.contains(platform)
                cell.updateCell(platform: platform, isSelected: isSelect)
            } else {
                cell.updateCell(platform: nil, isSelected: viewModel.isSelectAll)
            }
            
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(EarningTypeCell.self, indexPath: indexPath)!
            cell.selectedType = self.viewModel.selectedType
            cell.updateUI()
            cell.onSelectedType = { selectedTypes in
                self.viewModel.selectedType = selectedTypes
            }
            return cell
        }
    }
}

extension PlatformFilterViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.section == 0 else { return }
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
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 60.0
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.01
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 60))
        let label = UILabel (frame: CGRect(x: 30, y: 15, width: tableView.frame.size.width - 30, height: 35))
        label.text = section == 0 ? Strings.selectPlatform : Strings.selectType
        label.font = UIFont.karlaReguler(ofSize: 18)
        label.textColor = AppTheme.current.primaryTextColor
        view.addSubview(label)
        return view
    }
    
}
