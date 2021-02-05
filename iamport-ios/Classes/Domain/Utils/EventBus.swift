//
// Created by BingBong on 2021/01/08.
//

import Foundation
import RxBus
import RxSwift
import RxRelay

class EventBus {

    public static let shared = EventBus()

    let paymentRelay = BehaviorRelay<Payment?>(value: nil)

    var paymentBus: Observable<Payment?> {
        paymentRelay.asObservable()
    }

    let impResponseRelay = PublishRelay<IamPortResponse?>()

    public var impResponseBus: Observable<IamPortResponse?> {
        impResponseRelay.asObservable()
    }

    let closeRelay = PublishRelay<Void>()

    public var closeBus: Observable<Void> {
        closeRelay.asObservable()
    }

    let clearRelay = PublishRelay<Void>()

    public var clearBus: Observable<Void> {
        clearRelay.asObservable()
    }

    struct MainEvents {

        struct JudgeEvent: BusEvent {
            let judge: (JudgeStrategy.JudgeKinds, UserData?, Payment)
        }

        struct ChaiUri: BusEvent {
            let appAddress: URL
        }

    }

    struct WebViewEvents {

        /**
         * 결제 데이터
         */
        struct PaymentEvent: BusEvent {
            let webViewPayment: Payment
        }

        /**
         * 오픈 웹뷰
         */
        struct OpenWebView: BusEvent {
        }

        struct UpdateUrl: BusEvent {
            let url: URL
        }

        struct FinalBankPayProcess: BusEvent {
            let url: URL
        }

        /*
         외부앱 종료시 받은 URL(for 뱅크페이 앱 처리)
         */
        struct ReceivedAppDelegateURL: BusEvent {
            let url: URL
        }

        /**
         * 뱅크페이 외부앱 열기
         */
        struct NiceTransRequestParam: BusEvent {
            let niceTransRequestParam: String
        }

        /**
         * 외부앱 열기
         */
        struct ThirdPartyUri: BusEvent {
            let thirdPartyUri: URL
        }

        /**
         * 결제 결과 콜백 및 종료
         */
        struct ImpResponse: BusEvent {
            let impResponse: IamPortResponse?
        }
    }

}