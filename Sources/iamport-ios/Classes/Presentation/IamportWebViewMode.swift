//
// Created by BingBong on 2021/04/06.
//

import Foundation
import RxRelay
import RxSwift
import Then
import UIKit
import WebKit

class IamportWebViewMode: UIView, WKUIDelegate {
    var disposeBag = DisposeBag()
    let viewModel: WebViewModel

    var webview: WKWebView?
    var request: IamportRequest?
    init(eventBus: EventBus) {
        self.viewModel = WebViewModel(eventBus: eventBus)
        super.init(frame: .zero)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func start(webview: WKWebView) {
        debug_log("IamportWebViewMode :: start")
        clearAll()
        self.webview = webview
        setupWebView()
        subscribePayment()
    }

    func close() {
        debug_log("IamportWebViewMode :: close")
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
        debug_log("IamportWebViewMode :: clearAll")
        clearWebView()
        request = nil
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
            viewModel.delegate.do { delegate in
                wv.uiDelegate = delegate
                wv.navigationDelegate = delegate
            }
        }
    }

    internal func subscribePayment() {
        debug_log("IamportWebViewMode :: subscribePayment")

        // 결제 데이터
        viewModel.eventBus.webViewPaymentBus.subscribe { [weak self] event in
            guard let elem = event.element, let payment = elem else {
                print("IamportWebViewMode :: Error not found PaymentEvent")
                return
            }

            self?.subscribe(payment)
        }.disposed(by: disposeBag)
    }

    // isCertification 에 따라 bind 할 항목이 달라짐
    internal func subscribe(_ request: IamportRequest) {
        debug_log("IamportWebViewMode :: subscribe")
        self.request = request
        if request.isCertification {
            debug_log("IamportWebViewMode :: subscribeCertification")
            subscribeCertification(request)
        } else {
            debug_log("IamportWebViewMode :: subscribePayment")
            subscribePayment(request)
        }
    }

    // 본인인증 데이터가 있을때 처리 할 이벤트들
    internal func subscribeCertification(_ request: IamportRequest) {
        debug_log("IamportWebViewMode :: subscribeCertification")

        let bus = RxBus.shared
        let webViewEvents = EventBus.WebViewEvents.self

        bus.asObservable(event: webViewEvents.ImpResponse.self).subscribe { [weak self] event in
            guard let el = event.element else {
                print("IamportWebViewMode :: Cannot find ImpResponse")
                return
            }

            print("IamportWebViewMode :: ImpResponse received")
            self?.sdkFinish(el.impResponse)
        }.disposed(by: disposeBag)

        bus.asObservable(event: webViewEvents.OpenWebView.self).subscribe { [weak self] event in
            guard event.element != nil else {
                print("IamportWebViewMode :: Error not found OpenWebView")
                return
            }
            self?.openWebView()
        }.disposed(by: disposeBag)

        bus.asObservable(event: webViewEvents.ThirdPartyUri.self).subscribe { [weak self] event in
            guard let el = event.element else {
                print("IamportWebViewMode :: Error not found ThirdPartyUri")
                return
            }
            self?.openThirdPartyApp(el.thirdPartyUri)
        }.disposed(by: disposeBag)

        requestCertification(request)
    }

