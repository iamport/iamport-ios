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
        print("IamportSdk clearData!")
//        updatePolling(false)
//        controlForegroundService(false)

        viewModel.clear()
        EventBus.shared.clearRelay.accept(())
        disposeBag = DisposeBag()
    }

    private func sdkFinish(_ iamportResponse: IamPortResponse?) {
        print("I'mport SDK 에서 종료입니다")
        clearData()
        paymentResult?(iamportResponse)
    }

    internal func initStart(payment: Payment, paymentResultCallback: @escaping (IamPortResponse?) -> Void) {
        clearData()
        paymentResult = paymentResultCallback
        subscribe(payment) // 관찰할 옵저버블
    }

    func postReceivedURL(_ url: URL) {
        #if DEBUG
        print("외부앱 종료 후 전달 받음 => \(url)")
        #endif
        RxBus.shared.post(event: EventBus.WebViewEvents.ReceivedAppDelegateURL(url: url))
    }

    private func subscribe(_ payment: Payment) {
        // 결제결과 옵저빙
        EventBus.shared.impResponseBus.subscribe { [weak self] iamportResponse in
            self?.sdkFinish(iamportResponse)
        }.disposed(by: disposeBag)

        // TODO subscribe 결제결과
        // subscribe 웹뷰열기
        EventBus.shared.paymentBus.subscribe { [weak self] event in
            guard let el = event.element, let pay = el else {
                print("Error paymentBus is nil")
                return
            }

            self?.openWebViewController(pay)
        }.disposed(by: disposeBag)

        // subscribe 차이앱열기
        RxBus.shared.asObservable(event: EventBus.MainEvents.ChaiUri.self).subscribe { [weak self] event in
            guard let el = event.element else {
                print("Error not found PaymentEvent")
                return
            }

            let result = Utils.openApp(el.appAddress) // 앱 열기
            // TODO openApp result = false 일 떄, 이미 chai strategy 가 동작할 시나리오
            // 취소? 타임아웃 연장? 그대로 진행? ... 등
            // 어차피 앱 재설치시, 다시 차이 결제 페이지로 진입할 방법이 없음
            if (!result) {
                if let scheme = el.appAddress.scheme,
                   let urlString = AppScheme.getAppStoreUrl(scheme: scheme),
                   let url = URL(string: urlString) {
                    Utils.openApp(url) // 앱스토어 이동
                } else {
                    self?.sdkFinish(IamPortResponse.makeFail(payment: payment, msg: "지원하지 않는 App Scheme\(String(describing: el.appAddress.scheme)) 입니다"))
                }
            }

        }.disposed(by: disposeBag)

        // TODO subscribe 폴링여부
        // TODO 차이 결제 상태 approve 처리

        requestPayment(payment)

    }


    private func requestPayment(_ payment: Payment) {

        Payment.validator(payment) { valid, desc in
            print("Payment validator valid :: \(valid), valid :: \(desc)")
            if (!valid) {
                self.sdkFinish(IamPortResponse.makeFail(payment: payment, msg: desc))
                return
            }
        }

        if (!Utils.isInternetAvailable()) {
            sdkFinish(IamPortResponse.makeFail(payment: payment, msg: "네트워크 연결 안됨"))
            return
        }

        viewModel.judgePayment(payment)
    }

    // 웹뷰 컨트롤러 열기 및 데이터 전달
    private func openWebViewController(_ payment: Payment) {
        DispatchQueue.main.async { [weak self] in
            EventBus.shared.webViewPaymentRelay.accept(payment)
            self?.naviController.pushViewController(WebViewController(), animated: true)
//            self?.naviController.present(WebViewController(), animated: true)
            #if DEBUG
            print("check navigationController :: \(String(describing: self?.naviController))")
            #endif
        }
    }

}