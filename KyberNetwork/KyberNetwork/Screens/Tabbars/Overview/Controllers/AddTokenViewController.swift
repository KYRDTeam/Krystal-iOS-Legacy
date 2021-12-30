//
//  AddTokenViewController.swift
//  KyberNetwork
//
//  Created by Ta Minh Quan on 3/1/21.
//

import UIKit
import TrustCore

enum AddTokenViewEvent {
  case openQR
  case done(address: String, symbol: String, decimals: Int, shouldDismiss: Bool = true)
  case doneEdit(address: String, newAddress: String, symbol: String, decimals: Int)
  case getSymbol(address: String)
}

protocol AddTokenViewControllerDelegate: class {
  func addTokenViewController(_ controller: AddTokenViewController, run event: AddTokenViewEvent)
  func addTokensViaDeepLink(srcToken: TokenObject?, destToken: TokenObject?)
}

class AddTokenViewController: KNBaseViewController {
  @IBOutlet weak var addressField: UITextField!
  @IBOutlet weak var symbolField: UITextField!
  @IBOutlet weak var decimalsField: UITextField!
  @IBOutlet weak var doneButton: UIButton!
  @IBOutlet weak var titleHeader: UILabel!
  @IBOutlet weak var blockchainField: UITextField!
  
  weak var delegate: AddTokenViewControllerDelegate?
  var token: Token?
  var tokenObject: TokenObject?
  var newTokenObjects: [String: (TokenObject, Bool)] = [:]
  var remainTokenObjects: [TokenObject]?

  override func viewDidLoad() {
    super.viewDidLoad()
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    if let unwrapped = self.token {
      self.titleHeader.text = "Edit custom token".toBeLocalised()
      self.updateUI(unwrapped)
    } else {
      self.titleHeader.text = "Add custom token".toBeLocalised()
      if let unwrapped = self.tokenObject {
        if unwrapped.address.count != 54 {
          self.navigationController?.showTopBannerView(message: "Your custom token contract seems not to be a valid address")
        }
        
        self.addressField.text = unwrapped.address
        self.symbolField.text = unwrapped.symbol
        self.decimalsField.text = "\(unwrapped.decimals)"
      } else {
        self.addressField.text = ""
        self.symbolField.text = ""
        self.decimalsField.text = ""
      }
    }
    self.addressField.attributedPlaceholder = NSAttributedString(string: "Smart contract", attributes: [NSAttributedString.Key.foregroundColor: UIColor.Kyber.SWPlaceHolder])
    self.symbolField.attributedPlaceholder = NSAttributedString(string: "Token symbol", attributes: [NSAttributedString.Key.foregroundColor: UIColor.Kyber.SWPlaceHolder])
    self.decimalsField.attributedPlaceholder = NSAttributedString(string: "Decimals", attributes: [NSAttributedString.Key.foregroundColor: UIColor.Kyber.SWPlaceHolder])
    self.blockchainField.text = KNGeneralProvider.shared.chainName
  }
  
  fileprivate func updateUI(_ token: Token) {
    self.addressField.text = token.address
    self.symbolField.text = token.symbol
    self.decimalsField.text = "\(token.decimals)"
  }
  
  @IBAction func backButtonTapped(_ sender: UIButton) {
    if self.newTokenObjects.isEmpty {
      self.navigationController?.popViewController(animated: true)
    } else {
      self.dismissImportTokensFromDeepLink()
    }
    
  }
  @IBAction func pasteButtonTapped(_ sender: UIButton) {
    if let string = UIPasteboard.general.string {
      self.addressField.text = string
      self.delegate?.addTokenViewController(self, run: .getSymbol(address: string))
    }
  }

  @IBAction func qrButtonTapped(_ sender: UIButton) {
    self.delegate?.addTokenViewController(self, run: .openQR)
  }
  
