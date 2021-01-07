import UIKit
import WebKit

class WebViewController: UIViewController, WKUIDelegate {

    var webView: WKWebView?
    let startRequestPay = "startRequestPay"
    let customCallback = "customCallback"


    override func viewDidLoad() {
        super.viewDidLoad()

        print("어서오고")

        guard let url = URL(string: "https://www.iamport.kr/demo") else {
            return
        }

        let request = URLRequest(url: url)

        let contentController = WKUserContentController()
        let configuration = WKWebViewConfiguration.init()
        configuration.userContentController = contentController
        configuration.userContentController.add(self, name: "startRequestPay")
        configuration.userContentController.add(self, name: "customCallback")

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
        print(message)

        if (message.name == startRequestPay) {
//            webView.evaluateJavaScript("requestPay(" + self.userCode + ", " + self.impRequest + ");")
            print("결제 시작하자!")
        }

        if (message.name == customCallback) {
            print("콜백 왔당~")
        }
    }
}