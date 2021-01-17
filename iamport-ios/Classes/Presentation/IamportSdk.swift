//
// Created by BingBong on 2021/01/05.
//

import Foundation
import WebKit
import RxBus
import RxSwift

public class IamportSdk {

//    let viewModel = ViewModel()
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
        EventBus.shared.closeSubject.onNext(())
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
        print("외부앱 종료 후 전달 받음 => \(url)")
        RxBus.shared.post(event: EventBus.WebViewEvents.ReceivedAppDelegateURL(url: url))
    }

    private func observe(_ payment: Payment) {
        // 결제결과 옵저빙
        EventBus.shared.impResponseBus.subscribe { [weak self] iamportResponse in
            self?.sdkFinish(iamportResponse)
        }.disposed(by: disposeBag)

        // TODO for observe CHAI
        // ...

        openWebViewController(payment)
    }

    // 웹뷰 컨트롤러 열기 및 데이터 전달
    private func openWebViewController(_ payment: Payment) {
        DispatchQueue.main.async { [weak self] in
            EventBus.shared.paymentSubject.onNext(payment)
            self?.naviController.pushViewController(WebViewController(), animated: true)
//            self?.naviController.present(WebViewController(), animated: true)
            print("check navigationController :: \(self?.naviController.navigationController)")
        }
    }

}