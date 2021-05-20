
# :seedling: I'mport iOS SDK :seedling:

# iamport-ios

[![CI Status](https://www.travis-ci.com/iamport/iamport-ios.svg?style=flat)](https://www.travis-ci.com/github/iamport/iamport-ios)
[![Version](https://img.shields.io/cocoapods/v/iamport-ios.svg?style=flat)](https://cocoapods.org/pods/iamport-ios)
[![License](https://img.shields.io/cocoapods/l/iamport-ios.svg?style=flat)](https://cocoapods.org/pods/iamport-ios)
[![Platform](https://img.shields.io/cocoapods/p/iamport-ios.svg?style=flat)](https://cocoapods.org/pods/iamport-ios)



## 설명

iOS 네이티브 앱에서 결제 개발을 간편하게 도와주는 아임포트 SDK 입니다.

- CHAI 간편결제는 Native 연동되어 있습니다.

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

## iOS plist 설정방법

<details>
<summary>iOS 설정 펼쳐보기</summary>

# iOS 설정하기

iOS에서 아임포트 결제연동 모듈을 사용하기 위해서는 아래 3가지 항목을 설정해주셔야 합니다.

#### 1. App Scheme 등록
외부 결제 앱(예) 페이코, 신한 판 페이)에서 결제 후 돌아올 때 사용할 URL identifier를 설정해야합니다.

![](https://github.com/iamport/iamport-react-native/blob/master/src/img/app-scheme-registry.gif)

1. `[프로젝트 폴더]/ios/[프로젝트 이름]/info.plist` 파일을 연 후 `URL types`속성을 추가합니다.
2. item `0`를 확장하여 `URL schemes`를 선택합니다.
3. item `0`에 App Scheme을 작성합니다.


#### 2. 외부 앱 리스트 등록
3rd party앱(예) 간편결제 앱)을 실행할 수 있도록 외부 앱 리스트를 등록해야합니다. 

1. `[프로젝트 폴더]/ios/[프로젝트 이름]/info.plist` 파일을 오픈합니다.
2. [LSApplicationQueriesSchemes](https://developer.apple.com/library/content/documentation/General/Reference/InfoPlistKeyReference/Articles/LaunchServicesKeys.html#//apple_ref/doc/uid/TP40009250-SW14)속성을 추가하고 아래에 외부 앱 리스트를 등록합니다.

```html
<key>LSApplicationQueriesSchemes</key>
<array>
  <string>kftc-bankpay</string> <!-- 계좌이체 -->
  <string>ispmobile</string> <!-- ISP모바일 -->
  <string>itms-apps</string> <!-- 앱스토어 -->
  <string>hdcardappcardansimclick</string> <!-- 현대카드-앱카드 -->
  <string>smhyundaiansimclick</string> <!-- 현대카드-공인인증서 -->
  <string>shinhan-sr-ansimclick</string> <!-- 신한카드-앱카드 -->
  <string>smshinhanansimclick</string> <!-- 신한카드-공인인증서 -->
  <string>kb-acp</string> <!-- 국민카드-앱카드 -->
  <string>mpocket.online.ansimclick</string> <!-- 삼성카드-앱카드 -->
  <string>ansimclickscard</string> <!-- 삼성카드-온라인결제 -->
  <string>ansimclickipcollect</string> <!-- 삼성카드-온라인결제 -->
  <string>vguardstart</string> <!-- 삼성카드-백신 -->
  <string>samsungpay</string> <!-- 삼성카드-삼성페이 -->
  <string>scardcertiapp</string> <!-- 삼성카드-공인인증서 -->
  <string>lottesmartpay</string> <!-- 롯데카드-모바일결제 -->
  <string>lotteappcard</string> <!-- 롯데카드-앱카드 -->
  <string>cloudpay</string> <!-- 하나카드-앱카드 -->
  <string>nhappcardansimclick</string> <!-- 농협카드-앱카드 -->
  <string>nonghyupcardansimclick</string> <!-- 농협카드-공인인증서 -->
  <string>citispay</string> <!-- 씨티카드-앱카드 -->
  <string>citicardappkr</string> <!-- 씨티카드-공인인증서 -->
  <string>citimobileapp</string> <!-- 씨티카드-간편결제 -->
  <string>kakaotalk</string> <!-- 카카오톡 -->
  <string>payco</string> <!-- 페이코 -->
  <string>lpayapp</string> <!-- 롯데 L페이 -->
  <string>hanamopmoasign</string> <!-- 하나카드 공인인증앱 -->
  <string>wooripay</string> <!-- 우리페이 -->
  <string>nhallonepayansimclick</string> <!-- NH 올원페이 -->
  <string>hanawalletmembers</string> <!-- 하나카드(하나멤버스 월렛) -->
  <string>chaipayment</string> <!-- 차이 -->
  <string>kb-auth</string>
  <string>hyundaicardappcardid</string>
  <string>com.wooricard.wcard</string>
  <string>lmslpay</string>
  
</array>
```


#### 3. App Transport Security 설정
![](https://github.com/iamport/iamport-react-native/blob/master/src/img/allow-arbitrary.gif)

1. `[프로젝트 폴더]/ios/[프로젝트 이름]/info.plist` 파일을 오픈합니다.
2. `App Transport Security` 속성을 추가합니다.
3. 하부 속성에 `Allow Arbitrary Loads in Web Content`,`Allow Arbitrary Loads` 속성을 추가하고 각각의 값(value)을 `YES`로 변경합니다.

```html
<key>NSAppTransportSecurity</key>
<dict>
  <key>NSAllowsArbitraryLoadsInWebContent</key>
  <true/>
  <key>NSAllowsArbitraryLoads</key>
  <true/>
</dict>
```

</details>


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
                pg: PG.html5_inicis.getPgSting(pgId: ""), // PG 사
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


```swift
  // AppDelegate.swift 설정
  func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
      Iamport.shared.receivedURL(url)
      return true
  }
```

## 💡 샘플앱


[앱 소스 확인 경로](./Example/iamport-ios)


실행방법 

1. git clone 
2. Xcode project open
3. connect iPhone via USB Cable(or use Simulator)
4. build [Example app](./Example)



## Author

I'mport, support@chai.finance

## License

iamport-ios is available under the MIT license. See the LICENSE file for more info.
