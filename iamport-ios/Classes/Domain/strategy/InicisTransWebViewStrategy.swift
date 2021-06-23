//
// Created by BingBong on 2021/01/15.
//

import Foundation
import WebKit
import RxBus
import RxSwift

class InicisTransWebViewStrategy: WebViewStrategy {

    override func onUpdatedUrl(url: URL) {

        if let appScheme = payment?.iamPortRequest?.app_scheme {
            if (url.absoluteString.hasPrefix(appScheme)) {
                processInicisTrans(appScheme, url)
                return
            }
        }

        super.onUpdatedUrl(url: url)
    }

    private func processInicisTrans(_ appScheme: String, _ url: URL) {
        func isParseUrl(_ str: String) -> Bool {
            if URL(string: str) != nil {
                return true
            }

            return false
        }

        var scheme = "\(appScheme)?"
        if (!appScheme.contains(CONST.COLON_SLASH_SLASH)) {
            scheme = "\(appScheme)\(CONST.COLON_SLASH_SLASH)?"
        }

        let removeAppScheme = url.absoluteString.replacingOccurrences(of: scheme, with: "")
        let separated = removeAppScheme.components(separatedBy: "=")
        let redirectUrl = separated.map { s -> String in
            s.removingPercentEncoding ?? s
        }.filter { s in
            s.contains(CONST.IAMPORT_DETECT_URL)
        }.first

        if let urlStr = redirectUrl, let url = URL(string: urlStr) {
            dlog("parse url \(url.absoluteString)")
            RxBus.shared.post(event: EventBus.WebViewEvents.FinalBankPayProcess(url: url))
        }
    }
}
