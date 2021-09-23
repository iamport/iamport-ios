//
// Created by BingBong on 2021/04/06.
//

import Foundation
import UIKit
import WebKit
import RxBus
import RxSwift
import RxRelay
import Then

class IamPortWebViewMode: UIView, WKUIDelegate {

    var disposeBag = DisposeBag()
    let viewModel = WebViewModel()

    var webview: WKWebView?
    var payment: Payment?

    func start(webview: WKWebView) {
        dlog("IamPortWebViewMode 어서오고")
        clearAll()
        self.webview = webview
        setupWebView()
        subscribePayment()
    }

    func close() {
        dlog("IamPortWebViewMode close")
        clearAll()
    }

    func clearWebView() {
        if let wv = webview {
            wv.configuration.userContentController.do { controller in
                for value in WebViewController.JsInterface.allCases {
                    controller.removeScriptMessageHandler(forName: value.rawValue)
                }
            }
            wv.stopLoading()
            wv.uiDelegate = nil
            wv.navigationDelegate = nil
        }
    }

    private func clearAll() {
        dlog("clearAll")
        clearWebView()
        payment = nil
        disposeBag = DisposeBag()
    }

    internal func setupWebView() {

        if let wv = webview {
            wv.configuration.userContentController.do { controller in
                for value in WebViewController.JsInterface.allCases {
                    controller.add(self, name: value.rawValue)
                }
            }

            wv.backgroundColor = UIColor.white
            viewModel.iamPortWKWebViewDelegate.do { delegate in
                wv.uiDelegate = delegate
                wv.navigationDelegate = delegate
            }
        }
    }

    internal func subscribePayment() {
        dlog("webviewmode subscribePayment")
        let eventBus = EventBus.shared

        // 결제 데이터
        eventBus.webViewPaymentBus.subscribe { [weak self] event in
            guard let el = event.element, let pay = el else {
                print("Error not found PaymentEvent")
                return
            }

            self?.subscribe(pay)
        }.disposed(by: disposeBag)
    }

    // isCertification 에 따라 bind 할 항목이 달라짐
    internal func subscribe(_ payment: Payment) {
        dlog("나왔니?")
        self.payment = payment
        if (payment.isCertification()) {
            dlog("subscribeCertification?")
            subscribeCertification(payment)
        } else {
            dlog("subscribePayment?")
            subscribePayment(payment)
        }
    }

    // 결제 데이터가 있을때 처리 할 이벤트들
    internal func subscribeCertification(_ payment: Payment) {
        dlog("subscribe webview mode certification")

        let bus = RxBus.shared
        let webViewEvents = EventBus.WebViewEvents.self

        bus.asObservable(event: webViewEvents.ImpResponse.self).subscribe { [weak self] event in
            guard let el = event.element else {
                print("Error not found ImpResponse")
                return
            }

            print("receive ImpResponse")
            self?.sdkFinish(el.impResponse)
        }.disposed(by: disposeBag)

        bus.asObservable(event: webViewEvents.OpenWebView.self).subscribe { [weak self] event in
            guard nil != event.element else {
                print("Error not found OpenWebView")
                return
            }
            self?.openWebView()
        }.disposed(by: disposeBag)

        bus.asObservable(event: webViewEvents.ThirdPartyUri.self).subscribe { [weak self] event in
            guard let el = event.element else {
                print("Error not found ThirdPartyUri")
                return
            }
            self?.openThirdPartyApp(el.thirdPartyUri)
        }.disposed(by: disposeBag)

        requestCertification(payment)
    }

    // 결제 데이터가 있을때 처리 할 이벤트들
    internal func subscribePayment(_ payment: Payment) {
        dlog("subscribe webview mode payment")

        let bus = RxBus.shared
        let webViewEvents = EventBus.WebViewEvents.self

        bus.asObservable(event: webViewEvents.ImpResponse.self).subscribe { [weak self] event in
            guard let el = event.element else {
                print("Error not found ImpResponse")
                return
            }

            print("receive ImpResponse")
            self?.sdkFinish(el.impResponse)
        }.disposed(by: disposeBag)

        bus.asObservable(event: webViewEvents.OpenWebView.self).subscribe { [weak self] event in
            guard nil != event.element else {
                print("Error not found OpenWebView")
                return
            }
            self?.openWebView()
        }.disposed(by: disposeBag)

        bus.asObservable(event: webViewEvents.ThirdPartyUri.self).subscribe { [weak self] event in
            guard let el = event.element else {
                print("Error not found ThirdPartyUri")
                return
            }
            self?.openThirdPartyApp(el.thirdPartyUri)
        }.disposed(by: disposeBag)

        subscribeForBankPay()
        requestPayment(payment)
    }

