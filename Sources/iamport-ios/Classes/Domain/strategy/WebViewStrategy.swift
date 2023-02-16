//
// Created by BingBong on 2021/01/08.
//

import Foundation
import RxBusForPort
import RxSwift
import WebKit

class WebViewStrategy: BaseWebViewStrategy {
    override func doWork(_ request: IamportRequest) {
        super.doWork(request)
        print("헬로 WebViewStrategy")
        // 오픈 웹뷰!
        RxBus.shared.post(event: EventBus.WebViewEvents.OpenWebView())
    }

    override func onUpdatedUrl(url: URL) {
        super.onUpdatedUrl(url: url)

        if url.scheme == Constant.ABOUT_BLANK_SCHEME {
            return // 이동하지 않음
        }

        if Utils.isAppUrl(url) {
            RxBus.shared.post(event: EventBus.WebViewEvents.ThirdPartyUri(thirdPartyUri: url))
            return
        }

        if Utils.isPaymentOver(url) {
            let response = Utils.getQueryStringToImpResponse(url)
            debug_log("paymentOver :: \(String(describing: response))")
            debug_dump(response)
            finish(response)
            return
        }
    }
}
