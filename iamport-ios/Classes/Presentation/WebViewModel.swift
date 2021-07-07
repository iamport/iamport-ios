//
// Created by BingBong on 2021/01/05.
//

import RxBus
import RxSwift
import Foundation

internal class WebViewModel {

    let repository = StrategyRepository() // TODO dependency inject

//    func clear() {
//        repository.clear()
//    }

    /**
     * 뱅크페이 결과 처리
     */
    func processBankPayPayment(_ payment : Payment, _ url : URL) {
        repository.processBankPayPayment(payment, url)
    }

    /**
     * 결제 요청
     */
    func requestPayment(payment: Payment) {
        dlog("뷰모델에 결제 요청했니")
        DispatchQueue.main.async {
            self.repository.getWebViewStrategy(payment).doWork(payment)
        }
    }

//    /**
//     * WebMode Only 결제 요청
//     */
//    func requestPaymentIgnoreNativePG(payment: Payment) {
//        dlog("뷰모델에 결제 요청했니 IgnoreNativePG ")
//        DispatchQueue.main.async {
//            self.repository.getWebViewStrategy(payment).doWork(payment)
//        }
//    }

    /**
     * 본인인증 요청
     */
    func requestCertification(_ payment: Payment) {
        dlog("뷰모델에 본인인증 요청했니")
        DispatchQueue.main.async {
            self.repository.requestCertification(payment)
        }
    }
}