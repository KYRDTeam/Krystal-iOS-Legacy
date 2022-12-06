//
//  Images.swift
//  KyberNetwork
//
//  Created by Nguyen Tung on 01/04/2022.
//

import UIKit

class Images {
  
  // Explore screen
  static let exploreSwapIcon = UIImage(named: "swap_inverst_icon")!
  static let exploreTransferIcon = UIImage(named: "transfer_invest_icon")!
  static let exploreRewardIcon = UIImage(named: "reward_icon")!
  static let exploreReferralIcon = UIImage(named: "referral_invest_icon")!
  static let exploreDappsIcon = UIImage(named: "dapp_invest_icon")!
  static let exploreMultisendIcon = UIImage(named: "multiSend_icon")!
  static let exploreBuyCryptoIcon = UIImage(named: "buy_crypto_invest_icon")!
  static let explorePromotionIcon = UIImage(named: "promo_code_icon")!
  static let exploreRewardHuntingIcon = UIImage(named: "reward_hunting_icon")!
  static let exploreBridgeIcon = UIImage(named: "bridge_icon")!
  static let exploreScannerIcon = UIImage(named: "scan")!
  static let exploreStakeIcon = UIImage(named: "stake_icon")!
  
  // History
  static let giftIcon = UIImage(named: "gift_icon")!
  static let warningRedIcon = UIImage(named: "warning_red_icon")!
  static let pendingTx = UIImage(named: "pending_tx_icon")!
  static let historyBridge = UIImage(named: "history_bridge")!
  static let historyTransfer = UIImage(named: "history_send_icon")!
  static let historyReceive = UIImage(named: "history_receive_icon")!
  static let historyApprove = UIImage(named: "history_approve_icon")!
  static let historyContractInteraction = UIImage(named: "history_contract_interaction_icon")!
  static let historyClaimReward = UIImage(named: "history_claim_reward_icon")!
  static let historyMultisend = UIImage(named: "multiSend_icon")!
  static let warningYellowIcon = UIImage(named: "warning_yellow_icon")!
  static let openLinkIcon = UIImage(named: "open_link_icon_blue")!
  
  // Overview
  static let emptyAsset = UIImage(named: "empty_asset_icon")
  static let emptyFavToken = UIImage(named: "empty_fav_token")
  static let emptyDeposit = UIImage(named: "deposit_empty_icon")
  static let emptyLiquidityPool = UIImage(named: "liquidity_pool_empty_icon")
  static let emptyTokens = UIImage(named: "empty_token_token")
  static let emptyNFT = UIImage(named: "empty_nft")
  
  // Common
  static let comingSoon = UIImage(named: "comming_soon")!
  static let dropdown = UIImage(named: "arrow_down")!
  static let success = UIImage(named: "success")!
  static let failure = UIImage(named: "fail")!
  static let pending = UIImage(named: "loading_icon")!
  static let txSuccess = UIImage(named: "tx_success_icon")!
  static let helpLargeIcon = UIImage(named: "help_icon_large")!
  static let arrowDropDownWhite = UIImage(named: "arrow_down_icon_white")!
  static let emptySearch = UIImage(named: "empty-search-token")!
  
  // Swap
  static let excludeCircleArrow = UIImage(named: "progress_exclude")!
  static let swapDropdown = UIImage(named: "swap_dropdown_grey")!
  static let swapPullup = UIImage(named: "swap_dropup_grey")!
  static let swapInfoBlue = UIImage(named: "info_blue")!
  static let swapInfoYellow = UIImage(named: "info_yellow")!
  static let swapWarningRed = UIImage(named: "swap_warning_red")!
  static let swapInfo = UIImage(named: "info_white")!
  static let swapSettings = UIImage(named: "swap_settings")!
  
  // Chains
  static let allNetworkSquare = UIImage(named: "network_all_square")!
  static let chainEthSquare = UIImage(named: "chain_eth_square")!
  static let chainBscSquare = UIImage(named: "chain_bsc_square")!
  static let chainPolygonSquare = UIImage(named: "chain_polygon_square")!
  static let chainAvaxSquare = UIImage(named: "chain_avax_square")!
  static let chainFantomSquare = UIImage(named: "chain_ftm_square")!
  static let chainCronosSquare = UIImage(named: "chain_cronos_square")!
  static let chainArbitrumSquare = UIImage(named: "chain_arbitrum_square")!
  static let chainAuroraSquare = UIImage(named: "chain_aurora_square")!
  static let chainSolanaSquare = UIImage(named: "chain_solana_square")!
  static let chainKlaytnSquare = UIImage(named: "chain_klaytn_square")!
  static let chainOptimismSquare = UIImage(named: "chain_optimism_square")!
    
  // Wallet connect
  static let connectSuccess = UIImage(named: "connect_success")!
  static let connectFailed = UIImage(named: "connect_fail")!
    
  // Staking
  static let revert = UIImage(imageName: "revert_icon")!
  static let greenPlus = UIImage(named: "green_plus_icon")!
  static let greenSubtract = UIImage(named: "green_subtract_icon")!
  static let redSubtract =   UIImage(imageName: "red_subtract_icon")!
  static let allNetworkIcon = UIImage(imageName: "all_platform_icon")!
  static let filterIcon = UIImage(imageName: "filter_icon")!
}

extension UIImage {
    convenience init?(imageName: String) {
        self.init(named: imageName, in: Bundle(for: Images.self), compatibleWith: nil)
    }
}