    internal func subscribeForBankPay() {

        let bus = RxBus.shared
        let events = EventBus.WebViewEvents.self

        // Start about Nice PG, Trans PayMethod Pair BankPay

        bus.asObservable(event: events.NiceTransRequestParam.self).subscribe { [weak self] event in
            guard let el = event.element else {
                print("Error not found NiceTransRequestParam")
                return
            }
            self?.openNiceTransApp(it: el.niceTransRequestParam)
        }.disposed(by: disposeBag)

        bus.asObservable(event: events.ReceivedAppDelegateURL.self).subscribe { [weak self] event in
            guard let el = event.element else {
                print("Error not found ReceivedAppDelegateURL")
                return
            }
            self?.processBankPayPayment(el.url)
        }.disposed(by: disposeBag)

        // also use inicis + trans pair
        bus.asObservable(event: events.FinalBankPayProcess.self).subscribe { [weak self] event in
            guard let el = event.element else {
                print("Error not found FinalBankPayProcess")
                return
            }
            self?.finalProcessBankPayPayment(el.url)
        }.disposed(by: disposeBag)

        // End about Nice PG, Trans PayMethod Pair BankPay
    }

    /**
     * 결제 요청 실행
     */
    internal func requestPayment(_ it: Payment) {
        if (!Utils.isInternetAvailable()) {
            sdkFinish(IamPortResponse.makeFail(payment: it, msg: "네트워크 연결 안됨"))
            return
        }

        viewModel.requestPayment(payment: it)
    }

    /**
     * 본인인증 요청 실행
     */
    internal func requestCertification(_ it: Payment) {
        if (!Utils.isInternetAvailable()) {
            sdkFinish(IamPortResponse.makeFail(payment: it, msg: "네트워크 연결 안됨"))
            return
        }

        viewModel.requestCertification(it)
    }


    /*
     모든 결과 처리 및 SDK 종료
     */
    func sdkFinish(_ iamPortResponse: IamPortResponse?) {
        print("명시적 sdkFinish")
        ddump(iamPortResponse)

//        navigationController?.popViewController(animated: false)
//        dismiss(animated: true) {
        close()
        EventBus.shared.impResponseRelay.accept(iamPortResponse)
//        }
    }

    /**
     * 뱅크페이 결과 처리 viewModel 에 요청
     */
    func processBankPayPayment(_ url: URL) {
        if let it = payment {
            // 나이스 PG 의 뱅크페이만 동작
            // 이니시스 PG 의 뱅크페이의 경우 페이지 전환 후 m_redirect_url 이 내려오므로 그걸 이용
            viewModel.processBankPayPayment(it, url)
        }
    }

    /**
     * 뱅크페이 결과 처리 viewModel 에 요청
     */
    func finalProcessBankPayPayment(_ url: URL) {
        dlog("finalProcessBankPayPayment :: \(url)")
        var request = URLRequest(url: url)
////        request.httpMethod = "POST" // 해보니까 굳이 post 날릴 필요 없는 것 같음
        DispatchQueue.main.async { [weak self] in
            self?.webview?.load(request)
        }
    }

    /**
     * 뱅크페이 외부앱 열기 for nice PG + 실시간계좌이체(trans)
     */
    private func openNiceTransApp(it: String) {
        if let url = URL(string: it) {
            openThirdPartyApp(url)
        }
    }


    func openThirdPartyApp(_ url: URL) {
        dlog("openThirdPartyApp \(url)")
        let result = Utils.openAppWithCanOpen(url) // 앱 열기
        if (!result) {

            // 한번 더 열어보고 취소시 앱스토어 이동
            Utils.justOpenApp(url) { [weak self] in
                if let scheme = url.scheme,
                   let urlString = AppScheme.getAppStoreUrl(scheme: scheme),
                   let url = URL(string: urlString) {
                    Utils.justOpenApp(url) // 앱스토어로 이동
                } else {
                    guard (self?.payment) != nil else {
                        self?.sdkFinish(nil)
                        return
                    }
                }
            }
        }
    }

