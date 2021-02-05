import UIKit
import WebKit
import RxBus
import RxSwift

class WebViewController: UIViewController, WKUIDelegate {

    // for communicate WebView
    enum JsInterface: String {
        case RECEIVED = "received"
        case START_REQUEST_PAY = "startRequestPay"
        case CUSTOM_CALL_BACK = "customCallback"
    }

    var disposeBag = DisposeBag()
    let viewModel = WebViewModel()

    var webView: WKWebView?
    var payment: Payment?

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        #if DEBUG
        print("viewWillDisappear")
        #endif

        if let wv = webView {
            wv.stopLoading()
            wv.removeFromSuperview()
            wv.uiDelegate = nil
            wv.navigationDelegate = nil
        }
        webView = nil
        view.removeFromSuperview()

//        clear()
        disposeBag = DisposeBag()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        #if DEBUG
        print("WebViewController 어서오고")
        #endif

        view.backgroundColor = UIColor.white
        setupWebView()
        observePaymentData()
    }

    func clear() {
        viewModel.clear()
    }

    private func observePaymentData() {
        let eventBus = EventBus.shared

        eventBus.closeBus.subscribe { [weak self] in
            print("closeBus")
            self?.sdkFinish(nil)
        }.disposed(by: disposeBag)

        eventBus.paymentBus.subscribe { [weak self] event in
            guard let el = event.element, let pay = el else {
                print("Error paymentBus is nil")
                return
            }
            self?.observe(pay)
        }.disposed(by: disposeBag)
    }

    private func observe(_ payment: Payment) {
        print("observe")

        self.payment = payment
        let bus = RxBus.shared
        let events = EventBus.WebViewEvents.self

        bus.asObservable(event: events.ImpResponse.self).subscribe { [weak self] event in
            guard let el = event.element else {
                print("Error not found ImpResponse")
                return
            }

            print("receive ImpResponse")
            self?.sdkFinish(el.impResponse)
        }.disposed(by: disposeBag)

        bus.asObservable(event: events.OpenWebView.self).subscribe { [weak self] event in
            guard nil != event.element else {
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

        observeForBankPay()
        requestPayment(payment)
    }

    private func observeForBankPay() {

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
        #if DEBUG
        dump(iamPortResponse)
        #endif

//        clear()
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
        #if DEBUG
        print("finalProcessBankPayPayment :: \(url)")
        #endif
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
        #if DEBUG
        print("openThirdPartyApp \(url)")
        #endif
        let result = Utils.openApp(url) // 앱 열기
        if (!result) {
            if let scheme = url.scheme, let url = URL(string: Utils.getMarketUrl(scheme: scheme)) {
                Utils.openApp(url) // 앱스토어로 이동
            }
        }
    }

    private func setupWebView() {

        let config = WKWebViewConfiguration.init()
        let userController = WKUserContentController()
        userController.add(self, name: JsInterface.RECEIVED.rawValue)
        userController.add(self, name: JsInterface.START_REQUEST_PAY.rawValue)
        userController.add(self, name: JsInterface.CUSTOM_CALL_BACK.rawValue)
        config.userContentController = userController
        webView = WKWebView.init(frame: view.frame, configuration: config)

        if let wv = webView {
            wv.backgroundColor = UIColor.white
            wv.frame = view.bounds

            view.removeFromSuperview()
            view.addSubview(wv)

            wv.uiDelegate = self
            wv.navigationDelegate = self
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

            #if DEBUG
            dump(url)
            #endif

            urlRequest = URLRequest(url: url)
        }

        DispatchQueue.main.async { [weak self] in
            if let wv = self?.webView {
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
        #if DEBUG
        print("body \(message.body)")
        #endif

        // TODO enum 으로 분기 및 코드정리
        if (message.name == JsInterface.START_REQUEST_PAY.rawValue) {
            print("JS SDK 통한 결제 시작 요청")
            let encoder = JSONEncoder()
            // encoder.outputFormatting = .prettyPrinted
            let jsonData = try? encoder.encode(payment?.iamPortRequest)
//            dump(payment)
            if let json = jsonData, let code = payment?.userCode, let request = String(data: json, encoding: .utf8) {
                #if DEBUG
                print("'\(code)', '\(request)'")
                #endif
                webView?.evaluateJavaScript("requestPay('\(code)', '\(request)');")
            }
        }

        if (message.name == JsInterface.RECEIVED.rawValue) {
            print("Received from webview")
        }

        if (message.name == JsInterface.CUSTOM_CALL_BACK.rawValue) {
            print("Received payment callback")
            let decoder = JSONDecoder()
            if let data = (message.body as? String)?.data(using: .utf8), let impStruct = try? decoder.decode(IamPortResponseStruct.self, from: data) {
                let response = IamPortResponse.structToClass(impStruct)
                sdkFinish(response)
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