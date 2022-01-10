//
//  DappBrowserHomeViewController.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 21/12/2021.
//

import UIKit
import TagListView
import SwiftUI

enum DappBrowserHomeEvent {
  case enterText(text: String)
  case showAllRecently
}

protocol DappBrowserHomeViewControllerDelegate: class {
  func dappBrowserHomeViewController(_ controller: DappBrowserHomeViewController, run event: DappBrowserHomeEvent)
}

class DappBrowserHomeViewModel {
  let suggestDataSource = [
    BrowserItem(title: "KrystalGO", url: "https://go.krystal.app", image: "krystalgo"),
    BrowserItem(title: "KyberSwap", url: "https://kyberswap.com", image: "kyberswap"),
    BrowserItem(title: "Pancake", url: "https://pancakeswap.finance", image: "pancakeswap"),
    BrowserItem(title: "Compound", url: "https://compound.finance", image: "compound")
  ]
  
  var recentlyDataSource: [BrowserItem] {
    if BrowserStorage.shared.recentlyBrowser.count > 5 {
      return Array(BrowserStorage.shared.recentlyBrowser.prefix(5))
    }
    
    return BrowserStorage.shared.recentlyBrowser
  }
  var favoriteDataSource: [BrowserItem] {
    return BrowserStorage.shared.favoriteBrowser
  }
}

class DappBrowserHomeViewController: UIViewController {
  @IBOutlet weak var recentSearchTagsView: TagListView!
  @IBOutlet weak var favoriteTagsView: TagListView!
  @IBOutlet weak var suggestionTagsView: TagListView!
  @IBOutlet weak var recentTitleLabel: UILabel!
  @IBOutlet weak var favoriteTitleLabel: UILabel!
  @IBOutlet weak var suggestionTitleLabel: UILabel!
  @IBOutlet weak var favoriteTitleTopContainerContraint: NSLayoutConstraint!
  @IBOutlet weak var suggestionTitleTopContainerContraint: NSLayoutConstraint!
  @IBOutlet weak var favoriteTitleTopContraint: NSLayoutConstraint!
  @IBOutlet weak var suggestionTitleTopContraint: NSLayoutConstraint!
  @IBOutlet weak var suggestionTitleSpaceContraintWithRecentlyTagView: NSLayoutConstraint!
  @IBOutlet weak var showAllRecentlyButton: UIButton!
  
  
  let viewModel: DappBrowserHomeViewModel = DappBrowserHomeViewModel()

  weak var delegate: DappBrowserHomeViewControllerDelegate?

  override func viewDidLoad() {
    super.viewDidLoad()
    self.setupSuggestionSection()
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)

    self.setupFavoriteSection()
    self.setupRecentlySection()
    self.updateUI()
  }

  private func updateUI() {
    if self.viewModel.recentlyDataSource.isEmpty {
      if self.viewModel.favoriteDataSource.isEmpty {
        self.recentTitleLabel.isHidden = true
        self.showAllRecentlyButton.isHidden = true
        self.recentSearchTagsView.isHidden = true
        self.favoriteTitleLabel.isHidden = true
        self.favoriteTagsView.isHidden = true
        self.suggestionTitleTopContraint.priority = UILayoutPriority(200)
        self.suggestionTitleSpaceContraintWithRecentlyTagView.priority = UILayoutPriority(200)
        self.suggestionTitleTopContainerContraint.priority = UILayoutPriority(1000)
      } else {
        self.recentTitleLabel.isHidden = true
        self.showAllRecentlyButton.isHidden = true
        self.recentSearchTagsView.isHidden = true
        self.favoriteTitleLabel.isHidden = false
        self.favoriteTagsView.isHidden = false
        self.favoriteTitleTopContraint.priority = UILayoutPriority(200)
        self.favoriteTitleTopContainerContraint.priority = UILayoutPriority(1000)
        self.suggestionTitleTopContraint.priority = UILayoutPriority(1000)
        self.suggestionTitleTopContainerContraint.priority = UILayoutPriority(200)
      }
    } else {
      if self.viewModel.favoriteDataSource.isEmpty {
        self.recentTitleLabel.isHidden = false
        self.showAllRecentlyButton.isHidden = false
        self.recentSearchTagsView.isHidden = false
        self.favoriteTitleLabel.isHidden = true
        self.favoriteTagsView.isHidden = true
        self.suggestionTitleSpaceContraintWithRecentlyTagView.priority = UILayoutPriority(1000)
        self.suggestionTitleTopContraint.priority = UILayoutPriority(200)
        self.suggestionTitleTopContainerContraint.priority = UILayoutPriority(200)
      } else {
        self.recentTitleLabel.isHidden = false
        self.showAllRecentlyButton.isHidden = false
        self.recentSearchTagsView.isHidden = false
        self.favoriteTitleLabel.isHidden = false
        self.favoriteTagsView.isHidden = false
        self.suggestionTitleSpaceContraintWithRecentlyTagView.priority = UILayoutPriority(200)
        self.suggestionTitleTopContraint.priority = UILayoutPriority(1000)
        self.suggestionTitleTopContainerContraint.priority = UILayoutPriority(200)
        self.favoriteTitleTopContraint.priority = UILayoutPriority(1000)
        self.favoriteTitleTopContainerContraint.priority = UILayoutPriority(200)
      }
    }
  }

  private func setupSuggestionSection() {
    
    self.viewModel.suggestDataSource.forEach { item in
      self.suggestionTagsView.addTag(item.title, image: UIImage(named: item.image ?? ""))
    }
  }
  
  private func setupRecentlySection() {
    self.recentSearchTagsView.removeAllTags()
    self.viewModel.recentlyDataSource.forEach { item in
      UIImage.loadImageIconWithCache(item.image ?? "", completion: { image in
        self.recentSearchTagsView.addTag(item.title, image: image)
      })
    }
  }
  
  private func setupFavoriteSection() {
    self.favoriteTagsView.removeAllTags()
    self.viewModel.favoriteDataSource.forEach { item in
      UIImage.loadImageIconWithCache(item.image  ?? "", completion: { image in
        self.favoriteTagsView.addTag(item.title, image: image)
      })
      
    }
  }

  @IBAction func backButtonTapped(_ sender: UIButton) {
    self.navigationController?.popViewController(animated: true, completion: nil)
  }
  
  @IBAction func showAllRecently(_ sender: UIButton) {
    self.delegate?.dappBrowserHomeViewController(self, run: .showAllRecently)
  }
  
}

extension DappBrowserHomeViewController: UITextFieldDelegate {
  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    self.delegate?.dappBrowserHomeViewController(self, run: .enterText(text: textField.text ?? ""))
    textField.resignFirstResponder()
    return true
  }
}

extension DappBrowserHomeViewController: TagListViewDelegate {
  func tagPressed(_ title: String, tagView: TagView, sender: TagListView) {
    switch sender.tag {
    case 1:
      let filtered = self.viewModel.recentlyDataSource.first { item in
        return item.title == title
      }
      if let unwrap = filtered?.url {
        self.delegate?.dappBrowserHomeViewController(self, run: .enterText(text: unwrap))
      }
    case 2:
      let filtered = self.viewModel.favoriteDataSource.first { item in
        return item.title == title
      }
      if let unwrap = filtered?.url {
        self.delegate?.dappBrowserHomeViewController(self, run: .enterText(text: unwrap))
      }
    case 3:
      let filtered = self.viewModel.suggestDataSource.first { item in
        return item.title == title
      }
      if let unwrap = filtered?.url {
        self.delegate?.dappBrowserHomeViewController(self, run: .enterText(text: unwrap))
      }
    default:
      break
    }
  }
}
