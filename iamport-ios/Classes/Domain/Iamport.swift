//
// Created by BingBong on 2021/01/05.
//

import Foundation
import WebKit

// 머천트에서 직접 가져다가 쓰는 부분
open class Iamport {

    public static let shared = Iamport()

    private var sdk: IamportSdk?
    private var paymentResult: ((IamPortResponse?) -> Void)? // 결제 결과 callback

    init() {
        // WebView 쿠키 enable 위해 추가
        HTTPCookieStorage.shared.cookieAcceptPolicy = HTTPCookie.AcceptPolicy.always
    }

    private func clear() {
        sdk = nil
        paymentResult = nil
    }

    /**
     아임포트 SDK에 결제 요청
     - Parameters:
       - navController: ThirdParty 앱 및 웹뷰 컨트롤러를 띄우기 위한 UINavigationController
       - userCode: 아임포트 머천트 식별코드
       - iamPortRequest: 결제요청 데이터
       - paymentResultCallback: 결제 후 콜백 함수
     */
    public func payment(navController: UINavigationController?, userCode: String, iamPortRequest: IamPortRequest, _ paymentResultCallback: @escaping (IamPortResponse?) -> Void) {
        clear()
//        preventOverlapRun?.launch {
//            corePayment(userCode, iamPortRequest, approveCallback, paymentResultCallback)
//        }

        guard let nc = navController else {
            print("UINavigationController 를 찾을 수 없습니다")
            return
        }

        paymentResult = paymentResultCallback
        sdk = IamportSdk(nc)
        sdk?.initStart(payment: Payment(userCode: userCode, iamPortRequest: iamPortRequest), paymentResultCallback: paymentResultCallback)
    }

    // 외부 앱 종료후 AppDelegate 에서 받은 URL
    public func receivedURL(_ url: URL) {
        sdk?.postReceivedURL(url)
    }

    public func close() {
        sdk?.clearData()
    }
}