  @IBAction func doneButtonTapped(_ sender: UIButton) {
    guard self.validateFields() else {
      return
    }
    if let unwrapped = self.token {
      self.delegate?.addTokenViewController(self, run: .doneEdit(address: unwrapped.address, newAddress: self.addressField.text ?? "", symbol: self.symbolField.text ?? "", decimals: Int(self.decimalsField.text ?? "") ?? 6))
    } else {
      guard var remainTokenObjects = self.remainTokenObjects, !remainTokenObjects.isEmpty else {
        // case add new normal
        self.delegate?.addTokenViewController(self, run: .done(address: self.addressField.text ?? "", symbol: self.symbolField.text ?? "", decimals: Int(self.decimalsField.text ?? "") ?? 6))
        return
      }
      // case import from deeplink

      // update status added for current token
      if let currentToken = remainTokenObjects.first {
        if let tupple = self.newTokenObjects["src"] {
          let srcToken = tupple.0
          if srcToken == currentToken {
            self.newTokenObjects["src"] = (srcToken, true)
          }
        }
        if let tupple = self.newTokenObjects["dest"] {
          let destToken = tupple.0
          if destToken == currentToken {
            self.newTokenObjects["dest"] = (destToken, true)
          }
        }
      }
      self.delegate?.addTokenViewController(self, run: .done(address: self.addressField.text ?? "", symbol: self.symbolField.text ?? "", decimals: Int(self.decimalsField.text ?? "") ?? 6, shouldDismiss: false))
      
      remainTokenObjects.removeFirst()
      self.remainTokenObjects = remainTokenObjects

      if !remainTokenObjects.isEmpty {
        if let token = remainTokenObjects.first {
          UIView.transition(with: self.view, duration: 0.5, options: .transitionFlipFromLeft) {
            self.coordinatorDidUpdateTokenObject(token)
          }
        }
        return
      } else {
        self.dismissImportTokensFromDeepLink()
      }
    }
  }
  
  func dismissImportTokensFromDeepLink() {
    var srcToken: TokenObject?
    var destToken: TokenObject?
    
    if let tupple = self.newTokenObjects["src"] {
      let token = tupple.0
      let isAdded = tupple.1
      if isAdded {
        srcToken = token
      }
    }
    
    if let tupple = self.newTokenObjects["dest"] {
      let token = tupple.0
      let isAdded = tupple.1
      if isAdded {
        destToken = token
      }
    }

    self.delegate?.addTokensViaDeepLink(srcToken: srcToken, destToken: destToken)
    self.navigationController?.popViewController(animated: true)
  }
  
  fileprivate func validateFields() -> Bool {
    if let text = self.addressField.text, text.isEmpty {
      self.showErrorTopBannerMessage(with: "", message: "Address is empty")
      return false
    }
    if let text = self.symbolField.text, text.isEmpty {
      self.showErrorTopBannerMessage(with: "", message: "Symbol is empty")
      return false
    }
    if let text = self.decimalsField.text, text.isEmpty {
      self.showErrorTopBannerMessage(with: "", message: "Decimals is empty")
      return false
    }
    
    if let text = self.addressField.text, Address(string: text) == nil {
      self.showErrorTopBannerMessage(with: "", message: "Address isn't correct")
      return false
    }

    return true
  }
  
  func coordinatorDidUpdateQRCode(address: String) {
    self.addressField.text = address
    self.delegate?.addTokenViewController(self, run: .getSymbol(address: address))
  }
  
  func coordinatorDidUpdateToken(symbol: String, decimals: String) {
    self.symbolField.text = symbol
    self.decimalsField.text = decimals
  }

  func isAddedToDB(address: String) -> Bool {
    return KNSupportedTokenStorage.shared.get(forPrimaryKey: address) != nil
  }
  
  func coordinatorDidUpdateTokenObject(_ token: TokenObject) {
    self.tokenObject = token
    guard self.isViewLoaded else {
      return
    }
    self.symbolField.text = token.symbol
    self.decimalsField.text = "\(token.decimals)"
    self.addressField.text = token.address
  }
  
  func coordinatorDidUpdateNewTokens(_ sourceToken: TokenObject?, _ destToken: TokenObject?) {
    var remainTokens: [TokenObject] = []

    if let sourceToken = sourceToken {
      self.newTokenObjects["src"] = (sourceToken, self.isAddedToDB(address: sourceToken.address))
      if !self.isAddedToDB(address: sourceToken.address) {
        remainTokens.append(sourceToken)
      }
    }

    if let destToken = destToken {
      self.newTokenObjects["dest"] = (destToken, self.isAddedToDB(address: destToken.address))
      if !self.isAddedToDB(address: destToken.address) {
        remainTokens.append(destToken)
      }
    }

    self.remainTokenObjects = remainTokens
    if !remainTokens.isEmpty {
      self.coordinatorDidUpdateTokenObject(remainTokens[0])
    }
  }
}
