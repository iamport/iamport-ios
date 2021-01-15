//
// Created by BingBong on 2021/01/08.
//

import Foundation
import WebKit
import RxBus
import RxSwift

class WebViewStrategy: BaseWebViewStrategy {

    override func doWork(_ payment: Payment) {
        super.doWork(payment)
        print("헬로 WebViewStrategy")
        // 오픈 웹뷰!
        RxBus.shared.post(event: EventBus.WebViewEvents.OpenWebView(openWebView: payment))
    }

    override func onChangeUrl(url: URL) {
        super.onChangeUrl(url: url)

        print("onChangeUrl \(url)")
        if let appScheme = payment?.iamPortRequest.app_scheme {
            if (url.absoluteString.hasPrefix(appScheme)) {
                processInisisTrans(url)
                return
            }
        }

        if (Utils.isAppUrl(url)) {
            print("isAppUrl")
            RxBus.shared.post(event: EventBus.WebViewEvents.ThirdPartyUri(thirdPartyUri: url))
            return
        }

        if (Utils.isPaymentOver(url)) {
            let response = Utils.getQueryStringToImpResponse(url)
            print("paymentOver :: \(response)")
            dump(response)
            sdkFinish(response)
            return
        }
    }

    private func processInisisTrans(_ url: URL) {
        func isParseUrl(_ str: String) -> Bool {
            if URL(string: str) != nil {
                return true
            } else {
                return false
            }
        }

        let urlString: String = url.absoluteString
        let removeAppScheme = urlString.replacingOccurrences(of: "\(CONST.APP_SCHME)://?", with: "")
        let separated = removeAppScheme.components(separatedBy: "=")
        let redirectUrl = separated.map { s -> String in
            s.removingPercentEncoding ?? s
        }.filter { s in
            s.contains(CONST.IAMPORT_DUMMY_URL)
        }.first
        if let urlStr = redirectUrl, let url = URL(string: urlStr) {
            print("parse url \(url.absoluteString)")
            RxBus.shared.post(event: EventBus.WebViewEvents.FinalBankPayProcess(url: url))
        }
    }
}
