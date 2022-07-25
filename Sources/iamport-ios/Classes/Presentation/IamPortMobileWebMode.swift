//
// Created by BingBong on 2021/06/21.
//


import Foundation
import UIKit
import WebKit
import RxBusForPort
import RxSwift
import RxRelay

class IamPortMobileWebMode: IamPortWebViewMode {

    // for communicate WebView
    enum JsInterface: String, CaseIterable {
        case IAMPORT_MOBILE_WEB_MODE = "iamportmobilewebmode"

        static func convertJsInterface(s: String) -> JsInterface? {
            for value in self.allCases {
                if (s == value.rawValue) {
                    return value
                }
            }
            return nil
        }
    }


    override func clearWebView() {
        if let wv = webview {
            wv.configuration.userContentController.do { controller in
                for value in JsInterface.allCases {
                    controller.removeScriptMessageHandler(forName: value.rawValue)
                }
            }
            wv.stopLoading()
        }
//        super.clearWebView()
    }


    override func setupWebView() {

        webview?.do { wv in
            wv.configuration.userContentController.do { controller in
                for value in JsInterface.allCases {
                    controller.add(self, name: value.rawValue)
                }
            }
            wv.configuration.preferences.javaScriptCanOpenWindowsAutomatically = true

            wv.backgroundColor = UIColor.white

            dlog("wv.uiDelegate : \(wv.uiDelegate)")
            if ((wv.uiDelegate is IamPortWKWebViewDelegate) == false) {
                dlog("새로 할당 uiDelegate")
                wv.uiDelegate = viewModel.iamPortWKWebViewDelegate
            } else {
                dlog("기존꺼 사용 uiDelegate")
            }

            dlog("wv.navigationDelegate : \(wv.navigationDelegate)")
            if ((wv.navigationDelegate is IamPortWKWebViewDelegate) == false) {
                dlog("새로 할당 navigationDelegate")
                wv.navigationDelegate = viewModel.iamPortWKWebViewDelegate
            } else {
                dlog("기존꺼 사용 navigationDelegate")
            }

        }
    }

    override func subscribePayment() {
        //
    }


    // 결제 데이터가 있을때 처리 할 이벤트들
    override func subscribeCertification(_ payment: Payment) {
        dlog("subscribe mobile mode certification")

        let webViewEvents = EventBus.WebViewEvents.self

        RxBus.shared.asObservable(event: webViewEvents.ThirdPartyUri.self).subscribe { [weak self] event in
            guard let el = event.element else {
                print("Error not found ThirdPartyUri")
                return
            }
            self?.openThirdPartyApp(el.thirdPartyUri)
        }.disposed(by: disposeBag)

        requestCertification(payment)
    }


    // 실제 결제 요청 동작
    override func subscribePayment(_ payment: Payment) {
        dlog("subscribe mobile mode payment")

        let webViewEvents = EventBus.WebViewEvents.self

        RxBus.shared.asObservable(event: webViewEvents.ThirdPartyUri.self).subscribe { [weak self] event in
            guard let el = event.element else {
                print("Error not found ThirdPartyUri")
                return
            }
            self?.openThirdPartyApp(el.thirdPartyUri)
        }.disposed(by: disposeBag)

        subscribeForBankPay()
        requestPayment(payment)
    }

    override func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {

        dlog("body \(message.body)")

        if let jsMethod = JsInterface.convertJsInterface(s: message.name) {
            switch jsMethod {
            case .IAMPORT_MOBILE_WEB_MODE:

                guard let dataJson = try? JSONSerialization.data(withJSONObject: message.body, options: .prettyPrinted) else {
                    print("JSONSerialization 실패")
                    return
                }

                guard let payment = try? JSONDecoder().decode(Payment.self, from: dataJson) else {
                    print("JSONDecoder 실패")
                    return
                }

                dlog("받았어!! \(payment)")
                ddump(payment)

                self.payment = payment
                subscribe(payment) // rxbus 구독 및 strategy doWork
            }
        }
    }

}
