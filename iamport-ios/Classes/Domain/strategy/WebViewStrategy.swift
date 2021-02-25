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
        RxBus.shared.post(event: EventBus.WebViewEvents.OpenWebView())
    }

    override func onUpdatedUrl(url: URL) {
        super.onUpdatedUrl(url: url)

        if (Utils.isAppUrl(url)) {
            print("isAppUrl")
            RxBus.shared.post(event: EventBus.WebViewEvents.ThirdPartyUri(thirdPartyUri: url))
            return
        }

        if (Utils.isPaymentOver(url)) {
            let response = Utils.getQueryStringToImpResponse(url)
            dlog("paymentOver :: \(String(describing: response))")
            ddump(response)
            sdkFinish(response)
            return
        }
    }
}
