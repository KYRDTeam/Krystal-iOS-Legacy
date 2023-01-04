//
//  RateTransactionPopupViewController.swift
//  KyberNetwork
//
//  Created by Com1 on 09/03/2022.
//

import UIKit
import Moya
import BaseModule
import Services

public protocol RateTransactionPopupDelegate: class {
    func didUpdateRate(rate: Int)
    func didSendRate()
}

class RateTxPopup: KNBaseViewController {
    @IBOutlet weak var oneStarButton: UIButton!
    @IBOutlet weak var twoStarButton: UIButton!
    @IBOutlet weak var threeStarButton: UIButton!
    @IBOutlet weak var fourStarButton: UIButton!
    @IBOutlet weak var fiveStarButton: UIButton!
    @IBOutlet weak var detailTextView: UITextView!
    @IBOutlet weak var contentViewTopContraint: NSLayoutConstraint!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var tapOutsideBGView: UIView!
    @IBOutlet weak var finishView: UIView!
    @IBOutlet weak var doneImageView: UIImageView!
    @IBOutlet weak var sendButton: UIButton!
    
    var currentRate: Int!
    var txHash: String!
    var detailValuation: String?
    
    weak var delegate: RateTransactionPopupDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.updateRateUI(rate: self.currentRate)
    }
    
    @objc func tapOutside() {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func rateButtonTapped(_ sender: UIButton) {
        self.updateRateUI(rate: sender.tag)
        self.delegate?.didUpdateRate(rate: sender.tag)
    }
    
    @IBAction func closeButtonTapped(_ sender: Any) {
        self.dismiss(animated: true) {
            self.delegate?.didSendRate()
        }
    }
    
    @IBAction func sendButtonTapped(_ sender: Any) {
        if self.currentRate <= 3 && self.detailTextView.text.trimmed.isEmpty {
            self.detailTextView.shakeViewError()
            showTopBannerView(message: "Please input detailed valuation to send.")
            return
        }
        self.finishView.isHidden = false
        self.sendRate()
    }
    
    func updateRateUI(rate: Int) {
        self.oneStarButton.setImage(rate >= 1 ? UIImage(named: "green_star_icon") : UIImage(named: "star_icon"), for: .normal)
        self.oneStarButton.setImage(rate >= 1 ? UIImage(named: "green_star_icon") : UIImage(named: "star_icon"), for: .highlighted)
        
        self.twoStarButton.setImage(rate >= 2 ? UIImage(named: "green_star_icon") : UIImage(named: "star_icon"), for: .normal)
        self.twoStarButton.setImage(rate >= 2 ? UIImage(named: "green_star_icon") : UIImage(named: "star_icon"), for: .highlighted)
        
        self.threeStarButton.setImage(rate >= 3 ? UIImage(named: "green_star_icon") : UIImage(named: "star_icon"), for: .normal)
        self.threeStarButton.setImage(rate >= 3 ? UIImage(named: "green_star_icon") : UIImage(named: "star_icon"), for: .highlighted)
        
        self.fourStarButton.setImage(rate >= 4 ? UIImage(named: "green_star_icon") : UIImage(named: "star_icon"), for: .normal)
        self.fourStarButton.setImage(rate >= 4 ? UIImage(named: "green_star_icon") : UIImage(named: "star_icon"), for: .highlighted)
        
        self.fiveStarButton.setImage(rate >= 5 ? UIImage(named: "green_star_icon") : UIImage(named: "star_icon"), for: .normal)
        self.fiveStarButton.setImage(rate >= 5 ? UIImage(named: "green_star_icon") : UIImage(named: "star_icon"), for: .highlighted)
        self.currentRate = rate
    }
    
    func sendRate() {
        TrackingService().sendRate(star: currentRate, detail: detailTextView.text, txHash: txHash)
    }
}
