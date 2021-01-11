//
// Created by BingBong on 2021/01/05.
//

import RxBus
import RxSwift
import Foundation

internal class WebViewModel {

    var disposeBag = DisposeBag()
    let repository = StrategyRepository()

    func clear() {
        disposeBag = DisposeBag()
        repository.clear()
    }

    /**
     * PG(nice or 비nice) 따라 webview client 가져오기
     */
//    func getWebViewClient(payment: Payment) -> WebViewClient {
//        return repository.getWebViewClient(payment)
//    }


    /**
     * 뱅크페이 결과 처리
     */
//    func processBankPayPayment(resPair: Pair<String, String>) {
//        repository.getNiceTransWebViewClient().processBankPayPayment(resPair)
//    }

    /**
     * activity 에서 결제 요청
     */
    func startPayment(_ payment: Payment) {
        print("startPayment")
        RxBus.shared.post(event: EventBus.WebViewEvents.PaymentEvent(webViewPayment: payment))
    }

    /**
     * 결제 요청
     */
    func requestPayment(payment: Payment) {
        print("뷰모델에 요청했니")
        DispatchQueue.main.async {
            self.repository.getWebViewStrategy(payment).doWork(payment)
        }
    }
}