    /**
     * 결제 요청 실행
     */
    private func openWebView() {
        dlog("오픈! 웹뷰 webview mode")

        let myPG = payment?.iamPortRequest?.pgEnum

//        func bundle() -> Bundle {
//            let spmBundle = Bundle.module // spm 에서 리소스 가져오는 방법임, 에러처럼 보이지만 xcode 빌드시 정상 동작(cmd + b)
//            guard let _ = spmBundle.url(forResource: CONST.CDN_FILE_NAME, withExtension: CONST.CDN_FILE_EXTENSION) else {
//                return Bundle(for: type(of: self)) // use for cocoapods
//            }
//            return spmBundle // use for swift package manager
//        }

//        let bundle = bundle()
        let bundle = Bundle.module

        var urlRequest: URLRequest? = nil // for webView load
        var htmlContents: String? = nil // for webView loadHtml(smilepay 자동 로그인)

        if (myPG == PG.smilepay) {
            if let filepath = bundle.path(forResource: CONST.CDN_FILE_NAME, ofType: CONST.CDN_FILE_EXTENSION) {
                htmlContents = try? String(contentsOfFile: filepath, encoding: .utf8)
            }
        } else {
            guard let url = bundle.url(forResource: CONST.CDN_FILE_NAME, withExtension: CONST.CDN_FILE_EXTENSION) else {
                print("html file url 비정상")
                return
            }

            ddump(url)

            urlRequest = URLRequest(url: url)
        }

        DispatchQueue.main.async { [weak self] in
            guard let wv = self?.webview else {
                self?.failFinish(errMsg: "webView 를 찾을 수 없습니다.")
                return
            }

            if (myPG == PG.smilepay) {
                if let base = URL(string: CONST.SMILE_PAY_BASE_URL),
                   let contents = htmlContents {
                    wv.loadHTMLString(contents, baseURL: base)
                }
            } else {
                if let request = urlRequest {
                    wv.load(request)
                }
            }
        }
    }

    func failFinish(errMsg: String) {
        if let pay = payment {
            IamPortResponse.makeFail(payment: pay, prepareData: nil, msg: errMsg).do { it in
                sdkFinish(it)
            }
        } else {
            sdkFinish(nil)
        }
    }
}


extension IamPortWebViewMode: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        dlog("body \(message.body)")

        if let jsMethod = WebViewController.JsInterface.convertJsInterface(s: message.name) {
            switch jsMethod {
            case .START_WORKING_SDK:
                print("JS SDK 통한 결제 시작 요청")

                guard let pay = payment else {
                    print(".START_WORKING_SDK payment 를 찾을 수 없음")
                    return
                }
                ddump(pay)

                let encoder = JSONEncoder()
                // encoder.outputFormatting = .prettyPrinted

                initSDK(userCode: pay.userCode, tierCode: pay.tierCode)

                if (pay.isCertification()) {
                    let jsonData = try? encoder.encode(pay.iamPortCertification)
                    certification(impCertificationJsonData: jsonData)
                } else {
                    let jsonData = try? encoder.encode(pay.iamPortRequest)
                    requestPay(impRequestJsonData: jsonData)
                }

            case .RECEIVED:
                print("Received from webview")

            case .CUSTOM_CALL_BACK:
                print("Received payment callback")
                if let data = (message.body as? String)?.data(using: .utf8),
                   let impStruct = try? JSONDecoder().decode(IamPortResponseStruct.self, from: data) {
                    let response = IamPortResponse.structToClass(impStruct)
                    sdkFinish(response)
                }

            case .DEBUG_CONSOLE_LOG:
                dlog("DEBUG_CONSOLE_LOG :: \(message.body)")
            }
        }
    }

    private func evaluateJS(method: String) {
        webview?.evaluateJavaScript(method)
    }

    private func initSDK(userCode: String, tierCode: String? = nil) {
        dlog("userCode : '\(userCode)', tierCode : '\(tierCode)'")

        var jsInitMethod = "init('\(userCode)');" // IMP.init
        if (!tierCode.nilOrEmpty) {
            jsInitMethod = "agency('\(userCode)', '\(String(describing: tierCode))');" // IMP.agency
        }

        evaluateJS(method: jsInitMethod)
    }

    private func requestPay(impRequestJsonData: Data?) {
        if let json = impRequestJsonData,
           let request = String(data: json, encoding: .utf8) {
            dlog("requestPay request : '\(request)'")
            evaluateJS(method: "requestPay('\(request)');")
        }
    }

    private func certification(impCertificationJsonData: Data?) {
        if let json = impCertificationJsonData,
           let request = String(data: json, encoding: .utf8) {
            dlog("certification request : '\(request)'")
            evaluateJS(method: "certification('\(request)');")
        }
    }

}

