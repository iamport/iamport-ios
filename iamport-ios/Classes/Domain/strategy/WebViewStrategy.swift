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

        if(isAppUrl(uri: url)) {
            RxBus.shared.post(event: EventBus.WebViewEvents.ThirdPartyUri(thirdPartyUri: url))
        }

        if(isPaymentOver(uri: url)) {
            let response = Utils.getQueryStringToImpResponse(url)
            print("paymentOver :: \(response)")
            dump(response)
            sdkFinish(response)
        }

    }
}
