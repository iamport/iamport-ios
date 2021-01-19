//
// Created by BingBong on 2021/01/08.
//

import Foundation
import Then

class StrategyRepository {

//    let judgeStrategy: JudgeStrategy by inject() // 결제 판별
//    let chaiStrategy: ChaiStrategy by inject() // 결제 중 BG 폴링하는 차이 전략

    private let webViewStrategy = WebViewStrategy() // webview 사용하는 pg
    private let niceTransWebViewStrategy = NiceTransWebViewStrategy()
    private let inisisTransWebViewStrategy = InisisTransWebViewStrategy()

    func clear() {
        EventBus.shared.closeSubject.onNext(())
    }

    /**
     * 실제로 앱 띄울 결제 타입
     */
    enum PaymentKinds {
        case CHAI, NICE, WEB, INISIS
    }

    /**
     * PG 와 PayMethod 로 결제 타입하여 가져옴
     * @return PaymenyKinds
     */
    private func getPaymentKinds(payment: Payment) -> PaymentKinds {

        func isChaiPayment(pgPair: Pair<PG, PayMethod>) -> Bool {
            pgPair.first == PG.chai
        }

        func isNiceTransPayment(pgPair: Pair<PG, PayMethod>) -> Bool {
            pgPair.first == PG.nice && pgPair.second == PayMethod.trans
        }

        func isInisisTransPayment(pgPair: Pair<PG, PayMethod>) -> Bool {
            pgPair.first == PG.html5_inicis && pgPair.second == PayMethod.trans
        }

        let request = payment.iamPortRequest
        print(request.pgEnum)
        if let it = request.pgEnum {
            let pair = Pair(first: it, second: request.pay_method)
            if (isChaiPayment(pgPair: pair)) {
                return PaymentKinds.CHAI
            } else if (isNiceTransPayment(pgPair: pair)) {
                return PaymentKinds.NICE
            } else if (isInisisTransPayment(pgPair: pair)) {
                return PaymentKinds.INISIS
            } else {
                return PaymentKinds.WEB
            }
        } else {
            return PaymentKinds.WEB // default WEB
        }
    }

    func getWebViewStrategy(_ payment: Payment) -> IStrategy {
        switch getPaymentKinds(payment: payment) {
        case .NICE:
            return niceTransWebViewStrategy
        case .INISIS:
            return inisisTransWebViewStrategy
        case .WEB:
            return webViewStrategy
        default:
            return webViewStrategy
        }
    }

    func getNiceTransWebViewStrategy() -> NiceTransWebViewStrategy {
        niceTransWebViewStrategy
    }

    func processBankPayPayment(_ payment : Payment, _ url : URL) {
        if(getPaymentKinds(payment: payment) == PaymentKinds.NICE) {
            niceTransWebViewStrategy.processBankPayPayment(url)
        }
    }


}
