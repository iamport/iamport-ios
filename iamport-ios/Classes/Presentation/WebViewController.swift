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

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        print("viewDidDisappear")
        clear()
        disposeBag = DisposeBag()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        print("WebViewController 어서오고")
        view.backgroundColor = UIColor.white
        observePaymentData()
    }

    func clear() {
        viewModel.clear()
    }

    private func observePaymentData() {
        let eventBus = EventBus.shared

        eventBus.closeBus.subscribe { [weak self] in
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

        // Start abount Nice PG, Trans PayMethod Pair BankPay

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
        dump(iamPortResponse)

//        clear()
        navigationController?.popViewController(animated: false)
        dismiss(animated: true) {
            EventBus.shared.impResponseSubject.onNext(iamPortResponse)
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
        print("finalProcessBankPayPayment :: \(url)")
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
        print("openThirdPartyApp \(url)")
        let application = UIApplication.shared
        if (application.canOpenURL(url)) {
            if #available(iOS 10.0, *) {
                application.open(url, options: [:], completionHandler: nil)
            } else {
                application.openURL(url)
            }
        } else {
            openURLToAppStore(url)
        }
    }

    //MARK : 앱스토어로 이동
    private func openURLToAppStore(_ url: URL) {
        if let openUrl = URL(string: Utils.getMarketUrl(url: url.absoluteString, scheme: url.scheme ?? "")) {
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(openUrl, options: [:], completionHandler: nil)
            } else {
                UIApplication.shared.openURL(openUrl)
            }
        }
    }

    /**
     * 결제 요청 실행
     */
    private func openWebView() {
        print("오픈! 웹뷰")

        let bundle = Bundle(for: type(of: self))
        guard let url = bundle.url(forResource: "iamportcdn", withExtension: "html") else {
            print("html file url 비정상이요")
            return
        }

        let request = URLRequest(url: url)
        dump(url)

        let config = WKWebViewConfiguration.init()
        let userController = WKUserContentController()
        userController.add(self, name: JsInterface.RECEIVED.rawValue)
        userController.add(self, name: JsInterface.START_REQUEST_PAY.rawValue)
        userController.add(self, name: JsInterface.CUSTOM_CALL_BACK.rawValue)
        config.userContentController = userController

        DispatchQueue.main.async { [weak self] in
            if let view = self?.view {
                self?.webView = WKWebView.init(frame: view.frame, configuration: config)
                if let wv = self?.webView {
                    wv.uiDelegate = self
                    wv.navigationDelegate = self

                    wv.load(request)
                    view.addSubview(wv)
                    wv.frame = view.bounds
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

    // for Alert(for 주로 모빌리언스 + 휴대폰 소액결제 Pair)
    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        let alertController = UIAlertController(title: message, message: nil, preferredStyle: .alert); let cancelAction = UIAlertAction(title: "취소", style: .cancel) { _ in
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
        print(message.body)

        // TODO enum 으로 분기 및 코드정리
        if (message.name == JsInterface.START_REQUEST_PAY.rawValue) {
            print("JS SDK 통한 결제 시작 요청")
            let encoder = JSONEncoder()
            // encoder.outputFormatting = .prettyPrinted
            let jsonData = try? encoder.encode(payment?.iamPortRequest)
//            dump(payment)
            if let json = jsonData, let code = payment?.userCode, let request = String(data: json, encoding: .utf8) {
                print("'\(code)', '\(request)'")
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