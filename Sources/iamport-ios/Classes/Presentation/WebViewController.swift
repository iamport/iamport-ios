import UIKit
import WebKit
import RxBus
import RxSwift
import RxRelay

class WebViewController: UIViewController, WKUIDelegate, UINavigationBarDelegate {

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

    var webView: WKWebView?
    var popupWebView: WKWebView?//window.open()으로 열리는 새창
    var payment: Payment?

    var useNaviButton = false
    var naviHeight: CGFloat = 0
    var safeArea: CGFloat = 0

    // Disappear
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        dlog("viewWillDisappear")
//        clearAll()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        dlog("viewDidDisappear")
        clearAll()
    }


    // loaded
    override func viewDidLoad() {
        super.viewDidLoad()
        dlog("WebViewController 어서오고")

        view.backgroundColor = UIColor.white

        if (useNaviButton) {
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
        naviHeight = 45 // FIXME: 실제 ui 만큼 사이즈를 가져올 수 없음

        let navbar = UINavigationBar(frame: CGRect(x: 0, y: safeArea, width: UIScreen.main.bounds.width, height: naviHeight))
        navbar.backgroundColor = UIColor.white
        navbar.delegate = self

        let navItem = UINavigationItem()
        navItem.leftBarButtonItem = UIBarButtonItem(title: "Back", style: .plain, target: self, action: #selector(buttonClose(sender:)))

        navbar.items = [navItem]
        dlog("safeArea \(safeArea)")
        dlog("navbar.frame.height \(navbar.frame.height)")

        view.addSubview(navbar)
    }

    @objc
    private func buttonClose(sender: UIBarButtonItem) {
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
//        clearWebView()
//        view.removeFromSuperview()
        payment = nil
        disposeBag = DisposeBag()
    }

    func statusBarHeight() -> CGFloat {
        let statusBarSize = UIApplication.shared.statusBarFrame.size
        return Swift.min(statusBarSize.width, statusBarSize.height)
    }

    private func setupWebView() {

        clearWebView()

        let config = WKWebViewConfiguration.init().then { configuration in
            configuration.userContentController = WKUserContentController().then { controller in
                for value in JsInterface.allCases {
                    controller.add(self, name: value.rawValue)
                }
            }
        }

        webView = WKWebView.init(frame: view.frame, configuration: config).then { (wv: WKWebView) in
            wv.backgroundColor = UIColor.white

            // navi top bar 쓸 때
            if (useNaviButton) {
                wv.frame = CGRect(x: 0, y: safeArea + naviHeight, width: UIScreen.main.bounds.width, height: (UIScreen.main.bounds.height - naviHeight - safeArea))
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
            guard let el = event.element, let pay = el else {
                print("Error not found PaymentEvent")
                return
            }

            dlog("PaymentEvent 있음!")
            self?.subscribe(pay)
        }.disposed(by: disposeBag)

        // 외부 종료 시그널
//        eventBus.clearBus.subscribe { [weak self] in
//            print("clearBus")
////            self?.sdkFinish(nil)
//            self?.clearAll()
//        }.disposed(by: disposeBag)
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

            dlog("receive ImpResponse")
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
        dlog("subscribePayment vc")

        self.payment = payment
        let bus = RxBus.shared
        let webViewEvents = EventBus.WebViewEvents.self

        bus.asObservable(event: webViewEvents.ImpResponse.self).subscribe { [weak self] event in
            guard let el = event.element else {
                print("Error not found ImpResponse")
                return
            }

            dlog("receive ImpResponse")
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
        clearAll()

        navigationController?.popViewController(animated: false)
        dismiss(animated: true) {
            EventBus.shared.impResponseRelay.accept(iamPortResponse)
        }
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
        print("오픈! 웹뷰 vc")

        let myPG = payment?.iamPortRequest?.pgEnum

//        let bundle = Bundle(for: type(of: self))
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
            guard let wv = self?.webView else {
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

extension WebViewController: WKNavigationDelegate {

    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
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
            self.present(alertController, animated: true, completion: nil)
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
            self.present(alertController, animated: true, completion: nil)
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

extension WebViewController: WKScriptMessageHandler {
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
                dlog("DEBUG_CONSOLE_LOG :: \(message.body)")
            }
        }
    }

    private func evaluateJS(method: String) {
        webView?.evaluateJavaScript(method)
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
