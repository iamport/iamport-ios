//
// Created by BingBong on 2021/01/08.
//

import Foundation
import WebKit
import RxBus
import RxSwift

class CertificationWebViewStrategy: WebViewStrategy {

    override func onUpdatedUrl(url: URL) {
        dlog("CertificationWebViewStrategy onUpdatedUrl \(url)")
        if (Utils.isAppUrl(url)) {
            print("isAppUrl")
            RxBus.shared.post(event: EventBus.WebViewEvents.ThirdPartyUri(thirdPartyUri: url))
            return
        }
    }

    override func doWork(_ payment: Payment) {
        super.doWork(payment)
    }

}
