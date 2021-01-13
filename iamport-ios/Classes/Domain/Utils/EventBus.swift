//
// Created by BingBong on 2021/01/08.
//

import Foundation
import RxBus
import RxSwift

class EventBus {

    public static let shared = EventBus()

    let paymentSubject = BehaviorSubject<Payment?>(value: nil)

    var paymentBus: Observable<Payment?> {
        paymentSubject.asObservable()
    }

    let impResponseSubject = PublishSubject<IamPortResponse?>()

    public var impResponseBus: Observable<IamPortResponse?> {
        impResponseSubject.asObservable()
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
            let openWebView: Payment
        }

        struct ChangeUrl: BusEvent {
            let url: URL
        }

        struct FinalBackPayProcess: BusEvent {
            let url: URL
        }

        /*
         외부앱 종료시 받은 URL(for 뱅크페이 앱 처리)
         */
        struct ReceivedURL : BusEvent {
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