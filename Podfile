platform :ios, '12.0'
inhibit_all_warnings!

workspace 'KyberNetwork.xcworkspace'

source 'https://github.com/CocoaPods/Specs.git'
# source 'https://cdn.cocoapods.org/'
# tmp fix the CDN outage: https://github.com/CocoaPods/CocoaPods/issues/10078#issuecomment-696481185
# https://github.com/CocoaPods/CocoaPods/issues/11355

def firebasePods
  pod 'Firebase/Analytics'
  pod 'Firebase/Crashlytics'
  pod 'FirebasePerformance'
  #  pod 'FirebaseRemoteConfig', '~> 4.4'
end

def uiPods
  pod 'lottie-ios'
  pod 'SwipeCellKit'
  pod 'Charts'
  pod 'SeedStackViewController'
  pod 'IQKeyboardManager', '~> 6.5'
  pod 'JdenticonSwift', '~> 0.0.1'
  pod 'QRCodeReaderViewController', '~> 4.0.2'
  pod 'SwiftMessages', '~> 5.0.1'
  pod 'MBProgressHUD', '~> 1.1.0'
  pod 'StatefulViewController', '~> 3.0'
  pod 'Eureka', '~> 5.3.0'
  pod 'FSPagerView'
  pod 'TagListView', :git => 'https://github.com/Expensify/TagListView.git'
  pod 'SkeletonView'
  pod 'FittedSheets'
  pod 'loady'
end

def cryptoHelperPods
  pod 'BigInt', '~> 4.0'
  pod 'CryptoSwift'
  pod 'TrustWalletCore', '~> 2.9'
  pod 'TrustKeystore', '~> 0.4.2'
  pod 'TrustCore', '~> 0.0.7'
  pod 'WalletConnectSwift'
  pod 'Web3'
  # pod 'web3swift', :git=>'https://github.com/BANKEX/web3swift', :branch=>'master'
end

def networkingPods
  pod 'APIKit', '~> 3.2.1'
  pod 'JSONRPCKit', '~> 3.0.0' #:git=> 'https://github.com/bricklife/JSONRPCKit.git'
  pod 'JavaScriptKit', '~> 1.0.0'
  pod 'OneSignal', '>= 3.0.0', '< 4.0'
  pod 'Starscream', '~> 3.1'
  pod 'Kingfisher', '~> 7.0'
  pod 'Moya', '~> 10.0.1'
  pod 'Mixpanel-swift'
end

def databasePods
  pod 'KeychainSwift', '~> 13.0.0'
  pod 'SAMKeychain', '~> 1.5.3'
  pod 'RealmSwift', '~> 3.19.0'
end

def utilitiesPods
  pod 'LaunchDarkly', '~> 5.4'
  pod 'Swinject'
  pod 'SwiftLint', '~> 0.29.4'
  pod 'Sentry', :git => 'https://github.com/getsentry/sentry-cocoa.git', :tag => '7.2.8'
  pod 'Lokalise', '~> 0.8.1'
  pod 'GoogleMLKit/TextRecognition', '2.2.0'
end

def swapDependencies
  pod 'BigInt'
  pod 'Moya'
  pod 'JSONRPCKit'
  pod 'APIKit'
  pod 'lottie-ios'
end

def earnDependencies
  pod 'BigInt'
  pod 'Moya'
  pod 'JSONRPCKit'
  pod 'APIKit'
  pod 'lottie-ios'
  pod 'FittedSheets'
  pod 'TrustCore'
  pod 'SwipeCellKit'
end

def servicesDependencies
  pod 'Moya'
  pod 'BigInt'
  pod 'JSONRPCKit'
  pod 'APIKit'
  pod 'Web3'
  pod 'JavaScriptKit', '~> 1.0.0'
end

def designSystemDependencies
  pod 'SkeletonView'
  pod 'SwiftMessages'
  pod 'FittedSheets'
  pod 'MBProgressHUD', '~> 1.1.0'
end

def dependenciesDependencies
  pod 'BigInt'
end

def transactionModuleDependencies
  pod 'FittedSheets'
  pod 'BigInt'
  pod 'TrustWalletCore'
  pod 'TrustCore'
  pod 'JSONRPCKit'
  pod 'APIKit'
  pod 'CryptoSwift'
  pod 'loady'
end

target 'Dependencies' do
  project 'Dependencies/Dependencies.xcodeproj'
  use_frameworks!
  
  dependenciesDependencies
end

target 'DesignSystem' do
  project 'DesignSystem/DesignSystem.xcodeproj'
  use_frameworks!
  
  designSystemDependencies
end

target 'Services' do
  project 'Services/Services.xcodeproj'
  use_frameworks!
  
  servicesDependencies
end

target 'SwapModule' do
  project 'SwapModule/SwapModule.xcodeproj'
  use_frameworks!
  
  swapDependencies
end

target 'TransactionModule' do
  project 'TransactionModule/TransactionModule.xcodeproj'
  use_frameworks!
  
  transactionModuleDependencies
end

target 'EarnModule' do
  project 'EarnModule/EarnModule.xcodeproj'
  use_frameworks!
  uiPods
  earnDependencies
end

target 'Utilities' do
  project 'Utilities/Utilities.xcodeproj'
  use_frameworks!
  
  pod 'BigInt'
  pod 'Kingfisher'
end

target 'TokenModule' do
  project 'TokenModule/TokenModule.xcodeproj'
  use_frameworks!
  
  pod 'BigInt'
  pod 'MBProgressHUD', '~> 1.1.0'
  pod 'Charts'
  pod 'SkeletonView'
end

target 'BaseModule' do
  project 'BaseModule/BaseModule.xcodeproj'
  use_frameworks!
  
  pod 'FittedSheets'
end

target 'KyberNetwork' do
  use_frameworks!
  
  firebasePods
  uiPods
  cryptoHelperPods
  networkingPods
  databasePods
  utilitiesPods
  
  target 'KyberNetworkTests' do
    inherit! :search_paths
    # Pods for testing
  end
  
  target 'KrystalUnitTests' do
    inherit! :search_paths
    
    pod 'Quick'
    pod 'Nimble'
  end

  target 'KyberNetworkUITests' do
    inherit! :search_paths
    # Pods for testing
  end
  
end

target 'KrystalWallets' do
  use_frameworks!

  databasePods
  pod 'TrustWalletCore', '~> 2.9'
  pod 'KeychainSwift'
  pod 'CryptoSwift'
end

target 'KrystalNotificationServiceExtension' do
  use_frameworks!
  pod 'OneSignal', '>= 3.0.0', '< 4.0'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '12.0'
    end
    if ['TrustKeystore'].include? target.name
      target.build_configurations.each do |config|
        config.build_settings['SWIFT_OPTIMIZATION_LEVEL'] = '-Owholemodule'
      end
    end
  end
end
