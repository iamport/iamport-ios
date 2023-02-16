import RxBusForPort
import RxRelay
import RxSwift
import UIKit
import WebKit

class WebViewController: UIViewController, WKUIDelegate, UINavigationBarDelegate {
    // for communicate WebView
    enum JsInterface: String, CaseIterable {
        case RECEIVED = "received"
        case START_WORKING_SDK = "startWorkingSdk"
        case CUSTOM_CALL_BACK = "customCallback"
        case DEBUG_CONSOLE_LOG = "debugConsoleLog"

        static func convertJsInterface(s: String) -> JsInterface? {
            for value in allCases {
                if s == value.rawValue {
                    return value
                }
            }
            return nil
        }
    }

    var disposeBag = DisposeBag()
    let viewModel = WebViewModel()

    var webView: WKWebView?
    var popupWebView: WKWebView? // window.open()으로 열리는 새창
    var request: IamportRequest?

    var useNavigationButton = false
    var navigationHeight: CGFloat = 0
    var safeArea: CGFloat = 0

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        debug_log("viewWillDisappear")
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        debug_log("viewDidDisappear")
        clearAll()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        debug_log("WebViewController 어서오고")

        view.backgroundColor = UIColor.white

        if useNavigationButton {
            setTopNaviBar()
        }

