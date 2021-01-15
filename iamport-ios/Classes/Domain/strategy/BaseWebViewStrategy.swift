//
// Created by BingBong on 2021/01/08.
//

import Foundation
import WebKit
import RxBus
import RxSwift

protocol IStrategy {
    func clear()
    func start()
    func doWork(_ payment: Payment)
    func sdkFinish(_ response: IamPortResponse?)
}

public class BaseWebViewStrategy: IStrategy {
    var disposeBag = DisposeBag()
    var payment : Payment?

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
        disposeBag = DisposeBag()
        RxBus.shared.post(event: EventBus.WebViewEvents.ImpResponse(impResponse: response))
    }

    func start() {
        RxBus.shared.asObservable(event: EventBus.WebViewEvents.ChangeUrl.self)
                .asyncMain().subscribe { [weak self] event in
                    self?.onChangeUrl(url: event.element!.url)
                }.disposed(by: disposeBag)
    }

    func doWork(_ payment: Payment) {
        clear()
        self.payment = payment
        start()
    }

    func onChangeUrl(url: URL) {
    }

    /**
     * 성공해서 SDK 종료
     */
    func successFinish(payment: Payment) {
        successFinish(payment: payment, msg: CONST.EMPTY_STR)
    }

}
