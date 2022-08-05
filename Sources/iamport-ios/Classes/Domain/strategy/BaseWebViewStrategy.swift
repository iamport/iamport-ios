//
// Created by BingBong on 2021/01/08.
//

import Foundation
import WebKit
import RxBusForPort
import RxSwift

public class BaseWebViewStrategy: IStrategy {
    var disposeBag = DisposeBag()
    var payment: Payment?

    func clear() {
        payment = nil
        disposeBag = DisposeBag()
    }

    func successFinish(payment: Payment, msg: String) {
        print(msg)
        IamPortResponse.makeSuccess(payment: payment, msg: msg).do { it in
            sdkFinish(it)
        }
    }

    func failureFinish(payment: Payment, msg: String) {
        print(msg)
        IamPortResponse.makeFail(payment: payment, msg: msg).do { it in
            sdkFinish(it)
        }
    }

    func sdkFinish(_ response: IamPortResponse?) {
        clear()
        RxBus.shared.post(event: EventBus.WebViewEvents.ImpResponse(impResponse: response))
    }

    func doWork(_ payment: Payment) {
        clear()
        self.payment = payment

        EventBus.shared.clearBus.subscribe { [weak self] event in
            self?.clear() // 종료 없이 only clear
        }.disposed(by: disposeBag)

        RxBus.shared.asObservable(event: EventBus.WebViewEvents.UpdateUrl.self)
                .subscribe { [weak self] event in
                    guard let el = event.element else {
                        print("Error not found WebViewEvents")
                        return
                    }
                    dlog("onUpdatedUrl \(el.url)")
                    self?.onUpdatedUrl(url: el.url)
                }.disposed(by: disposeBag)
    }

    func onUpdatedUrl(url: URL) {
        // NOTHING here, use Child Strategy
    }

    /**
     * 성공해서 SDK 종료
     */
    func successFinish(payment: Payment) {
        successFinish(payment: payment, msg: CONST.EMPTY_STR)
    }

}
