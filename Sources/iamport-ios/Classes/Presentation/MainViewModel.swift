//
// Created by BingBong on 2021/01/19.
//

import Foundation
import RxBusForPort
import RxSwift

class MainViewModel {
    private var disposeBag = DisposeBag()
    private let repository = StrategyRepository() // TODO: dependency inject

    func clear() {
        disposeBag = DisposeBag()
    }

    func judgePayment(_ payment: IamportRequest, ignoreNative: Bool = false) {
        subscribe()

        DispatchQueue.main.async { [weak self] in
            IamportRequest.validator(payment) { valid, desc in
                print("one more Payment validator valid :: \(valid), valid :: \(desc)")
                if !valid {
                    IamportResponse.makeFail(payment: payment, msg: desc).do { it in
                        self?.clear()
                        EventBus.shared.impResponseRelay.accept(it)
                    }
                }
            }

            // 판단 시작
            self?.repository.judgeStrategy.doWork(payment, ignoreNative: ignoreNative)
        }
    }

    // 판단 결과 구독
    func subscribe() {
        clear()
        RxBus.shared.asObservable(event: EventBus.MainEvents.JudgeEvent.self).subscribe { [weak self] event in
            guard let el = event.element else {
                print("Error not found JudgeEvent")
                return
            }
            self?.judgeProcess(el.judge)
        }.disposed(by: disposeBag)
    }

    // 판단 결과 처리
    private func judgeProcess(_ judge: (JudgeStrategy.JudgeKinds, UserData?, IamportRequest)) {
        debug_log("JudgeEvent \(judge)")
        switch judge.0 {
        case .CHAI:
            judge.1?.do { userData in
                if let pgId = userData.pg_id {
                    repository.chaiStrategy.doWork(pgId, judge.2)
                }
            }
        case .WEB, .CERT:
            EventBus.shared.paymentRelay.accept(judge.2) // 웹뷰 컨트롤러 열기
        case .ERROR:
            print("판단불가 \(judge)")
        }
    }

    /**
     * 차이 최종 결제 요청
     */
    func requestApprovePayments(approve: IamportApprove) {
        print("차이 최종 결제 요청")
        repository.chaiStrategy.requestApprovePayments(approve: approve)
    }

    /**
     * 차이 앱 없으므로 폴링 stop
     */
    func stopChaiStrategy() {
        print("차이 앱 없으므로 폴링 stop")
        repository.chaiStrategy.clear()
    }
}
