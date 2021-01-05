//
// Created by BingBong on 2021/01/05.
//

import Foundation
import WebKit

public class IamportSdk {

    let webView = WKWebView()

    init() {
        guard let url = URL(string: "https://www.iamport.kr/demo") else {
            return
        }

        let request = URLRequest(url: url)
        webView.load(request)
    }

    func getWebView() -> WKWebView {
        webView
    }
}