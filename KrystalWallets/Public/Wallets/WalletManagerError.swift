//
//  WalletManagerError.swift
//  KrystalWalletManager
//
//  Created by Tung Nguyen on 01/06/2022.
//

import Foundation

public enum WalletManagerError: Error {
//  case invalidAddress
  case invalidMnemonic
  case invalidPrivateKey
  case invalidJSON
  case invalidPassword
  case invalidKeyStore
  case cannotSaveAddress
  case cannotCreateWallet
  case cannotFindWallet
  case importFromPrivateKey
  case cannotExportMnemonic
  case cannotExportPrivateKey
  case cannotExportKeystore
  case cannotImportWallet
  case duplicatedWallet
  case failedToRemoveWallet
  case failedToRemoveAddress
  case failedToRenameWallet
  case failedToUpdateAddress
  case failedToSignMessage
}
