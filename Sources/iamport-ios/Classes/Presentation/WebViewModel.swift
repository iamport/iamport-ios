//
// Created by BingBong on 2021/01/05.
//

import Foundation
import RxBusForPort
import RxSwift

internal class WebViewModel {
    let repository = StrategyRepository()
    let delegate = IamportWKWebViewDelegate()

    /**
     * 뱅크페이 결과 처리
     */
    func processBankPayPayment(_ request: IamportRequest, _ url: URL) {
        repository.processBankPayPayment(request, url)
    }

    /**
     * 결제 요청
     */
    func requestPayment(request: IamportRequest) {
        debug_log("Payment requested")
        DispatchQueue.main.async {
            self.repository.getWebViewStrategy(request).doWork(request)
        }
    }

    /**
     * 본인인증 요청
     */
    func requestCertification(_ request: IamportRequest) {
        debug_log("Certification requested")
        DispatchQueue.main.async {
            self.repository.requestCertification(request)
        }
    }
}
