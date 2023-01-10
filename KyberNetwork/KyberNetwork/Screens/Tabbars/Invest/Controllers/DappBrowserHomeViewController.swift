//
//  DappBrowserHomeViewController.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 21/12/2021.
//

import UIKit
import TagListView

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
    BrowserItem(title: "KyberSwap", url: "https://kyberswap.com", image: "kyberswap")
  ]

  var recentlyDataSource: [BrowserItem] {
    if BrowserStorage.shared.recentlyBrowser.count > 8 {
      return Array(BrowserStorage.shared.recentlyBrowser.reversed().prefix(8))
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
  @IBOutlet weak var recentlyTagsListWidthContraint: NSLayoutConstraint!
  @IBOutlet weak var recentlyTagViewScrollViewContainer: UIScrollView!
  @IBOutlet weak var searchTextField: UITextField!
  
  let limitTagLength = 15

  let viewModel: DappBrowserHomeViewModel = DappBrowserHomeViewModel()

  weak var delegate: DappBrowserHomeViewControllerDelegate?

  override func viewDidLoad() {
    super.viewDidLoad()
    self.setupSuggestionSection()
    self.searchTextField.setupCustomDeleteIcon()
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
        self.recentlyTagViewScrollViewContainer.isHidden = true
        self.favoriteTitleLabel.isHidden = true
        self.favoriteTagsView.isHidden = true
        self.suggestionTitleTopContraint.priority = UILayoutPriority(200)
        self.suggestionTitleSpaceContraintWithRecentlyTagView.priority = UILayoutPriority(200)
        self.suggestionTitleTopContainerContraint.priority = UILayoutPriority(1000)
      } else {
        self.recentTitleLabel.isHidden = true
        self.showAllRecentlyButton.isHidden = true
        self.recentSearchTagsView.isHidden = true
        self.recentlyTagViewScrollViewContainer.isHidden = true
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
        self.recentlyTagViewScrollViewContainer.isHidden = false
        self.favoriteTitleLabel.isHidden = true
        self.favoriteTagsView.isHidden = true
        self.suggestionTitleSpaceContraintWithRecentlyTagView.priority = UILayoutPriority(1000)
        self.suggestionTitleTopContraint.priority = UILayoutPriority(200)
        self.suggestionTitleTopContainerContraint.priority = UILayoutPriority(200)
      } else {
        self.recentTitleLabel.isHidden = false
        self.showAllRecentlyButton.isHidden = false
        self.recentSearchTagsView.isHidden = false
        self.recentlyTagViewScrollViewContainer.isHidden = false
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
      guard !AppDelegate.session.address.isWatchWallet else {
          suggestionTagsView.isHidden = true
          suggestionTitleLabel.isHidden = true
          return
      }
      suggestionTagsView.isHidden = false
      suggestionTitleLabel.isHidden = false
    self.viewModel.suggestDataSource.forEach { item in
      self.suggestionTagsView.addTag(item.title.limit(scope: limitTagLength), image: UIImage(named: item.image ?? ""))
    }
  }

  private func setupRecentlySection() {
    var cacheImg: [String: UIImage] = [:]
    let group = DispatchGroup()

    self.viewModel.recentlyDataSource.forEach { item in
      group.enter()
      UIImage.loadImageIconWithCache(item.image ?? "", completion: { image in
        cacheImg[item.title] = image
        group.leave()
      })
    }

    group.notify(queue: .main) {
      self.recentSearchTagsView.removeAllTags()
      self.viewModel.recentlyDataSource.forEach { item in
        let tagView = self.recentSearchTagsView.addTag(item.title.limit(scope: self.limitTagLength), image: cacheImg[item.title])
        tagView.imageView?.contentMode = .scaleAspectFit
      }
      self.recentlyTagsListWidthContraint.constant = CGFloat(132 * self.viewModel.recentlyDataSource.count)
    }
  }

  private func setupFavoriteSection() {
    self.favoriteTagsView.removeAllTags()
    self.viewModel.favoriteDataSource.forEach { item in
      UIImage.loadImageIconWithCache(item.image  ?? "", completion: { image in
        let tag = self.favoriteTagsView.createCustomTagView(item.title.limit(scope: self.limitTagLength), image: image) { _ in
        }
        self.favoriteTagsView.addTagView(tag)
      })
    }
  }

  @IBAction func backButtonTapped(_ sender: UIButton) {
    self.navigationController?.popViewController(animated: true, completion: nil)
  }

  @IBAction func showAllRecently(_ sender: UIButton) {
    Tracker.track(event: .dappShowAllHistory)
    self.delegate?.dappBrowserHomeViewController(self, run: .showAllRecently)
  }
  
  @IBAction func searchTextButtonTapped(_ sender: UIButton) {
    guard self.searchTextField.isFirstResponder else {
      self.delegate?.dappBrowserHomeViewController(self, run: .enterText(text: self.searchTextField.text ?? ""))
      return
    }
    self.searchTextField.resignFirstResponder()
  }
}

extension DappBrowserHomeViewController: UITextFieldDelegate {
  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    textField.resignFirstResponder()
    return true
  }

  func textFieldDidEndEditing(_ textField: UITextField) {
    guard let text = textField.text, !text.isEmpty else { return }
    self.delegate?.dappBrowserHomeViewController(self, run: .enterText(text: text))
  }
}

