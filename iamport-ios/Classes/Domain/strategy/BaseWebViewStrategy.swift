//
// Created by BingBong on 2021/01/08.
//

import Foundation
import WebKit
import RxBus
import RxSwift

public class BaseWebViewStrategy: IStrategy {
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
        RxBus.shared.post(event: EventBus.WebViewEvents.ImpResponse(impResponse: response))
    }

    func doWork(_ payment: Payment) {
        clear()
        self.payment = payment

        EventBus.shared.closeSubject.subscribe { [weak self] event in
            self?.clear()
        }.disposed(by: disposeBag)

        RxBus.shared.asObservable(event: EventBus.WebViewEvents.UpdateUrl.self)
                .subscribe { [weak self] event in
                    guard let el = event.element else {
                        print("Error not found WebViewEvents")
                        return
                    }
                    #if DEBUG
                    print("onUpdatedUrl \(el.url)")
                    #endif
                    self?.onUpdatedUrl(url: el.url)
                }.disposed(by: disposeBag)
    }

    func onUpdatedUrl(url: URL) {
    }

    /**
     * 성공해서 SDK 종료
     */
    func successFinish(payment: Payment) {
        successFinish(payment: payment, msg: CONST.EMPTY_STR)
    }

}
