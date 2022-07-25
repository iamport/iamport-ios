//
// Created by BingBong on 2021/01/22.
//

import Foundation
import RxBusForPort
import RxSwift

public class BaseStrategy: IStrategy {

    var disposeBag = DisposeBag()
    var payment: Payment?

    func clear() {
        payment = nil
        disposeBag = DisposeBag()
    }

    func successFinish(payment: Payment, prepareData: PrepareData? = nil, msg: String) {
        print(msg)
        IamPortResponse.makeSuccess(payment: payment, prepareData: prepareData, msg: msg).do { it in
            sdkFinish(it)
        }
    }

    func failureFinish(payment: Payment, prepareData: PrepareData? = nil, msg: String) {
        print(msg)
        IamPortResponse.makeFail(payment: payment, prepareData: prepareData, msg: msg).do { it in
            sdkFinish(it)
        }
    }

    func sdkFinish(_ response: IamPortResponse?) {
        clear()
//        RxBus.shared.post(event: EventBus.WebViewEvents.ImpResponse(impResponse: response))
        EventBus.shared.impResponseRelay.accept(response)
    }

    func doWork(_ payment: Payment) {
        clear()
        self.payment = payment

        EventBus.shared.clearBus.subscribe { [weak self] event in
            self?.clear()
        }.disposed(by: disposeBag)

    }


    /**
     * 성공해서 SDK 종료
     */
    func successFinish(payment: Payment) {
        successFinish(payment: payment, msg: CONST.EMPTY_STR)
    }

}
