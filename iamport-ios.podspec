#
# Be sure to run `pod lib lint iamport-ios.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'iamport-ios'
  s.version          = '1.3.2'
  s.summary          = 'iamport-ios will help develop for your iOS App payments'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
  iamport-ios will help develop for your iOS App payments
  Please contact us!
                       DESC

  s.homepage         = 'https://github.com/iamport/iamport-ios'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'bingbong' => 'bingbong@chai.finance' }
  s.source           = { :git => 'https://github.com/iamport/iamport-ios.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'
  
  s.swift_versions = '5.0'
  s.ios.deployment_target = '10.0'
  
  s.source_files = 'Sources/iamport-ios/Classes/**/*'
  
#   s.resource_bundles = {
#     'iamport-ios' => ['Sources/iamport-ios/Assets/**/*']
#   }

   s.resources = "Sources/iamport-ios/Assets/**/*"

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
   
    s.dependency 'Then'

    s.dependency 'Swinject'
       
    # 대표적인 네트워크 라이브러리입니다.
    s.dependency 'Alamofire', '~> 5.1'

    # Pods for RxSwift+MVVM
    s.dependency 'RxBusForPort'
    s.dependency 'RxSwift', '~> 6.0'
    s.dependency 'RxCocoa'
    s.dependency 'RxRelay'
    s.dependency 'RxOptional'
    s.dependency 'RxViewController'


end
