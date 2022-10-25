//
//  ApprovalListViewModel.swift
//  KyberNetwork
//
//  Created by Tung Nguyen on 25/10/2022.
//

import Foundation

class ApprovalListViewModel {
    
    struct Actions {
        var onTapBack: () -> ()
    }
    
    var searchText: String = "" {
        didSet {
            filteredApprovedTokens = self.getFilteredApprovals(searchText: searchText)
                .map { token in ApprovedTokenItemViewModel() }
        }
    }
    
    var actions: Actions
    var approvedTokens: [String] = []
    var filteredApprovedTokens: [ApprovedTokenItemViewModel] = []
    
    init(actions: Actions) {
        self.actions = actions
    }
    
    func getFilteredApprovals(searchText: String) -> [String] {
        return approvedTokens.filter { token in
            return true
        }
    }
    
    func onTapBack() {
        actions.onTapBack()
    }
}
