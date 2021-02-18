//
// Created by BingBong on 2021/01/19.
//

import Foundation
import RxSwift
import RxBus

class MainViewModel {

    var disposeBag = DisposeBag()
    let repository = StrategyRepository() // TODO dependency inject

    func clear() {
        disposeBag = DisposeBag()
    }

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

            // judge
            self?.repository.judgeStrategy.doWork(payment)
        }
    }

    private func judgeProcess(_ judge: (JudgeStrategy.JudgeKinds, UserData?, Payment)) {
        print("JudgeEvent \(judge)")
        switch judge.0 {
        case .CHAI:
            if let userData = judge.1 {
                repository.chaiStrategy.doWork(userData.pg_id, judge.2)
            }
        case .WEB:
//            RxBus.shared.post(event: EventBus.WebViewEvents.PaymentEvent(webViewPayment: judge.2))
            EventBus.shared.paymentRelay.accept(judge.2)
        case .EMPTY:
            print("판단불가 \(judge)")
        }
    }
}
