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
        sdk?.clearData()
        sdk = nil
        paymentResult = nil
    }

    private func paymentStart(sdk: IamportSdk, userCode: String, iamPortRequest: IamPortRequest, approveCallback: ((IamPortApprove) -> Void)? = nil, paymentResultCallback: @escaping (IamPortResponse?) -> Void) {
        paymentResult = paymentResultCallback
        self.sdk = sdk
        sdk.initStart(payment: Payment(userCode: userCode, iamPortRequest: iamPortRequest), approveCallback: approveCallback, paymentResultCallback: paymentResultCallback)
    }


    private func certStart(sdk: IamportSdk, userCode: String, iamPortCertification: IamPortCertification, certificationResultCallback: @escaping (IamPortResponse?) -> Void) {
        paymentResult = certificationResultCallback
        self.sdk = sdk
        sdk.initStart(payment: Payment(userCode: userCode, iamPortCertification: iamPortCertification), certificationResultCallback: certificationResultCallback)
    }

    /**
     아임포트 SDK에 결제 요청
     - Parameters:
       - navController: ThirdParty 앱 및 웹뷰 컨트롤러를 띄우기 위한 UINavigationController
       - userCode: 아임포트 머천트 식별코드
       - iamPortRequest: 결제요청 데이터
       - paymentResultCallback: 결제 후 콜백 함수
     */
    public func payment(navController: UINavigationController?, userCode: String, iamPortRequest: IamPortRequest, approveCallback: ((IamPortApprove) -> Void)? = nil, paymentResultCallback: @escaping (IamPortResponse?) -> Void) {
        print("IamPort SDK payment for navController mode")
        clear()

        guard let nc = navController else {
            print("UINavigationController 를 찾을 수 없습니다")
            return
        }

        paymentStart(sdk : IamportSdk(naviController: nc), userCode: userCode, iamPortRequest: iamPortRequest, approveCallback: approveCallback, paymentResultCallback: paymentResultCallback)
    }

    public func payment(viewController: UIViewController?, userCode: String, iamPortRequest: IamPortRequest, approveCallback: ((IamPortApprove) -> Void)? = nil, paymentResultCallback: @escaping (IamPortResponse?) -> Void) {
        print("IamPort SDK payment for viewController mode")
        clear()

        guard let vc = viewController else {
            print("UIViewController 를 찾을 수 없습니다")
            return
        }

        paymentStart(sdk : IamportSdk(viewController: vc), userCode: userCode, iamPortRequest: iamPortRequest, approveCallback: approveCallback, paymentResultCallback: paymentResultCallback)
    }


    public func paymentWebView(webview: WKWebView?, userCode: String, iamPortRequest: IamPortRequest, approveCallback: ((IamPortApprove) -> Void)? = nil, paymentResultCallback: @escaping (IamPortResponse?) -> Void) {
        print("IamPort SDK payment for webview mode")
        clear()

        guard let wv = webview else {
            print("WKWebView 를 찾을 수 없습니다")
            return
        }

        paymentStart(sdk : IamportSdk(webview: wv), userCode: userCode, iamPortRequest: iamPortRequest, approveCallback: approveCallback, paymentResultCallback: paymentResultCallback)
    }

    /**
     아임포트 SDK에 본인인증 요청
     - Parameters:
       - navController: ThirdParty 웹뷰 컨트롤러를 띄우기 위한 UINavigationController
       - userCode: 아임포트 머천트 식별코드
       - iamPortCertification: 본인인증 요청 데이터
       - paymentResultCallback: 결제 후 콜백 함수
     */
    public func certification(navController: UINavigationController?, userCode: String, iamPortCertification: IamPortCertification, certificationResultCallback: @escaping (IamPortResponse?) -> Void) {
        print("IamPort SDK certification")
        clear()

        guard let nc = navController else {
            print("UINavigationController 를 찾을 수 없습니다")
            return
        }

        certStart(sdk : IamportSdk(naviController: nc), userCode: userCode, iamPortCertification: iamPortCertification, certificationResultCallback: certificationResultCallback)
    }

    public func certification(viewController: UIViewController?, userCode: String, iamPortCertification: IamPortCertification, certificationResultCallback: @escaping (IamPortResponse?) -> Void) {
        print("IamPort SDK certification")
        clear()

        guard let vc = viewController else {
            print("UIViewController 를 찾을 수 없습니다")
            return
        }

        certStart(sdk : IamportSdk(viewController: vc), userCode: userCode, iamPortCertification: iamPortCertification, certificationResultCallback: certificationResultCallback)
    }

    public func certification(webview: WKWebView?, userCode: String, iamPortCertification: IamPortCertification, certificationResultCallback: @escaping (IamPortResponse?) -> Void) {
        print("IamPort SDK certification")
        clear()

        guard let wv = webview else {
            print("WKWebView 를 찾을 수 없습니다")
            return
        }

        certStart(sdk : IamportSdk(webview: wv), userCode: userCode, iamPortCertification: iamPortCertification, certificationResultCallback: certificationResultCallback)
    }

    // 외부 앱 종료후 AppDelegate 에서 받은 URL
    public func receivedURL(_ url: URL) {
        print("IamPort SDK receivedURL")
        sdk?.postReceivedURL(url)
    }

    /**
     * 외부에서 차이 최종결제 요청
     */
    public func approvePayment(approve: IamPortApprove) {
        sdk?.requestApprovePayments(approve: approve)
    }

    public func close() {
        print("IamPort SDK close")
        clear()
    }
}
