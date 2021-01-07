//
// Created by BingBong on 2021/01/05.
//

import Foundation
import WebKit

public class IamportSdk {

    let viewModel = WebViewModel()
    let parentViewController: UIViewController

    public init(_ parentViewController: UIViewController) {
        self.parentViewController = parentViewController
    }

    /**
     * 뷰모델 데이터 클리어
     */
    func clearData() {
//        d("clearData!")
//        updatePolling(false)
//        controlForegroundService(false)
//        viewModel.clearData()
    }

    internal func initStart(payment: Payment, paymentResultCallback: ((IamPortResponse?) -> Void)?) {
        observeViewModel(payment) // 관찰할 LiveData
    }

    private func observeViewModel(_ payment: Payment?) {
        if let payment = payment {
            // 결제결과 옵저빙
//            viewModel.impResponse().observe(owner, EventObserver(this::sdkFinish))

            // 웹뷰앱 열기
//            viewModel.webViewPayment().observe(owner, EventObserver(this::requestWebViewPayment))

            // 결제 시작
//            preventOverlapRun.launch { requestPayment(pay) }

            let wvController = WebViewController()
            wvController.setPayment(payment) // TODO 이방식이 맞는지 생각해보자
            parentViewController.navigationController?.pushViewController(wvController, animated: true)

            print("check nvc :: \(parentViewController.navigationController)")
        }
    }

}