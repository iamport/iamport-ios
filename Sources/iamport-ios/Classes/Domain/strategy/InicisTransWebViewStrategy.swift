//
// Created by BingBong on 2021/01/15.
//

import Foundation
import RxSwift
import WebKit

class InicisTransWebViewStrategy: WebViewStrategy {
    override func onUpdatedUrl(url: URL) {
        if case let .payment(payment) = request?.payload, let appScheme = payment.app_scheme {
            if url.absoluteString.hasPrefix(appScheme) {
                processInicisTrans(appScheme, url)
                return
            }
        }

        super.onUpdatedUrl(url: url)
    }

    private func processInicisTrans(_ appScheme: String, _ url: URL) {
        debug_log("processInicisTrans")
        func isParseUrl(_ str: String) -> Bool {
            if URL(string: str) != nil {
                return true
            }

            return false
        }

        var scheme = "\(appScheme)?"
        if !appScheme.contains(Constant.COLON_SLASH_SLASH) {
            scheme = "\(appScheme)\(Constant.COLON_SLASH_SLASH)?"
        }

        guard case let .payment(payment) = request?.payload else { return }

        let removeAppScheme = url.absoluteString.replacingOccurrences(of: scheme, with: "")
        let separated = removeAppScheme.components(separatedBy: "=")
        let redirectUrl = separated.map { s -> String in
            s.removingPercentEncoding ?? s
        }.filter { s in
            s.contains(payment.getRedirectUrl() ?? Constant.IAMPORT_DETECT_URL)
        }.first

        if let urlStr = redirectUrl, let url = URL(string: urlStr) {
            debug_log("parse url \(url.absoluteString)")
            RxBus.shared.post(event: EventBus.WebViewEvents.FinalBankPayProcess(url: url))
        }
    }
}
