//
// Created by BingBong on 2021/01/19.
//

import Foundation
import RxSwift
import RxBus

class MainViewModel {

    private var disposeBag = DisposeBag()
    private let repository = StrategyRepository() // TODO dependency inject

    func clear() {
        disposeBag = DisposeBag()
    }

    func judgePayment(_ payment: Payment) {

        subscribe()

        DispatchQueue.main.async { [weak self] in

            Payment.validator(payment) { valid, desc in
                print("Payment validator valid :: \(valid), valid :: \(desc)")
                if (!valid) {
                    IamPortResponse.makeFail(payment: payment, msg: desc).do { it in
                        self?.clear()
                        EventBus.shared.impResponseRelay.accept(it)
                    }
                }
            }

            // 판단 시작
            self?.repository.judgeStrategy.doWork(payment)
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
    private func judgeProcess(_ judge: (JudgeStrategy.JudgeKinds, UserData?, Payment)) {
        dlog("JudgeEvent \(judge)")
        switch judge.0 {
        case .CHAI:
            judge.1?.do { userData in
                repository.chaiStrategy.doWork(userData.pg_id, judge.2)
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
    func requestApprovePayments(approve: IamPortApprove) {
        print("차이 최종 결제 요청")
        repository.chaiStrategy.requestApprovePayments(approve: approve)
    }

}
