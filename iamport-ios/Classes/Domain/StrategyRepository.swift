//
// Created by BingBong on 2021/01/08.
//

import Foundation
import Then

class StrategyRepository {

//    let judgeStrategy: JudgeStrategy by inject() // 결제 중 BG 폴링하는 차이 전략
//    let chaiStrategy: ChaiStrategy by inject() // 결제 중 BG 폴링하는 차이 전략

    private let webViewStrategy = WebViewStrategy() // webview 사용하는 pg
    private let niceTransWebViewStrategy = NiceTransWebViewStrategy()

    func clear() {
        webViewStrategy.clear()
        niceTransWebViewStrategy.clear()
    }

    /**
     * 실제로 앱 띄울 결제 타입
     */
    enum PaymentKinds {
        case CHAI, NICE, WEB
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

        let request = payment.iamPortRequest
        print(request.pgEnum)
        if let it = request.pgEnum {
            let pair = Pair(first: it, second: request.pay_method)
            if (isChaiPayment(pgPair: pair)) {
                return PaymentKinds.CHAI
            } else if (isNiceTransPayment(pgPair: pair)) {
                return PaymentKinds.NICE
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
        case .WEB:
            return webViewStrategy
        default:
            return webViewStrategy
        }
    }

    func getNiceTransWebViewStrategy() -> NiceTransWebViewStrategy {
        niceTransWebViewStrategy
    }


}
