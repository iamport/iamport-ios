//
// Created by BingBong on 2021/01/05.
//

import Foundation
import WebKit
import RxBus
import RxSwift

public class IamportSdk {

    let viewModel = WebViewModel()
    let parentViewController: UIViewController
    var paymentResultCallback: ((IamPortResponse?) -> Void)?
    var disposeBag = DisposeBag()

    public init(_ parentViewController: UIViewController) {
        self.parentViewController = parentViewController
    }

    struct Events {
        struct PaymentBus: BusEvent {
            let payment: Payment
        }
    }

    /**
     * 뷰모델 데이터 클리어
     */
    func clearData() {
//        d("clearData!")
//        updatePolling(false)
//        controlForegroundService(false)
//        viewModel.clearData()
        disposeBag = DisposeBag()
    }

    internal func initStart(payment: Payment, paymentResultCallback: ((IamPortResponse?) -> Void)?) {
        self.paymentResultCallback = paymentResultCallback
        observeViewModel(payment) // 관찰할 LiveData
    }


    private func sdkFinish(_ iamportResponse: IamPortResponse?) {
        print("iamportSdk 에서 종료입니다")
        clearData()
        paymentResultCallback?(iamportResponse)
    }

    func postReceivedURL(_ url : URL) {
        print("외부 결제앱 종료 후에 url 전달 받음 \(url)")
        RxBus.shared.post(event: EventBus.WebViewEvents.ReceivedURL(url: url))
    }

    private func observeViewModel(_ payment: Payment?) {
        if let payment = payment {
            // 결제결과 옵저빙
//            viewModel.impResponse().observe(owner, EventObserver(this::sdkFinish))

            // 웹뷰앱 열기
//            viewModel.webViewPayment().observe(owner, EventObserver(this::requestWebViewPayment))

            // 결제 시작
//            preventOverlapRun.launch { requestPayment(pay) }

            EventBus.shared.impResponseBus.subscribe { [weak self] iamportResponse in
                self?.sdkFinish(iamportResponse)
            }.disposed(by: disposeBag)

            EventBus.shared.paymentSubject.onNext(payment)

            let wvController = WebViewController()
            parentViewController.navigationController?.pushViewController(wvController, animated: false)

            print("check navigationController :: \(parentViewController.navigationController)")
        }
    }

}