//
// Created by BingBong on 2021/01/08.
//

import Foundation
import WebKit
import RxBus
import RxSwift

class NiceTransWebViewStrategy: WebViewStrategy {

    var bankTid: String?
    var niceTransUrl: String?

    override func doWork(_ payment: Payment) {
        super.doWork(payment)
        self.payment = payment
    }

    override func onUpdatedUrl(url: URL) {
        #if DEBUG
        print("아주 나이스~ \(url)")
        #endif
        if (isNiceTransScheme(url)) {
            let queryParams = url.queryParams()
            bankTid = (queryParams[NiceBankpay.USER_KEY] as? String)
            niceTransUrl = (queryParams[NiceBankpay.CALLBACKPARAM] as? String)

            if let bankPayData = makeBankPayData(url) {
                // 뱅크페이 앱 열기
//                RxBus.shared.post(event: EventBus.WebViewEvents.NiceTransRequestParam(niceTransRequestParam: bankPayData))
                RxBus.shared.post(event: EventBus.WebViewEvents.NiceTransRequestParam(niceTransRequestParam: url.absoluteString))
            }
            return
        }

        super.onUpdatedUrl(url: url)
    }

    /**
     뱅크페이 결제 결과 처리
     - Parameter url: 외부앱 뱅크페이 결제 종료시 받은 URL
     */
    public func processBankPayPayment(_ url: URL) {

        // bankpaycode값과 bankpayvalue값을 추출해 각각 bankpay_code와 bankpay_value값으로 전달
        let queryItems = URLComponents(string: url.absoluteString)?.queryItems
        let bankpayCode: String = (queryItems?.filter({ $0.name == "bankpaycode" }).first!.value)!
        let bankpayValue: String = (queryItems?.filter({ $0.name == "bankpayvalue" }).first!.value)!

        let resPair = (bankpayCode, bankpayValue)

        func makeNiceTransPaymentsQuery(res: (String, String)) -> String {
            if let niceUrl = niceTransUrl, let tid = bankTid {
                let result = "\(niceUrl)" +
                        "?\(NiceBankpay.CALLBACKPARAM2)=\(tid)" +
                        "&\(NiceBankpay.CODE)=\(res.0)" +
                        "&\(NiceBankpay.VALUE)=\(res.1)"
                #if DEBUG
                print("makeNiceTransPaymentsQuery \(result)")
                #endif
                return result
            }
            return ""
        }

        if let code = BankPayResultCode.from(resPair.0) {
            switch code {
            case .OK:
                print("BankPayResultCode :: OK")
                if let url = URL(string: makeNiceTransPaymentsQuery(res: resPair)) {
                    #if DEBUG
                    print("url :: \(url)")
                    #endif
                    RxBus.shared.post(event: EventBus.WebViewEvents.FinalBankPayProcess(url: url))
                }
            case .CANCEL, .TIME_OUT, .FAIL_SIGN, .FAIL_OTP, .FAIL_CERT_MODULE_INIT:
                #if DEBUG
                print(code.desc)
                #endif
                if let it = payment {
                    failureFinish(payment: it, msg: code.desc)
                }
            }
        } else {
            print("알 수 없는 에러 code : \(resPair.0)")
        }

    }

    private func makeBankPayData(_ uri: URL) -> String? {
        let prefix = ProvidePgScheme.BANKPAY.getNiceBankPayPrefix()
        let index = prefix.index(prefix.startIndex, offsetBy: prefix.count)
        let returnString = uri.absoluteString.substring(from: index).removingPercentEncoding
        #if DEBUG
        print("makeBankPayData :: \(returnString)")
        #endif
        return returnString
    }

    private func isNiceTransScheme(_ uri: URL) -> Bool {
        uri.scheme == ProvidePgScheme.BANKPAY.rawValue
    }

}
