//
//  Strings.swift
//  KyberNetwork
//
//  Created by Nguyen Tung on 01/04/2022.
//

import Foundation

struct Strings {
  // Common
  static let ok = "ok".toBeLocalised()
  
  // Actions
  static let add = "add".toBeLocalised()
  static let edit = "edit".toBeLocalised()
  static let addWatchWallet = "add.watched.wallet".toBeLocalised()
  static let editWatchWallet = "edit.watched.wallet".toBeLocalised()
  
  // Errors
  static let privateKeyError = "private.key.error".toBeLocalised()
  static let canNotGetPrivateKey = "can.not.get.private.key".toBeLocalised()
  static let invalidSession = "invalid.session".toBeLocalised()
  static let invalidSessionTryOtherQR = "invalid.session.try.other.qr".toBeLocalised()
  static let invalidEns = "invalid.ens".toBeLocalised()
  
  // Overview
  static let balanceIsEmpty = "your.balance.is.empty".toBeLocalised()
  static let notHaveLiquidityPool = "dont.have.any.liquidity.pool".toBeLocalised()
  static let notSuppliedAnyToken = "not.supply.any.token".toBeLocalised()
  static let noFavoriteToken = "no.favorite.token.yet".toBeLocalised()
  static let tokenListIsEmpty = "token.list.is.empty".toBeLocalised()
  static let notHaveAnyNFT = "not.have.any.nft".toBeLocalised()
  static let addNFT = "add.nft".toBeLocalised()
  static let supplyTokensToEarnInterest = "supply.tokens.to.earn.interest".toBeLocalised()
  
  // Explore screen
  static let explore = "explore".toBeLocalised()
  static let swap = "swap".toBeLocalised()
  static let transfer = "transfer".toBeLocalised()
  static let reward = "reward".toBeLocalised()
  static let referral = "referral".toBeLocalised()
  static let dApps = "dapps".toBeLocalised()
  static let multiSend = "multisend".toBeLocalised()
  static let buyCrypto = "buy.crypto".toBeLocalised()
  static let promotion = "promotion".toBeLocalised()
  static let supportedPlatforms = "supported.platforms".toBeLocalised()
  
  // History
  static let application = "application".toBeLocalised()
  static let fromWallet = "from.wallet".toBeLocalised()
  static let toWallet = "to.wallet".toBeLocalised()
  static let wallet = "wallet".toBeLocalised()
  static let fromColonX = "from_colon_x".toBeLocalised()
  static let toColonX = "to_colon_x".toBeLocalised()
  static let rewardHunting = "reward.hunting".toBeLocalised()
  static let copied = "copied".toBeLocalised()
  static let to = "to".toBeLocalised()
  static let from = "from".toBeLocalised()
  
  // Wallet
  static let chooseChainWallet = "choose.chain.wallet".toBeLocalised()
  static let rewardHuntingWatchWalletErrorMessage = "reward.hunting.watch.wallet.not.supported".toBeLocalised()
  static let notHaveChainWalletPleaseCreateOrImport = "not.have.chain.wallet.please.create.or.import".toBeLocalised()
}
