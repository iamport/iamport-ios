import UIKit
import WebKit

class WebViewController: UIViewController, WKUIDelegate {

    var webView: WKWebView?
    let received = "received"
    let startRequestPay = "startRequestPay"
    let customCallback = "customCallback"

    var payment: Payment?

    public func setPayment(_ pay: Payment) {
        payment = pay
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        print("어서오고")

        let bundle = Bundle(for: type(of: self))
        guard let url = bundle.url(forResource: "iamportcdn", withExtension: "html") else {
            print("html file url 비정상이요")
            return
        }

        let request = URLRequest(url: url)
        dump(url)
        dump(request)

        let contentController = WKUserContentController()
        let configuration = WKWebViewConfiguration.init()
        configuration.userContentController = contentController
        configuration.userContentController.add(self, name: received)
        configuration.userContentController.add(self, name: startRequestPay)
        configuration.userContentController.add(self, name: customCallback)

        webView = WKWebView.init(frame: view.frame, configuration: configuration)
        if let wv = webView {
            wv.uiDelegate = self
            wv.navigationDelegate = self
            wv.load(request)

            view.addSubview(wv)
            wv.frame = view.bounds
        }
    }

}

extension WebViewController: WKNavigationDelegate {

}

extension WebViewController: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        print(message.body)

        if (message.name == startRequestPay) {
            print("결제 시작하자!")

            let encoder = JSONEncoder()
//            encoder.outputFormatting = .prettyPrinted
            let jsonData = try? encoder.encode(payment?.iamPortRequest)
            if let json = jsonData, let code = payment?.userCode, let request = String(data: json, encoding: .utf8) {
                print("'\(code)', '\(request)'")
                webView?.evaluateJavaScript("requestPay('\(code)', '\(request)');")
            }

        }

        if (message.name == received) {
            print("받은거야?")
        }

        if (message.name == customCallback) {
            print("콜백 왔당~")
        }
    }
}