//
// Created by BingBong on 2021/01/05.
//

import Foundation
import WebKit
import RxBus
import RxSwift

public class IamportSdk {

    let viewModel = MainViewModel()
    let naviController: UINavigationController
    var paymentResult: ((IamPortResponse?) -> Void)?
    var disposeBag = DisposeBag()

    public init(_ naviController: UINavigationController) {
        self.naviController = naviController
    }

    // 뷰모델 데이터 클리어
    func clearData() {
//        d("clearData!")
//        updatePolling(false)
//        controlForegroundService(false)
//        viewModel.clearData()
        EventBus.shared.closeSubject.onNext(()) // FIXME 어디서 중복됨
        disposeBag = DisposeBag()
    }

    private func sdkFinish(_ iamportResponse: IamPortResponse?) {
        print("Iamport SDK 에서 종료입니다")
        clearData()
        paymentResult?(iamportResponse)
    }

    internal func initStart(payment: Payment, paymentResultCallback: @escaping (IamPortResponse?) -> Void) {
        clearData()
        paymentResult = paymentResultCallback
        observe(payment) // 관찰할 옵저버블
    }

    func postReceivedURL(_ url: URL) {
        #if DEBUG
        print("외부앱 종료 후 전달 받음 => \(url)")
        #endif
        RxBus.shared.post(event: EventBus.WebViewEvents.ReceivedAppDelegateURL(url: url))
    }

    private func observe(_ payment: Payment) {
        // 결제결과 옵저빙
        EventBus.shared.impResponseBus.subscribe { [weak self] iamportResponse in
            self?.sdkFinish(iamportResponse)
        }.disposed(by: disposeBag)

        // TODO subscribe 결제결과
        // subscribe 웹뷰열기
        RxBus.shared.asObservable(event: EventBus.WebViewEvents.PaymentEvent.self).subscribe { [weak self] event in
            guard let el = event.element else {
                print("Error not found PaymentEvent")
                return
            }

            self?.openWebViewController(el.webViewPayment)
        }.disposed(by: disposeBag)

        // subscribe 차이앱열기
        RxBus.shared.asObservable(event: EventBus.MainEvents.ChaiUri.self).subscribe { [weak self] event in
            guard let el = event.element else {
                print("Error not found PaymentEvent")
                return
            }

            let result = Utils.openApp(el.appAddress)
            // TODO true 때만 차이 스트레티지 동작 해야 함??
            if (!result) {
                if let scheme = el.appAddress.scheme, let url = URL(string: Utils.getMarketUrl(scheme: scheme)) {
                    Utils.openApp(url)
                }
            }

        }.disposed(by: disposeBag)

        // TODO subscribe 폴링여부
        // TODO 차이 결제 상태 approve 처리

        requestPayment(payment)

    }

    private func requestPayment(_ payment: Payment) {

        // TODO Payment data validator

        // TODO 네트워크 상태 체크

        viewModel.judgePayment(payment)
    }

    // 웹뷰 컨트롤러 열기 및 데이터 전달
    private func openWebViewController(_ payment: Payment) {
        DispatchQueue.main.async { [weak self] in
            EventBus.shared.paymentSubject.onNext(payment)
            self?.naviController.pushViewController(WebViewController(), animated: true)
//            self?.naviController.present(WebViewController(), animated: true)
            #if DEBUG
            print("check navigationController :: \(self?.naviController)")
            #endif
        }
    }

}