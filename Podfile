platform :ios, '12.0'
inhibit_all_warnings!
plugin 'cocoapods-binary'
source 'https://cdn.cocoapods.org/'

def firebasePods
  pod 'Firebase/Analytics', :binary => true
  pod 'Firebase/Crashlytics', :binary => true
  pod 'FirebasePerformance', :binary => true
  #  pod 'FirebaseRemoteConfig', '~> 4.4'
end

def uiPods
  pod 'lottie-ios', :binary => true
  pod 'SwipeCellKit', :binary => true
  pod 'Charts', :binary => true
  pod 'SeedStackViewController', :binary => true
  pod 'SwiftChart', :git => 'https://github.com/gpbl/SwiftChart.git', :binary => true
  pod 'IQKeyboardManager', '~> 6.5', :binary => true
  pod 'JdenticonSwift', '~> 0.0.1', :binary => true
  pod 'QRCodeReaderViewController', '~> 4.0.2', :binary => true
  pod 'SwiftMessages', '~> 5.0.1', :binary => true
  pod 'MBProgressHUD', '~> 1.1.0', :binary => true
  pod 'StatefulViewController', '~> 3.0', :binary => true
  pod 'Eureka', '~> 5.3.0', :binary => true
  pod 'FSPagerView', :binary => true
  pod 'TagListView', :git => 'https://github.com/Expensify/TagListView.git', :binary => true
  pod 'SkeletonView', :binary => true
end

def cryptoHelperPods
  pod 'BigInt', '~> 4.0', :binary => true
  pod 'CryptoSwift', :binary => true
  pod 'TrustWalletCore', '~> 2.6.29', :binary => true
  pod 'TrustKeystore', '~> 0.4.2', :binary => true
  pod 'WalletConnect', git: 'https://github.com/trustwallet/wallet-connect-swift', :binary => true
  pod 'TrustCore', '~> 0.0.7', :binary => true
  pod 'WalletConnectSwift', :binary => true
  pod 'Web3', :binary => true
  # pod 'web3swift', :git=>'https://github.com/BANKEX/web3swift', :branch=>'master'
end

def networkingPods
  pod 'APIKit', '~> 3.2.1', :binary => true
  pod 'JSONRPCKit', '~> 3.0.0', :binary => true #:git=> 'https://github.com/bricklife/JSONRPCKit.git'
  pod 'JavaScriptKit', '~> 1.0.0', :binary => true
  pod 'OneSignal', '>= 3.0.0', '< 4.0', :binary => true
  pod 'Starscream', '~> 3.1', :binary => true
  pod 'Kingfisher', '~> 7.0', :binary => true
  pod 'Moya', '~> 10.0.1', :binary => true
  pod 'Mixpanel-swift', :binary => true
end

def databasePods
  pod 'KeychainSwift', '~> 13.0.0', :binary => true
  pod 'SAMKeychain', '~> 1.5.3', :binary => true
  pod 'RealmSwift', '~> 3.19.0', :binary => true
end

def utilitiesPods
  pod 'LaunchDarkly', '~> 5.4', :binary => true
  pod 'Swinject', :binary => true
  pod 'SwiftLint', '~> 0.29.4', :binary => true
  pod 'Sentry', :git => 'https://github.com/getsentry/sentry-cocoa.git', :tag => '7.2.8', :binary => true
  pod 'Lokalise', '~> 0.8.1', :binary => true
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

  target 'KyberNetworkUITests' do
    inherit! :search_paths
    # Pods for testing
  end
  
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