    // 결제 데이터가 있을때 처리 할 이벤트들
    internal func subscribePayment(_ request: IamportRequest) {
        debug_log("IamportWebViewMode :: subscribePayment")

        let bus = RxBus.shared
        let webViewEvents = EventBus.WebViewEvents.self

        bus.asObservable(event: webViewEvents.ImpResponse.self).subscribe { [weak self] event in
            guard let el = event.element else {
                print("IamportWebViewMode :: Cannot find ImpResponse")
                return
            }

            print("IamportWebViewMode :: receive ImpResponse")
            self?.sdkFinish(el.impResponse)
        }.disposed(by: disposeBag)

        bus.asObservable(event: webViewEvents.OpenWebView.self).subscribe { [weak self] event in
            guard event.element != nil else {
                print("IamportWebViewMode :: Cannot find OpenWebView")
                return
            }
            self?.openWebView()
        }.disposed(by: disposeBag)

        bus.asObservable(event: webViewEvents.ThirdPartyUri.self).subscribe { [weak self] event in
            guard let el = event.element else {
                print("IamportWebViewMode :: Error not found ThirdPartyUri")
                return
            }
            self?.openThirdPartyApp(el.thirdPartyUri)
        }.disposed(by: disposeBag)

        subscribeForBankPay()
        requestPayment(request)
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
    internal func requestPayment(_ it: IamportRequest) {
        if !Utils.isInternetAvailable() {
            sdkFinish(IamportResponse.makeFail(request: it, msg: "네트워크 연결 안됨"))
            return
        }

        viewModel.requestPayment(request: it)
    }

    /**
     * 본인인증 요청 실행
     */
    internal func requestCertification(_ it: IamportRequest) {
        if !Utils.isInternetAvailable() {
            sdkFinish(IamportResponse.makeFail(request: it, msg: "네트워크 연결 안됨"))
            return
        }

        viewModel.requestCertification(it)
    }

    /**
     * 모든 결과 처리 및 SDK 종료
     */
    func sdkFinish(_ iamportResponse: IamportResponse?) {
        print("명시적 sdkFinish")
        debug_dump(iamportResponse)

        close()
        viewModel.eventBus.impResponseRelay.accept(iamportResponse)
    }

    /**
     * 뱅크페이 결과 처리 viewModel 에 요청
     */
    func processBankPayPayment(_ url: URL) {
        if let it = request {
            // 나이스 PG 의 뱅크페이만 동작
            // 이니시스 PG 의 뱅크페이의 경우 페이지 전환 후 m_redirect_url 이 내려오므로 그걸 이용
            viewModel.processBankPayPayment(it, url)
        }
    }

    /**
     * 뱅크페이 결과 처리 viewModel 에 요청
     */
    func finalProcessBankPayPayment(_ url: URL) {
        debug_log("finalProcessBankPayPayment :: \(url)")
        let request = URLRequest(url: url)
        /// request.httpMethod = "POST" 해보니까 굳이 post 날릴 필요 없는 것 같음
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
        debug_log("openThirdPartyApp \(url)")
        let result = Utils.openAppWithCanOpen(url) // 앱 열기
        if !result {
            /// 한번 더 열어보고 취소시 앱스토어 이동
            Utils.justOpenApp(url) { [weak self] in
                if let scheme = url.scheme,
                   let urlString = AppScheme.getAppStoreUrl(scheme: scheme),
                   let url = URL(string: urlString)
                {
                    Utils.justOpenApp(url) // 앱스토어로 이동
                } else {
                    guard (self?.request) != nil else {
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
        debug_log("OpenWebView in WebViewMode")

        let bundle = Bundle.module

        var urlRequest: URLRequest? // for webView load
        var htmlContents: String? // for webView loadHtml(smilepay 자동 로그인)

        if case let .payment(payment) = request?.payload, payment.pgEnum == PG.smilepay {
            if let filepath = bundle.path(forResource: Constant.CDN_FILE_NAME, ofType: Constant.CDN_FILE_EXTENSION) {
                htmlContents = try? String(contentsOfFile: filepath, encoding: .utf8)
            }
        } else {
            guard let url = bundle.url(forResource: Constant.CDN_FILE_NAME, withExtension: Constant.CDN_FILE_EXTENSION) else {
                print("html file url 비정상")
                return
            }

            debug_dump(url)

            urlRequest = URLRequest(url: url)
        }

        DispatchQueue.main.async { [weak self] in
            guard let wv = self?.webview else {
                self?.failFinish(errMsg: "webView 를 찾을 수 없습니다.")
                return
            }

            if case let .payment(payment) = self?.request?.payload, payment.pgEnum == PG.smilepay {
                if let base = URL(string: Constant.SMILE_PAY_BASE_URL),
                   let contents = htmlContents
                {
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
        if let request = request {
            IamportResponse.makeFail(request: request, prepareData: nil, msg: errMsg).do { it in
                sdkFinish(it)
            }
        } else {
            sdkFinish(nil)
        }
    }
}

extension IamportWebViewMode: WKScriptMessageHandler {
    func userContentController(_: WKUserContentController, didReceive message: WKScriptMessage) {
        debug_log("body \(message.body)")

        if let jsMethod = WebViewController.JsInterface.convertJsInterface(s: message.name) {
            switch jsMethod {
            case .START_WORKING_SDK:
                print("JS SDK 통한 결제 시작 요청")

                guard let pay = request else {
                    print(".START_WORKING_SDK payment 를 찾을 수 없음")
                    return
                }
                debug_dump(pay)

                let encoder = JSONEncoder()

                initSDK(userCode: pay.userCode, tierCode: pay.tierCode)

                switch pay.payload {
                case let .payment(payload):
                    let jsonData = try? encoder.encode(payload)
                    requestPay(payloadJsonData: jsonData)

                case let .certification(payload):
                    let jsonData = try? encoder.encode(payload)
                    requestCertification(payloadJsonData: jsonData)
                }

            case .RECEIVED:
                print("Received from webview")

            case .CUSTOM_CALL_BACK:
                print("Received payment callback")
                if let data = (message.body as? String)?.data(using: .utf8),
                   let impStruct = try? JSONDecoder().decode(IamportResponseStruct.self, from: data)
                {
                    let response = IamportResponse.structToClass(impStruct)
                    sdkFinish(response)
                }

            case .DEBUG_CONSOLE_LOG:
                debug_log("DEBUG_CONSOLE_LOG :: \(message.body)")
            }
        }
    }

    private func evaluateJavaScript(method: String) {
        webview?.evaluateJavaScript(method)
    }

    private func initSDK(userCode: String, tierCode: String? = nil) {
        debug_log("userCode : '\(userCode)', tierCode : '\(tierCode ?? "-")'")

        var jsInitMethod = "init('\(userCode)');" // IMP.init
        if !tierCode.nilOrEmpty {
            jsInitMethod = "agency('\(userCode)', '\(String(describing: tierCode))');" // IMP.agency
        }

        evaluateJavaScript(method: jsInitMethod)
    }

    private func requestPay(payloadJsonData: Data?) {
        guard let json = payloadJsonData, let request = String(data: json, encoding: .utf8)?.replacingOccurrences(of: "'", with: "\\'") else {
            print("Failed to encode payload for `requestPay`")
            return
        }
        debug_log("payment request : '\(request)'")
        evaluateJavaScript(method: "requestPay('\(request)');")
    }

    private func requestCertification(payloadJsonData: Data?) {
        guard let json = payloadJsonData, let request = String(data: json, encoding: .utf8)?.replacingOccurrences(of: "'", with: "\\'") else {
            print("Failed to encode payload for `requestCertification`")
            return
        }
        debug_log("certification request : '\(request)'")
        evaluateJavaScript(method: "certification('\(request)');")
    }
}
