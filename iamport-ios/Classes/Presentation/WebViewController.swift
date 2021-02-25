import UIKit
import WebKit
import RxBus
import RxSwift
import RxRelay

class WebViewController: UIViewController, WKUIDelegate {

    // for communicate WebView
    enum JsInterface: String, CaseIterable {
        case RECEIVED = "received"
        case START_REQUEST_PAY = "startRequestPay"
        case CUSTOM_CALL_BACK = "customCallback"

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
    var payment: Payment?

    // Disappear
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        dlog("viewWillDisappear")
        clearAll()
    }

    // loaded
    override func viewDidLoad() {
        super.viewDidLoad()
        dlog("WebViewController 어서오고")

        view.backgroundColor = UIColor.white
        setupWebView()
        subscribePayment()
    }

    private func clearWebView() {
        if let wv = webView {
            wv.stopLoading()
            wv.removeFromSuperview()
            wv.uiDelegate = nil
            wv.navigationDelegate = nil
        }
        webView = nil
    }

    private func clearAll() {
        clearWebView()
        view.removeFromSuperview()
        payment = nil
        disposeBag = DisposeBag()
    }

    private func setupWebView() {

        clearWebView()

        let userController = WKUserContentController().then { controller in
            controller.add(self, name: JsInterface.RECEIVED.rawValue)
            controller.add(self, name: JsInterface.START_REQUEST_PAY.rawValue)
            controller.add(self, name: JsInterface.CUSTOM_CALL_BACK.rawValue)
        }

        let config = WKWebViewConfiguration.init().then { configuration in
            configuration.userContentController = userController
        }

        webView = WKWebView.init(frame: view.frame, configuration: config).then { (wv: WKWebView) in
            wv.backgroundColor = UIColor.white
            wv.frame = view.bounds

            view.addSubview(wv)

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

    // 결제 데이터가 있을때 처리 할 이벤트들
    private func subscribe(_ payment: Payment) {
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


    /*
     모든 결과 처리 및 SDK 종료
     */
    func sdkFinish(_ iamPortResponse: IamPortResponse?) {
        print("명시적 sdkFinish")
        ddump(iamPortResponse)

//        clear() // viewWillDisappear 에서 처리
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
        let result = Utils.openApp(url) // 앱 열기
        if (!result) {

            if let scheme = url.scheme,
               let urlString = AppScheme.getAppStoreUrl(scheme: scheme),
               let url = URL(string: urlString) {

                Utils.openApp(url) // 앱스토어로 이동
            } else {

                guard let pay = payment else {
                    sdkFinish(nil)
                    return
                }

                let response = IamPortResponse.makeFail(payment: pay, msg: "지원하지 않는 App Scheme\(url.scheme) 입니다")
                sdkFinish(response)
            }
        }
    }

    /**
     * 결제 요청 실행
     */
    private func openWebView() {
        print("오픈! 웹뷰")

        let fileName = "iamportcdn"
        let fileExtension = "html"

        let myPG = payment?.iamPortRequest.pgEnum
        let bundle = Bundle(for: type(of: self))

        var urlRequest: URLRequest? = nil // for webView load
        var htmlContents: String? = nil // for webView loadHtml(smilepay 자동 로그인)

        if (myPG == PG.smilepay) {
            if let filepath = bundle.path(forResource: fileName, ofType: fileExtension) {
                htmlContents = try? String(contentsOfFile: filepath, encoding: .utf8)
            }
        } else {
            guard let url = bundle.url(forResource: fileName, withExtension: fileExtension) else {
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
            case .START_REQUEST_PAY:
                print("JS SDK 통한 결제 시작 요청")
                let encoder = JSONEncoder()
                // encoder.outputFormatting = .prettyPrinted
                let jsonData = try? encoder.encode(payment?.iamPortRequest)
//            dump(payment)
                if let json = jsonData, let code = payment?.userCode, let request = String(data: json, encoding: .utf8) {
                    dlog("'\(code)', '\(request)'")
                    webView?.evaluateJavaScript("requestPay('\(code)', '\(request)');")
                }

            case .RECEIVED:
                print("Received from webview")

            case .CUSTOM_CALL_BACK:
                print("Received payment callback")
                if let data = (message.body as? String)?.data(using: .utf8), let impStruct = try? JSONDecoder().decode(IamPortResponseStruct.self, from: data) {
                    let response = IamPortResponse.structToClass(impStruct)
                    sdkFinish(response)
                }
            }
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