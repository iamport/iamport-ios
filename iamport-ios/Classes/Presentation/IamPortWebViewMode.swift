//
// Created by BingBong on 2021/04/06.
//

import Foundation
import UIKit
import WebKit
import RxBus
import RxSwift
import RxRelay

class IamPortWebViewMode: UIView, WKUIDelegate {

    // for communicate WebView
    enum JsInterface: String, CaseIterable {
        case RECEIVED = "received"
        case START_WORKING_SDK = "startWorkingSdk"
        case CUSTOM_CALL_BACK = "customCallback"
        case DEBUG_CONSOLE_LOG = "debugConsoleLog"

        static func convertJsInterface(s: String) -> JsInterface? {
            for value in self.allCases {
                if (s == value.rawValue) {
                    return value
                }
            }
            return nil
        }
    }

    var disposeBag = DisposeBag()
    let viewModel = WebViewModel()

    var webview: WKWebView?
    var payment: Payment?

    func start(webview: WKWebView) {
        dlog("IamPortWebViewMode 어서오고")
        self.webview = webview
        setupWebView()
        subscribePayment()
    }

    func close(webview: WKWebView) {
        dlog("IamPortWebViewMode close")
        clearAll()
    }

    private func clearWebView() {
        if let wv = webview {
            wv.stopLoading()
//            wv.removeFromSuperview()
            wv.uiDelegate = nil
            wv.navigationDelegate = nil
        }
//        webview = nil
    }

    private func clearAll() {
        clearWebView()
//        view.removeFromSuperview()
        payment = nil
        disposeBag = DisposeBag()
    }

    private func setupWebView() {

        clearWebView()

        let userController = WKUserContentController().then { controller in
            controller.add(self, name: JsInterface.RECEIVED.rawValue)
            controller.add(self, name: JsInterface.START_WORKING_SDK.rawValue)
            controller.add(self, name: JsInterface.CUSTOM_CALL_BACK.rawValue)
            controller.add(self, name: JsInterface.DEBUG_CONSOLE_LOG.rawValue)
        }

        let config = WKWebViewConfiguration.init().then { configuration in
            configuration.userContentController = userController
        }

//        webview = WKWebView.init(frame: view.frame, configuration: config).then { (wv: WKWebView) in
        if let wv = webview {
            wv.backgroundColor = UIColor.white
//            wv.frame = view.bounds

//            view.addSubview(wv)

            wv.uiDelegate = self
            wv.navigationDelegate = self
        }
    }

    private func subscribePayment() {
        let eventBus = EventBus.shared

        // 외부 종료 시그널
        eventBus.clearBus.subscribe { [weak self] in
            print("clearBus")
            self?.sdkFinish(nil) // data clear 는 viewWillDisappear 에서 처리
        }.disposed(by: disposeBag)

        // 결제 데이터
        EventBus.shared.webViewPaymentBus.subscribe { [weak self] event in
            guard let el = event.element, let pay = el else {
                print("Error not found PaymentEvent")
                return
            }

            self?.subscribe(pay)
        }.disposed(by: disposeBag)
    }

    // isCertification 에 따라 bind 할 항목이 달라짐
    private func subscribe(_ payment: Payment) {
        if (payment.isCertification()) {
            subscribeCertification(payment)
        } else {
            subscribePayment(payment)
        }
    }

    // 결제 데이터가 있을때 처리 할 이벤트들
    private func subscribeCertification(_ payment: Payment) {
        self.payment = payment

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
    private func subscribePayment(_ payment: Payment) {
        print("subscribe")

        self.payment = payment
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

    private func subscribeForBankPay() {

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

        // also use inisis + trans pair
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
    private func requestPayment(_ it: Payment) {
        if (!Utils.isInternetAvailable()) {
            sdkFinish(IamPortResponse.makeFail(payment: it, msg: "네트워크 연결 안됨"))
            return
        }

        viewModel.requestPayment(payment: it)
    }

    /**
     * 본인인증 요청 실행
     */
    private func requestCertification(_ it: Payment) {
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
     * 나이스 뱅크페이 결과 처리 viewModel 에 요청
     */
    func finalProcessBankPayPayment(_ url: URL) {
        dlog("finalProcessBankPayPayment :: \(url)")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
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
            if let scheme = url.scheme,
               let urlString = AppScheme.getAppStoreUrl(scheme: scheme),
               let url = URL(string: urlString) {
                Utils.justOpenApp(url) // 앱스토어로 이동
            } else {

                guard let pay = payment else {
                    sdkFinish(nil)
                    return
                }

//                let response = IamPortResponse.makeFail(payment: pay, msg: "지원하지 않는 App Scheme \(String(describing: url.scheme)) 입니다")
//                sdkFinish(response)
                Utils.justOpenApp(url) // 걍 열엇
            }
        }
    }

    /**
     * 결제 요청 실행
     */
    private func openWebView() {
        print("오픈! 웹뷰")


        let myPG = payment?.iamPortRequest?.pgEnum
        let bundle = Bundle(for: type(of: self))

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
}


extension IamPortWebViewMode: WKNavigationDelegate {


    @available(iOS 8.0, *)
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        // url 변경 시점

        if let url = navigationAction.request.url {

            RxBus.shared.post(event: EventBus.WebViewEvents.UpdateUrl(url: url))

            let policy = Utils.getActionPolicy(url)
            decisionHandler(policy ? .cancel : .allow)
        } else {
            decisionHandler(.cancel)
            failFinish(errMsg: "URL 을 찾을 수 없습니다")
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("didFail \(error.localizedDescription)")
//        failFinish(errMsg: "탐색중 에러가 발생하였습니다 ::  \(error.localizedDescription)")
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        print("didFailProvisionalNavigation \(error.localizedDescription)")
//        failFinish(errMsg: "컨텐츠 로드중 에러가 발생하였습니다 :: \(error.localizedDescription)")
    }

    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        let alertController = UIAlertController(title: message, message: nil, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "확인", style: .default) { _ in
            completionHandler()
        }
        alertController.addAction(okAction)
        DispatchQueue.main.async {
//            self.present(alertController, animated: true, completion: nil)

            if let window = self.window, let controller = window.rootViewController {
                controller.present(alertController, animated: true, completion: nil)
            }
        }
    }

    // for Alert(for 주로 모빌리언스 + 휴대폰 소액결제 Pair)
    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        let alertController = UIAlertController(title: message, message: nil, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "취소", style: .cancel) { _ in
            completionHandler(false)
        }
        let okAction = UIAlertAction(title: "확인", style: .default) { _ in
            completionHandler(true)
        }
        alertController.addAction(cancelAction)
        alertController.addAction(okAction)
        DispatchQueue.main.async {
//            self.present(alertController, animated: true, completion: nil)

            if let window = self.window, let controller = window.rootViewController {
                controller.present(alertController, animated: true, completion: nil)
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

        if let jsMethod = JsInterface.convertJsInterface(s: message.name) {
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
                dlog("DEBUG_CONSOLE_LOG :: \(message)")
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