extension DappBrowserHomeViewController: TagListViewDelegate {
  func tagPressed(_ title: String, tagView: TagView, sender: TagListView) {
    self.searchTextField.text = ""
    switch sender.tag {
    case 1:
      let filtered = self.viewModel.recentlyDataSource.first { item in
        return item.title.limit(scope: self.limitTagLength) == title
      }
      if let unwrap = filtered?.url {
        self.delegate?.dappBrowserHomeViewController(self, run: .enterText(text: unwrap))
      }
    case 2:
      let filtered = self.viewModel.favoriteDataSource.first { item in
        return item.title.limit(scope: self.limitTagLength) == title
      }
      if let unwrap = filtered?.url {
        self.delegate?.dappBrowserHomeViewController(self, run: .enterText(text: unwrap))
      }
    case 3:
      let filtered = self.viewModel.suggestDataSource.first { item in
        return item.title.limit(scope: self.limitTagLength) == title
      }
      if let unwrap = filtered?.url {
        self.delegate?.dappBrowserHomeViewController(self, run: .enterText(text: unwrap))
      }
    default:
      break
    }
  }
}

class CustomTagView: TagView {
  let containerWidth: CGFloat
  required public init?(coder aDecoder: NSCoder) {
    self.containerWidth = 100
    super.init(coder: aDecoder)
    
  }
  
  public init(title: String, containerWidth: CGFloat) {
    self.containerWidth = containerWidth
    super.init(title: title)
  }
  
  override open var intrinsicContentSize: CGSize {
    var size = titleLabel?.text?.size(withAttributes: [NSAttributedString.Key.font: textFont]) ?? CGSize.zero
    size.height = textFont.pointSize + paddingY * 2
    let width = (self.containerWidth / 2) - (paddingX / 2)
    size.width = width
    return size
  }
}

extension TagListView {
  func createCustomTagView(_ title: String, image: UIImage? = nil, onTap: @escaping ((TagView) -> Void)) -> TagView {
    let tagView = CustomTagView(title: title, containerWidth: self.frame.size.width)
    
    tagView.textColor = textColor
    tagView.selectedTextColor = selectedTextColor
    tagView.tagBackgroundColor = tagBackgroundColor
    tagView.highlightedBackgroundColor = tagHighlightedBackgroundColor
    tagView.selectedBackgroundColor = tagSelectedBackgroundColor
    tagView.titleLineBreakMode = tagLineBreakMode
    tagView.cornerRadius = cornerRadius
    tagView.borderWidth = borderWidth
    tagView.borderColor = borderColor
    tagView.selectedBorderColor = selectedBorderColor
    tagView.paddingX = paddingX
    tagView.paddingY = paddingY
    tagView.textFont = textFont
    tagView.removeIconLineWidth = removeIconLineWidth
    tagView.removeButtonIconSize = removeButtonIconSize
    tagView.enableRemoveButton = enableRemoveButton
    tagView.removeIconLineColor = removeIconLineColor
    tagView.addTarget(self, action: #selector(customTagPressed(_:)), for: .touchUpInside)

    if let image = image {
      tagView.imageView?.contentMode = .scaleAspectFit
      tagView.setImage(image, for: .normal)
    }
    
    // On long press, deselect all tags except this one
    tagView.onLongPress = { [unowned self] this in
      self.tagViews.forEach {
        $0.isSelected = $0 == this
      }
    }
    tagView.onTap = onTap
    
    return tagView
  }
  
  @objc func customTagPressed(_ sender: CustomTagView!) {
      sender.onTap?(sender)
      delegate?.tagPressed?(sender.currentTitle ?? "", tagView: sender, sender: self)
  }
}

