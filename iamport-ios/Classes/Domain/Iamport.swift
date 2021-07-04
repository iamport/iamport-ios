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
    private var animate = true
    private var useNaviButton = false

    init() {
        // WebView 쿠키 enable 위해 추가
        HTTPCookieStorage.shared.cookieAcceptPolicy = HTTPCookie.AcceptPolicy.always
    }

    private func clear() {
        sdk?.clearData()
        sdk = nil
        paymentResult = nil
    }

    private func paymentStart(sdk: IamportSdk, userCode: String, tierCode: String? = nil, iamPortRequest: IamPortRequest, approveCallback: ((IamPortApprove) -> Void)? = nil, paymentResultCallback: @escaping (IamPortResponse?) -> Void) {
        paymentResult = paymentResultCallback
        self.sdk = sdk
        sdk.animate = animate
        sdk.useNaviButton = useNaviButton
        sdk.initStart(payment: Payment(userCode: userCode, tierCode: tierCode, iamPortRequest: iamPortRequest), approveCallback: approveCallback, paymentResultCallback: paymentResultCallback)
    }


    private func certStart(sdk: IamportSdk, userCode: String, tierCode: String? = nil, iamPortCertification: IamPortCertification, certificationResultCallback: @escaping (IamPortResponse?) -> Void) {
        paymentResult = certificationResultCallback
        self.sdk = sdk
        sdk.animate = animate
        sdk.useNaviButton = useNaviButton
        sdk.initStart(payment: Payment(userCode: userCode, tierCode: tierCode, iamPortCertification: iamPortCertification), certificationResultCallback: certificationResultCallback)
    }

    /**
     아임포트 SDK에 결제 요청
     - Parameters:
       - navController: ThirdParty 앱 및 웹뷰 컨트롤러를 띄우기 위한 UINavigationController
       - userCode: 아임포트 머천트 식별코드
       - iamPortRequest: 결제요청 데이터
       - paymentResultCallback: 결제 후 콜백 함수
     */

    public func payment(navController: UINavigationController, userCode: String, tierCode: String? = nil, iamPortRequest: IamPortRequest, approveCallback: ((IamPortApprove) -> Void)? = nil, paymentResultCallback: @escaping (IamPortResponse?) -> Void) {
        print("IamPort SDK payment for navController mode")
        clear()

        paymentStart(sdk: IamportSdk(naviController: navController), userCode: userCode, tierCode: tierCode, iamPortRequest: iamPortRequest, approveCallback: approveCallback, paymentResultCallback: paymentResultCallback)
    }

    public func payment(viewController: UIViewController, userCode: String, tierCode: String? = nil, iamPortRequest: IamPortRequest, approveCallback: ((IamPortApprove) -> Void)? = nil, paymentResultCallback: @escaping (IamPortResponse?) -> Void) {
        print("IamPort SDK payment for viewController mode")
        clear()

        paymentStart(sdk: IamportSdk(viewController: viewController), userCode: userCode, tierCode: tierCode, iamPortRequest: iamPortRequest, approveCallback: approveCallback, paymentResultCallback: paymentResultCallback)
    }


    public func paymentWebView(webViewMode: WKWebView, userCode: String, tierCode: String? = nil, iamPortRequest: IamPortRequest, approveCallback: ((IamPortApprove) -> Void)? = nil, paymentResultCallback: @escaping (IamPortResponse?) -> Void) {
        print("IamPort SDK payment for webview mode")
        clear()

        paymentStart(sdk: IamportSdk(webViewMode: webViewMode), userCode: userCode, tierCode: tierCode, iamPortRequest: iamPortRequest, approveCallback: approveCallback, paymentResultCallback: paymentResultCallback)
    }

    /**
     Mobile Web Mode 를 사용합니다. (WKWebView 를 넘기고, 결제요청 또한 JS 에서 사용)
     - Parameter mobileWebMode: url 을 로드한 WKWebView 파라미터
     */
    public func pluginMobileWebSupporter(mobileWebMode: WKWebView) {
        print("IamPort SDK payment for mobileweb mode")
        clear()

        sdk = IamportSdk(mobileWebMode: mobileWebMode) // 생성 및 mobileWebMode 실행
    }

    public func setAnimate(animate: Bool) {
        self.animate = animate
    }

    public func useNaviButton(enable: Bool) {
        useNaviButton = enable
    }

    /**
     아임포트 SDK에 본인인증 요청
     - Parameters:
       - navController: ThirdParty 웹뷰 컨트롤러를 띄우기 위한 UINavigationController
       - userCode: 아임포트 머천트 식별코드
       - iamPortCertification: 본인인증 요청 데이터
       - paymentResultCallback: 결제 후 콜백 함수
     */
    public func certification(navController: UINavigationController, userCode: String, tierCode: String? = nil, iamPortCertification: IamPortCertification, certificationResultCallback: @escaping (IamPortResponse?) -> Void) {
        print("IamPort SDK certification")
        clear()

        certStart(sdk: IamportSdk(naviController: navController), userCode: userCode, tierCode: tierCode, iamPortCertification: iamPortCertification, certificationResultCallback: certificationResultCallback)
    }

    public func certification(viewController: UIViewController, userCode: String, tierCode: String? = nil, iamPortCertification: IamPortCertification, certificationResultCallback: @escaping (IamPortResponse?) -> Void) {
        print("IamPort SDK certification")
        clear()

        certStart(sdk: IamportSdk(viewController: viewController), userCode: userCode, tierCode: tierCode, iamPortCertification: iamPortCertification, certificationResultCallback: certificationResultCallback)
    }

    public func certification(webview: WKWebView, userCode: String, tierCode: String? = nil, iamPortCertification: IamPortCertification, certificationResultCallback: @escaping (IamPortResponse?) -> Void) {
        print("IamPort SDK certification")
        clear()

        certStart(sdk: IamportSdk(webViewMode: webview), userCode: userCode, tierCode: tierCode, iamPortCertification: iamPortCertification, certificationResultCallback: certificationResultCallback)
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
        print("IamPort SDK clear")
        clear()
    }
}
