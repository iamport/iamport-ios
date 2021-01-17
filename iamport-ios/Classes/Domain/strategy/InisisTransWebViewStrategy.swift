//
// Created by BingBong on 2021/01/15.
//

import Foundation
import WebKit
import RxBus
import RxSwift

class InisisTransWebViewStrategy: WebViewStrategy {

    override func onUpdatedUrl(url: URL) {

        if let appScheme = payment?.iamPortRequest.app_scheme {
            if (url.absoluteString.hasPrefix(appScheme)) {
                processInisisTrans(appScheme, url)
                return
            }
        }

        super.onUpdatedUrl(url: url)
    }

    private func processInisisTrans(_ appScheme: String, _ url: URL) {
        func isParseUrl(_ str: String) -> Bool {
            if URL(string: str) != nil {
                return true
            } else {
                return false
            }
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
            s.contains(CONST.IAMPORT_DUMMY_URL)
        }.first

        if let urlStr = redirectUrl, let url = URL(string: urlStr) {
            print("parse url \(url.absoluteString)")
            RxBus.shared.post(event: EventBus.WebViewEvents.FinalBankPayProcess(url: url))
        }
    }
}
