//
// Created by BingBong on 2021/01/22.
//

import Foundation
import RxBusForPort
import RxSwift

public class BaseStrategy: IStrategy {
    var disposeBag = DisposeBag()
    var request: IamportRequest?

    func clear() {
        request = nil
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
        IamportResponse.makeSuccess(request: request, prepareData: prepareData, msg: msg).do { it in
            finish(it)
        }
    }

    func failure(request: IamportRequest, prepareData: PrepareData? = nil, msg: String) {
        print(msg)
        IamportResponse.makeFail(request: request, prepareData: prepareData, msg: msg).do { it in
            finish(it)
        }
    }

    func finish(_ response: IamportResponse?) {
        clear()
        EventBus.shared.impResponseRelay.accept(response)
    }

    func doWork(_ request: IamportRequest) {
        clear()
        self.request = request

        EventBus.shared.clearBus.subscribe { [weak self] _ in
            self?.clear()
        }.disposed(by: disposeBag)
    }
}
