//
// Created by BingBong on 2021/01/22.
//

import Foundation
import RxBusForPort
import RxSwift

public class BaseStrategy: IStrategy {
    var disposeBag = DisposeBag()
    var payment: IamportRequest?

    func clear() {
        payment = nil
        disposeBag = DisposeBag()
    }

    /**
     * 성공해서 SDK 종료
     */
    func success(request: IamportRequest) {
        success(request: request, msg: Constant.EMPTY_STR)
    }

    func success(request: IamportRequest, prepareData: PrepareData? = nil, msg: String) {
        print(msg)
        IamportResponse.makeSuccess(payment: request, prepareData: prepareData, msg: msg).do { it in
            finish(it)
        }
    }

    func failure(request: IamportRequest, prepareData: PrepareData? = nil, msg: String) {
        print(msg)
        IamportResponse.makeFail(payment: request, prepareData: prepareData, msg: msg).do { it in
            finish(it)
        }
    }

    func finish(_ response: IamportResponse?) {
        clear()
        EventBus.shared.impResponseRelay.accept(response)
    }

    func doWork(_ payment: IamportRequest) {
        clear()
        self.payment = payment

        EventBus.shared.clearBus.subscribe { [weak self] _ in
            self?.clear()
        }.disposed(by: disposeBag)
    }
}
