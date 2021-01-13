import UIKit
import WebKit
import RxBus
import RxSwift

class WebViewController: UIViewController, WKUIDelegate {

    var disposeBag = DisposeBag()
    let viewModel = WebViewModel()

    var webView: WKWebView?
    let received = "received"
    let startRequestPay = "startRequestPay"
    let customCallback = "customCallback"

    var payment: Payment?

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        disposeBag = DisposeBag()
        // TODO 초기화
        viewModel.clear()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        print("WebViewController 어서오고")

        EventBus.shared.paymentBus.subscribe { [weak self] pay in
            self?.observeViewModel(pay)
        }.disposed(by: disposeBag)
    }

    func observeViewModel(_ payment: Payment?) {
        if let pay = payment {
            print("observeViewModel")
            self.payment = payment

            let bus = RxBus.shared
            bus.asObservable(event: EventBus.WebViewEvents.PaymentEvent.self)
                    .subscribe { [weak self] event in
                        self?.requestPayment(event.element!.webViewPayment)
                    }.disposed(by: disposeBag)

            bus.asObservable(event: EventBus.WebViewEvents.OpenWebView.self)
                    .subscribe { [weak self] event in
                        self?.openWebView(event.element!.openWebView)
                    }.disposed(by: disposeBag)

            bus.asObservable(event: EventBus.WebViewEvents.ImpResponse.self)
                    .subscribe { [weak self] event in
                        self?.sdkFinish(event.element!.impResponse)
                    }.disposed(by: disposeBag)

            bus.asObservable(event: EventBus.WebViewEvents.ThirdPartyUri.self)
                    .subscribe { [weak self] event in
                        self?.openThirdPartyApp(event.element!.thirdPartyUri)
                    }.disposed(by: disposeBag)

            bus.asObservable(event: EventBus.WebViewEvents.ReceivedURL.self)
                    .subscribe { [weak self] event in
                        self?.processBankPayPayment(event.element!.url)
                    }.disposed(by: disposeBag)

            bus.asObservable(event: EventBus.WebViewEvents.FinalBackPayProcess.self)
                    .subscribe { [weak self] event in
                        self?.finalProcessBankPayPayment(event.element!.url)
                    }.disposed(by: disposeBag)

            bus.asObservable(event: EventBus.WebViewEvents.NiceTransRequestParam.self)
                    .subscribe { [weak self] event in
                        self?.openNiceTransApp(it: event.element!.niceTransRequestParam)
                    }.disposed(by: disposeBag)

            viewModel.startPayment(pay)
        }
    }


    /**
     * 결제 요청 실행
     */
    private func requestPayment(_ it: Payment) {
        // TODO 네트워크 체크
//        if (!Util.isInternetAvailable(this)) {
//            sdkFinish(IamPortResponse.makeFail(it, msg = "네트워크 연결 안됨"))
//            return
//        }

        viewModel.requestPayment(payment: it)
    }


    /*
     모든 결과 처리 및 SDK 종료
     */
    func sdkFinish(_ iamPortResponse: IamPortResponse?) {
        print("명시적 sdkFinish")
        dump(iamPortResponse)

        navigationController?.popViewController(animated: false)
        dismiss(animated: true) {
            EventBus.shared.impResponseSubject.onNext(iamPortResponse)
        }
    }

    /**
     * 뱅크페이 결과 처리 viewModel 에 요청
     */
    func processBankPayPayment(_ url: URL) {
        viewModel.processBankPayPayment(url)
    }

    /**
     * 뱅크페이 결과 처리 viewModel 에 요청
     */
    func finalProcessBankPayPayment(_ url: URL) {
        print("finalProcessBankPayPayment :: \(url)")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        DispatchQueue.main.async { [self] in
            if let wv = webView {
                wv.uiDelegate = self
                wv.navigationDelegate = self

                wv.load(request)
                view.addSubview(wv)
                wv.frame = view.bounds
            }
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
    private func openWebView(_ payment: Payment) {
        print("오픈! 웹뷰")

        let bundle = Bundle(for: type(of: self))
        guard let url = bundle.url(forResource: "iamportcdn", withExtension: "html") else {
            print("html file url 비정상이요")
            return
        }

        let request = URLRequest(url: url)
        dump(url)
//        dump(request)

        let config = WKWebViewConfiguration.init()
        let userController = WKUserContentController()
        userController.add(self, name: received)
        userController.add(self, name: startRequestPay)
        userController.add(self, name: customCallback)
        config.userContentController = userController


        DispatchQueue.main.async { [self] in
            webView = WKWebView.init(frame: view.frame, configuration: config)
            if let wv = webView {
                wv.uiDelegate = self
                wv.navigationDelegate = self

                wv.load(request)
                view.addSubview(wv)
                wv.frame = view.bounds
            }
        }
    }
}

extension WebViewController: WKNavigationDelegate {

    @available(iOS 8.0, *)
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        // url 변경 시점
        if let url = navigationAction.request.url {
            RxBus.shared.post(event: EventBus.WebViewEvents.ChangeUrl(url: url))

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

        if (message.name == startRequestPay) {
            print("JS SDK 통한 결제 시작 요청")

            let encoder = JSONEncoder() //            encoder.outputFormatting = .prettyPrinted
            let jsonData = try? encoder.encode(payment?.iamPortRequest)
            dump(payment)
            if let json = jsonData, let code = payment?.userCode, let request = String(data: json, encoding: .utf8) {
                print("'\(code)', '\(request)'")
                webView?.evaluateJavaScript("requestPay('\(code)', '\(request)');")
            }
        }

        if (message.name == received) {
            print("Received from webview")
        }

        if (message.name == customCallback) {
            print("Received payment callback")
            let decoder = JSONDecoder()
            if let data = (message.body as? String)?.data(using: .utf8), let impStruct = try? decoder.decode(IamPortResponseStruct.self, from: data) {
                let response = IamPortResponse.structToClass(impStruct)
                sdkFinish(response)
            }
        }
    }
}