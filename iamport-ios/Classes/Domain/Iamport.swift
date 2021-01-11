//
// Created by BingBong on 2021/01/05.
//

import Foundation
import WebKit

// 머천트에서 직접 가져다가 쓰는 부분
open class Iamport {

    public static let shared = Iamport()

    var iamportSdk: IamportSdk? = nil
    private var impCallbackFunction: ((IamPortResponse?) -> Void)? = nil // 결제결과 callbck type#2 함수 호출

    fileprivate init() {
    }

    public func start(_ parentVC: UIViewController) {
        iamportSdk = IamportSdk(parentVC)
    }


    public func payment(userCode: String, iamPortRequest: IamPortRequest, paymentResultCallback: @escaping (IamPortResponse?) -> Void) {
//        preventOverlapRun?.launch {
//            corePayment(userCode, iamPortRequest, approveCallback, paymentResultCallback)
//        }
        corePayment(userCode: userCode, iamPortRequest: iamPortRequest, paymentResultCallback: paymentResultCallback)
    }

    func corePayment(
            userCode: String,
            iamPortRequest: IamPortRequest,
            paymentResultCallback: ((IamPortResponse?) -> Void)?
    ) {
        impCallbackFunction = paymentResultCallback
        iamportSdk?.initStart(payment: Payment(userCode: userCode, iamPortRequest: iamPortRequest), paymentResultCallback: paymentResultCallback)
    }
}
