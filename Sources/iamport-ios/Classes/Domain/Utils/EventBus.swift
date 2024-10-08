//
// Created by BingBong on 2021/01/08.
//

import Foundation
import RxRelay
import RxSwift

class EventBus {
    public static let shared = EventBus()

    // SDK 에 결제요청
    let paymentRelay = PublishRelay<IamportRequest?>()

    var paymentBus: Observable<IamportRequest?> {
        paymentRelay.asObservable()
    }

    // 실제 종료 시그널 IamportSdk 에서 사용
    let impResponseRelay = PublishRelay<IamportResponse?>()

    public var impResponseBus: Observable<IamportResponse?> {
        impResponseRelay.asObservable()
    }

    // 각종 데이터 초기화
    let clearRelay = PublishRelay<Void>()

    public var clearBus: Observable<Void> {
        clearRelay.asObservable()
    }

    // WebViewController 에 결제요청
    let webViewPaymentRelay = BehaviorRelay<IamportRequest?>(value: nil)

    var webViewPaymentBus: Observable<IamportRequest?> {
        webViewPaymentRelay.asObservable()
    }

    enum MainEvents {
        // 현재 결제 종류 판별
        struct JudgeEvent: BusEvent {
            let judge: (JudgeStrategy.JudgeKind, UserData?, IamportRequest)
        }

        // 차이앱 열기 위한 url
        struct ChaiUri: BusEvent {
            let appAddress: URL
        }

        // 머천트에게 최종 컨펌 받기 위한 요청
        struct AskApproveFromChai: BusEvent {
            let approve: IamportApprove
        }
    }

    enum WebViewEvents {
        /**
         * WebViewController, WebViewStrategy 에서만 사용
         * 결제 결과 콜백 및 종료
         */
        struct ImpResponse: BusEvent {
            let impResponse: IamportResponse?
        }

        /**
         * 오픈 웹뷰 이벤트
         */
        struct OpenWebView: BusEvent {}

        // webview 에 업데이트 되는 현재 url
        struct UpdateUrl: BusEvent {
            let url: URL
        }

        struct FinalBankPayProcess: BusEvent {
            let url: URL
        }

        /**
         * 외부앱 종료시 받은 URL(for 뱅크페이 앱 처리)
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
    }
}
