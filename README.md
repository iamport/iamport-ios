# :seedling: I'mport iOS SDK :seedling:

# iamport-ios

[![CI Status](https://img.shields.io/travis/bingbong/iamport-ios.svg?style=flat)](https://travis-ci.org/bingbong/iamport-ios)
[![Version](https://img.shields.io/cocoapods/v/iamport-ios.svg?style=flat)](https://cocoapods.org/pods/iamport-ios)
[![License](https://img.shields.io/cocoapods/l/iamport-ios.svg?style=flat)](https://cocoapods.org/pods/iamport-ios)
[![Platform](https://img.shields.io/cocoapods/p/iamport-ios.svg?style=flat)](https://cocoapods.org/pods/iamport-ios)



## 설명

iOS 네이티브 앱에서 결제 개발을 간편하게 도와주는 아임포트 SDK 입니다.

- 여러 PG 들을 WebView 기반으로 결제 할 수 있습니다.

- 추후 순차적으로 타 간편결제들도 네이티브 연동 예정입니다. 

--- 

- [아임포트][1]

- [아임포트 블로그][2]

- [아임포트 docs][3]

[1]: https://www.iamport.kr/
[2]: http://blog.iamport.kr/
[3]: https://docs.iamport.kr/?lang=ko


---

- iOS 설정방법

- [참조 : react native iOS 설정][4]

[4]: https://github.com/iamport/iamport-react-native/blob/master/manuals/SETTING.md

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

## Installation

iamport-ios is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'iamport-ios'
```

## Usage

> - Navigation Controller 생성.  
  storyboard 의 root view controller 에서.  
  Xcode 상단 -> Editor -> Embed in -> Navigation Controller.  

```swift
  // 결제 요청 데이터 구성 
  let request = IamPortRequest(
                pg: PG.html5_inicis.getPgSting(storeId: ""), // PG 사
                merchant_uid: "mid_123456",                   // 주문번호                
                amount: "1000").then {                        // 가격
                  $0.pay_method = PayMethod.card              // 결제수단
                  $0.name = "샘플 머천트에서 주문~"                // 주문명
                  $0.buyer_name = "독고독"                     
                  $0.app_scheme = "iamport"                   // 결제 후 앱으로 복귀 위한 app scheme
              }

  // I'mport SDK 에 결제 요청
  Iamport.shared.payment(navController: navigationController, // 네비게이션 컨트롤러
                         userCode: userCode, // 머천트 유저 식별 코드
                         iamPortRequest: request) // 결제 요청 데이터
                         { [weak self] iamPortResponse in
                            // 결제 종료 콜백
                         }
                         
  Iamport.shared.close() // sdk 종료 원할시 호출
```

## Author

bingbong, akrasias2@naver.com

## License

iamport-ios is available under the MIT license. See the LICENSE file for more info.
