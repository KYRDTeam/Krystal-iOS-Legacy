//
//  ConfirmBackupViewController.swift
//  KyberNetwork
//
//  Created by Com1 on 18/08/2022.
//

import UIKit
import KrystalWallets
import AppState

protocol ConfirmBackupViewControllerDelegate: class {
  func didFinishBackup(_ controller: ConfirmBackupViewController)
}

class ConfirmBackupViewController: KNBaseViewController {
  @IBOutlet var answerWordLabel: [UILabel]!
  @IBOutlet var answerWordViews: [UIView]!
  @IBOutlet weak var collectionView: UICollectionView!
  weak var delegate: ConfirmBackupViewControllerDelegate?
  var seedStrings: [String] = []
  var walletId: String?
  var shuffledSeedStrings: [String] = []
  var questionIndexs: [Int] = []
  var currentIndex: Int = 0

  override func viewDidLoad() {
    super.viewDidLoad()
    collectionView.registerCellNib(SeedStringCell.self)
    shuffledSeedStrings = seedStrings.shuffled()
    reset()
  }
  
  func updateAnswerView() {
    for index in 0..<answerWordViews.count {
      let view = answerWordViews[index]
      if view.tag == currentIndex {
        view.backgroundColor = UIColor.Kyber.buttonBg.withAlphaComponent(0.2)
      } else {
        view.backgroundColor = UIColor.Kyber.grayBackgroundColor
      }
      view.layer.borderWidth = 0
    }
  }
  
  func updateAnswerLabel(answer: String, isCorrect: Bool) {
    guard isCorrect else {
      let currentAnswerView = answerWordViews.first(where: { $0.tag == currentIndex })
      currentAnswerView?.backgroundColor = UIColor.Kyber.errorText.withAlphaComponent(0.2)
      currentAnswerView?.shakeViewError()
      let label = answerWordLabel.first(where: { $0.tag == currentIndex })
      label?.textColor = UIColor.Kyber.errorText
      label?.text = "\(questionIndexs[currentIndex]). " + answer
      return
    }
    if let label = answerWordLabel.first(where: { $0.tag == currentIndex }) {
      label.textColor = UIColor.Kyber.whiteText
      label.text = answer.isEmpty ? "\(questionIndexs[currentIndex])" : "\(questionIndexs[currentIndex]). " + answer
    }
  }
  
  func checkAnswer(answer: String, index: Int) -> Bool {
    return answer == seedStrings[index - 1]
  }
  
  func reset() {
    currentIndex = 0
    generateQuestion()
    updateAnswerView()
    collectionView.reloadData()
  }
  
  func generateQuestion() {
    questionIndexs = []
    while questionIndexs.count < 4 {
      let randomInt = Int.random(in: 1..<12)
      if !questionIndexs.contains(randomInt) {
        questionIndexs.append(randomInt)
        updateAnswerLabel(answer: "", isCorrect: true)
        currentIndex += 1
      }
    }
    currentIndex = 0
  }
  
  func showSuccessBackup() {
    if let walletId = walletId {
        WalletExtraDataManager.shared.markWalletBackedUp(walletID: walletId)
    }
    let successBackupVC = BackupSuccessViewController()
    successBackupVC.delegate = self
    self.show(successBackupVC, sender: nil)
  }

  @IBAction func onBackButtonTapped(_ sender: Any) {
    self.navigationController?.popViewController(animated: true)
  }
}

extension ConfirmBackupViewController: UICollectionViewDataSource {
  
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return shuffledSeedStrings.count
  }
  
  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(SeedStringCell.self, indexPath: indexPath)!
    cell.titleLabel.text = shuffledSeedStrings[indexPath.row]
    cell.titleLabel.backgroundColor = UIColor.Kyber.cellBackground
    return cell
  }
}

extension ConfirmBackupViewController: UICollectionViewDelegateFlowLayout {
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
    return 12
  }

  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
    return UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
  }

  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    let text = shuffledSeedStrings[indexPath.row]
    let width = text.width(withConstrainedHeight: 32, font: UIFont.Kyber.regular(with: 14)) + 30
    return CGSize(width: width, height: 32)
  }
}

extension ConfirmBackupViewController: UICollectionViewDelegate {
  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    if currentIndex > 3 {
      return
    }
    guard let cell = collectionView.cellForItem(at: indexPath) as? SeedStringCell else {
      return
    }
    let answer = shuffledSeedStrings[indexPath.row]
    let index = questionIndexs[currentIndex]
    if checkAnswer(answer: answer, index: index) {
      cell.titleLabel.backgroundColor = UIColor.Kyber.buttonBg.withAlphaComponent(0.5)
      updateAnswerLabel(answer: answer, isCorrect: true)
      currentIndex += 1
      updateAnswerView()
      if currentIndex == 4 {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
          self.showSuccessBackup()
        }
      }
    } else {
      cell.titleLabel.backgroundColor = UIColor.Kyber.errorText.withAlphaComponent(0.5)
      updateAnswerLabel(answer: answer, isCorrect: false)
      DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
        self.reset()
      }
    }
  }
}

extension ConfirmBackupViewController: BackupSuccessViewControllerDelegate {
  func didFinishBackup(_ controller: BackupSuccessViewController) {
    self.delegate?.didFinishBackup(self)
  }
}