        DispatchQueue.main.async { [weak self] in
            self?.setupWebView()
            self?.subscribePayment()
        }
    }

    // 버튼 생성
    private func setTopNaviBar() {
        safeArea = statusBarHeight()
        navigationHeight = 45 // FIXME: 실제 ui 만큼 사이즈를 가져올 수 없음

        let navbar = UINavigationBar(frame: CGRect(x: 0, y: safeArea, width: UIScreen.main.bounds.width, height: navigationHeight))
        navbar.backgroundColor = UIColor.white
        navbar.delegate = self

        let navItem = UINavigationItem()
        navItem.leftBarButtonItem = UIBarButtonItem(title: "Back", style: .plain, target: self, action: #selector(buttonClose(sender:)))

        navbar.items = [navItem]
        debug_log("safeArea \(safeArea)")
        debug_log("navbar.frame.height \(navbar.frame.height)")

        view.addSubview(navbar)
    }

    @objc
    private func buttonClose(sender _: UIBarButtonItem) {
        navigationController?.popViewController(animated: false)
        dismiss(animated: true)
    }

    private func clearWebView() {
        if let wv = webView {
            wv.configuration.userContentController.do { controller in
                for value in JsInterface.allCases {
                    controller.removeScriptMessageHandler(forName: value.rawValue)
                }
            }

            wv.stopLoading()
            wv.removeFromSuperview()
            wv.uiDelegate = nil
            wv.navigationDelegate = nil
        }
        webView = nil
    }

    private func clearAll() {
        request = nil
        disposeBag = DisposeBag()
    }

    func statusBarHeight() -> CGFloat {
        let statusBarSize = UIApplication.shared.statusBarFrame.size
        return Swift.min(statusBarSize.width, statusBarSize.height)
    }

    private func setupWebView() {
        clearWebView()

        let config = WKWebViewConfiguration().then { configuration in
            configuration.userContentController = WKUserContentController().then { controller in
                for value in JsInterface.allCases {
                    controller.add(self, name: value.rawValue)
                }
            }
            configuration.preferences.javaScriptCanOpenWindowsAutomatically = true
        }
        webView = WKWebView(frame: view.frame, configuration: config).then { (wv: WKWebView) in
            wv.backgroundColor = UIColor.white

            // navi top bar 쓸 때
            if useNavigationButton {
                wv.frame = CGRect(x: 0, y: safeArea + navigationHeight, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height - navigationHeight - safeArea)
            } else {
                wv.frame = view.bounds
            }

            view.addSubview(wv)

            wv.uiDelegate = self
            wv.navigationDelegate = self
        }
    }

    private func subscribePayment() {
        let eventBus = EventBus.shared

        // 결제 데이터
        eventBus.webViewPaymentBus.subscribe { [weak self] event in
            guard let el = event.element, let request = el else {
                print("Error not found PaymentEvent")
                return
            }

            debug_log("PaymentEvent 있음!")
            self?.subscribe(request)
        }.disposed(by: disposeBag)
    }

    // isCertification 에 따라 bind 할 항목이 달라짐
    private func subscribe(_ request: IamportRequest) {
        if request.isCertification {
            subscribeCertification(request)
        } else {
            subscribePayment(request)
        }
    }

    // 결제 데이터가 있을때 처리 할 이벤트들
    private func subscribeCertification(_ request: IamportRequest) {
        self.request = request
        subscribeWebViewEvents()
        requestCertification(request)
    }

    // 결제 데이터가 있을때 처리 할 이벤트들
    private func subscribePayment(_ request: IamportRequest) {
        self.request = request
        subscribeWebViewEvents()
        subscribeForBankPay()
        requestPayment(request)
    }

    private func subscribeWebViewEvents() {
        let bus = RxBus.shared
        let events = EventBus.WebViewEvents.self

        bus.asObservable(event: events.ImpResponse.self).subscribe { [weak self] event in
            guard let el = event.element else {
                print("Error not found ImpResponse")
                return
            }

            debug_log("receive ImpResponse")
            self?.sdkFinish(el.impResponse)
        }.disposed(by: disposeBag)

        bus.asObservable(event: events.OpenWebView.self).subscribe { [weak self] event in
            guard event.element != nil else {
                print("Error not found OpenWebView")
                return
            }
            self?.openWebView()
        }.disposed(by: disposeBag)

        bus.asObservable(event: events.ThirdPartyUri.self).subscribe { [weak self] event in
            guard let el = event.element else {
                print("Error not found ThirdPartyUri")
                return
            }
            self?.openThirdPartyApp(el.thirdPartyUri)
        }.disposed(by: disposeBag)
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
    private func requestPayment(_ it: IamportRequest) {
        if !Utils.isInternetAvailable() {
            sdkFinish(IamportResponse.makeFail(request: it, msg: "네트워크 연결 안됨"))
            return
        }

        viewModel.requestPayment(request: it)
    }

    /**
     * 본인인증 요청 실행
     */
    private func requestCertification(_ it: IamportRequest) {
        if !Utils.isInternetAvailable() {
            sdkFinish(IamportResponse.makeFail(request: it, msg: "네트워크 연결 안됨"))
            return
        }

        viewModel.requestCertification(it)
    }

    /*
     모든 결과 처리 및 SDK 종료
     */
    func sdkFinish(_ iamportResponse: IamportResponse?) {
        print("명시적 sdkFinish")
        debug_dump(iamportResponse)
        clearAll()

        navigationController?.popViewController(animated: false)
        dismiss(animated: true) {
            EventBus.shared.impResponseRelay.accept(iamportResponse)
        }
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
     * 나이스 뱅크페이 결과 처리 viewModel 에 요청
     */
    func finalProcessBankPayPayment(_ url: URL) {
        debug_log("finalProcessBankPayPayment :: \(url)")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        DispatchQueue.main.async { [weak self] in
            self?.webView?.load(request)
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
            // 한번 더 열어보고 취소시 앱스토어 이동
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
        debug_log("Try to open WebView")

        let bundle = Bundle.module

        guard let filepath = bundle.path(forResource: Constant.CDN_FILE_NAME, ofType: Constant.CDN_FILE_EXTENSION), let contents = try? String(contentsOfFile: filepath, encoding: .utf8) else {
            return
        }

        DispatchQueue.main.async { [weak self] in
            guard let wv = self?.webView else {
                self?.failFinish(errMsg: "webView 를 찾을 수 없습니다.")
                return
            }

            // SMILEPAY 자동로그인
            if case let .payment(payment) = self?.request?.payload, payment.pgEnum == PG.smilepay, let base = URL(string: Constant.SMILE_PAY_BASE_URL) {
                wv.loadHTMLString(contents, baseURL: base)
            } else {
                wv.loadHTMLString(contents, baseURL: nil)
            }
        }
    }
}

extension WebViewController: WKNavigationDelegate {
    func webView(_: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for _: WKNavigationAction, windowFeatures _: WKWindowFeatures) -> WKWebView? {
        let frame = UIScreen.main.bounds
        popupWebView = WKWebView(frame: frame, configuration: configuration)
        if let popup = popupWebView {
            popup.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            popup.navigationDelegate = self
            popup.uiDelegate = self
            view.addSubview(popup)
            return popup
        }

        return nil
    }

    func webViewDidClose(_ webView: WKWebView) {
        if webView == popupWebView {
            popupWebView?.removeFromSuperview()
            popupWebView = nil
        }
    }

    @available(iOS 8.0, *)
    func webView(_: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
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

    func webView(_: WKWebView, didFail _: WKNavigation!, withError error: Error) {
        print("didFail \(error.localizedDescription)")
    }

    func webView(_: WKWebView, didFailProvisionalNavigation _: WKNavigation!, withError error: Error) {
        print("didFailProvisionalNavigation \(error.localizedDescription)")
    }

    func webView(_: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame _: WKFrameInfo, completionHandler: @escaping () -> Void) {
        let alertController = UIAlertController(title: message, message: nil, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "확인", style: .default) { _ in
            completionHandler()
        }
        alertController.addAction(okAction)
        DispatchQueue.main.async {
            self.present(alertController, animated: true, completion: nil)
        }
    }

    // for Alert(for 주로 모빌리언스 + 휴대폰 소액결제 Pair)
    func webView(_: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame _: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
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
            self.present(alertController, animated: true, completion: nil)
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

extension WebViewController: WKScriptMessageHandler {
    func userContentController(_: WKUserContentController, didReceive message: WKScriptMessage) {
        debug_log("body \(message.body)")

        if let jsMethod = JsInterface.convertJsInterface(s: message.name) {
            switch jsMethod {
            case .START_WORKING_SDK:
                print("JS SDK 통한 결제 시작 요청")

                guard let request = request else {
                    print(".START_WORKING_SDK payment 를 찾을 수 없음")
                    return
                }
                debug_dump(request)

                initSDK(userCode: request.userCode, tierCode: request.tierCode)

                switch request.payload {
                case let .payment(payment):
                    requestPay(payment: payment)
                case let .certification(certification):
                    requestCertification(certification: certification)
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
        webView?.evaluateJavaScript(method)
    }

    private func initSDK(userCode: String, tierCode: String? = nil) {
        debug_log("userCode : '\(userCode)', tierCode : '\(tierCode ?? "-")'")

        var jsInitMethod = "init('\(userCode)');" // IMP.init
        if !tierCode.nilOrEmpty {
            jsInitMethod = "agency('\(userCode)', '\(String(describing: tierCode))');" // IMP.agency
        }

        evaluateJavaScript(method: jsInitMethod)
    }

    private func requestPay(payment: IamportPayment) {
        guard let impRequestJsonData = try? JSONEncoder().encode(payment) else {
            print("requestPay :: payment 데이터를 JSONEncoder encode 할 수 없습니다.")
            return
        }

        if let customData = payment.custom_data {
            requestPayWithCustomData(payloadJsonData: impRequestJsonData, customData: customData)
        } else {
            requestPayNormal(payloadJsonData: impRequestJsonData)
        }
    }

    private func requestPayNormal(payloadJsonData: Data) {
        guard let request = String(data: payloadJsonData, encoding: .utf8) else {
            print("requestPayNormal :: impRequestJsonData 을 String 화 할 수 없습니다.")
            return
        }

        debug_log("requestPay request : '\(request)'")
        evaluateJavaScript(method: "requestPay('\(request)');")
    }

    private func requestPayWithCustomData(payloadJsonData: Data, customData: String) {
        guard let request = String(data: payloadJsonData, encoding: .utf8) else {
            print("requestPayWithCustomData :: impRequestJsonData 을 String 화 할 수 없습니다.")
            return
        }

        guard let encodedCustomData = customData.getBase64Encode() else {
            print("requestPayWithCustomData :: getBase64Encode 를 가져올 수 없어 requestPayNormal 실행")
            requestPayNormal(payloadJsonData: payloadJsonData)
            return
        }

        debug_log("requestPayWithCustomData request : '\(request)', encodedCustomData : '\(encodedCustomData)'")
        evaluateJavaScript(method: "requestPayWithCustomData('\(request)', '\(encodedCustomData)');")
    }

    private func requestCertification(certification: IamportCertification) {
        guard let impCertificationJsonData = try? JSONEncoder().encode(certification) else {
            print("requestPay :: certification 데이터를 JSONEncoder encode 할 수 없습니다.")
            return
        }

        requestCertification(payloadJsonData: impCertificationJsonData)
    }

    private func requestCertification(payloadJsonData: Data?) {
        if let json = payloadJsonData,
           let request = String(data: json, encoding: .utf8)
        {
            debug_log("certification request : '\(request)'")
            evaluateJavaScript(method: "certification('\(request)');")
        }
    }
}

/**
  쿠키 처리 필요시..
              let policy = Utils.getActionPolicy(url)
             if (!policy) {
 //                let cookies = HTTPCookieStorage.shared.cookies ?? []
 //                for cookie in cookies {
 //                    if #available(iOS 11.0, *) {
 //                        dump(cookie)
 //                        if (cookie.domain.contains(".mysmilepay.com")) {
 //                            webView.configuration.websiteDataStore.httpCookieStore.setCookie(cookie)
 //                        }
 //                    } else {
 //                        // Fallback on earlier versions
 //                    }
 //                }

 //                if #available(iOS 11.0, *) {
 //                    webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { (cookies) in
 //                        for cookie in cookies {
 //                            print("@@@ cookie ==> \(cookie.name) : \(cookie.value)")
 //                            if cookie.name.contains("sp_") {
 ////                                UserDefaults.standard.set(cookie.value, forKey: "PHPSESSID")
 //                                webView.configuration.websiteDataStore.httpCookieStore.setCookie(cookie)
 //                                print("@@@ PHPSESSID 저장하기: \(cookie.value)")
 //                            }
 //                        }
 //                    }
 //                } else {
 //                    // Fallback on earlier versions
 //                }

             }
  */
