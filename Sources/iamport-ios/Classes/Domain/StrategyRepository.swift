//
// Created by BingBong on 2021/01/08.
//

import Foundation
import Then

class StrategyRepository {
    /**
     * 실제로 앱 띄울 결제 타입
     */
    enum PaymentKind {
        case CHAI, NICE, WEB, INICIS
    }
    init(eventBus: EventBus) {
        self.eventBus = eventBus
        judgeStrategy = JudgeStrategy(eventBus: self.eventBus)
        chaiStrategy = ChaiStrategy(eventBus: self.eventBus)
        webViewStrategy = WebViewStrategy(eventBus: self.eventBus)
        niceTransWebViewStrategy = NiceTransWebViewStrategy(eventBus: self.eventBus)
        inicisTransWebViewStrategy = InicisTransWebViewStrategy(eventBus: self.eventBus)
        certificationWebViewStrategy = CertificationWebViewStrategy(eventBus: self.eventBus)
    }
    let eventBus: EventBus

    let judgeStrategy: JudgeStrategy  // 결제 판별
    let chaiStrategy: ChaiStrategy // 결제 중 BG 폴링하는 차이 전략

    private let webViewStrategy: WebViewStrategy // webview 사용하는 pg
    private let niceTransWebViewStrategy: NiceTransWebViewStrategy
    private let inicisTransWebViewStrategy: InicisTransWebViewStrategy

    private let certificationWebViewStrategy: CertificationWebViewStrategy

    /**
     * PG 와 PayMethod 로 결제 타입하여 가져옴
     * @return PaymentKind
     */
    private func getPaymentKind(request: IamportRequest) -> PaymentKind {
        guard case let .payment(payment) = request.payload,
              let pg = payment.pgEnum else { return .WEB }

        switch (pg, PayMethod.convertPayMethod(payment.pay_method)) {
        case (PG.chai, _): return PaymentKind.CHAI
        case (PG.nice, PayMethod.trans): return PaymentKind.NICE
        case (PG.html5_inicis, PayMethod.trans): return PaymentKind.INICIS
        default: return PaymentKind.WEB
        }
    }

    func getWebViewStrategy(_ request: IamportRequest) -> IStrategy {
        switch getPaymentKind(request: request) {
        case .NICE:
            return niceTransWebViewStrategy

        case .INICIS:
            return inicisTransWebViewStrategy

        case .WEB:
            return webViewStrategy

        default:
            return webViewStrategy
        }
    }

    func getNiceTransWebViewStrategy() -> NiceTransWebViewStrategy {
        niceTransWebViewStrategy
    }

    func processBankPayPayment(_ request: IamportRequest, _ url: URL) {
        // NICE인 경우 뱅크페이를 수행합니다.
        if getPaymentKind(request: request) == PaymentKind.NICE {
            niceTransWebViewStrategy.processBankpayPayment(url)
            return
        }
    }

    func requestCertification(_ request: IamportRequest) {
        certificationWebViewStrategy.doWork(request)
    }
}
