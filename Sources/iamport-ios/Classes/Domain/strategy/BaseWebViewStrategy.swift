//
// Created by BingBong on 2021/01/08.
//

import Foundation
import RxBusForPort
import RxSwift
import WebKit

public class BaseWebViewStrategy: IStrategy {
    var disposeBag = DisposeBag()
    var request: IamportRequest?
    let eventBus: EventBus
    
    init(eventBus: EventBus) {
        self.eventBus = eventBus
    }

    func clear() {
        request = nil
        disposeBag = DisposeBag()
    }

    func success(request: IamportRequest, msg: String) {
        print(msg)
        IamportResponse.makeSuccess(request: request, msg: msg).do { it in
            finish(it)
        }
    }

    func failure(request: IamportRequest, msg: String) {
        print(msg)
        IamportResponse.makeFail(request: request, msg: msg).do { it in
            finish(it)
        }
    }

    func finish(_ response: IamportResponse?) {
        clear()
        RxBus.shared.post(event: EventBus.WebViewEvents.ImpResponse(impResponse: response))
    }

    func doWork(_ request: IamportRequest) {
        clear()
        self.request = request

        eventBus.clearBus.subscribe { [weak self] _ in
            self?.clear() // 종료 없이 only clear
        }.disposed(by: disposeBag)

        RxBus.shared.asObservable(event: EventBus.WebViewEvents.UpdateUrl.self)
            .subscribe { [weak self] event in
                guard let el = event.element else {
                    print("Error not found WebViewEvents")
                    return
                }
                debug_log("onUpdatedUrl \(el.url)")
                self?.onUpdatedUrl(url: el.url)
            }.disposed(by: disposeBag)
    }

    func onUpdatedUrl(url _: URL) {
        // NOTHING here, use Child Strategy
    }

    /**
     * 성공해서 SDK 종료
     */
    func success(request: IamportRequest) {
        success(request: request, msg: Constant.EMPTY_STR)
    }
}
