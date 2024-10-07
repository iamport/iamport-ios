//
// Created by BingBong on 2021/01/05.
//

import Foundation
import RxBusForPort
import RxSwift
import Then
import WebKit

public class IamportSdk: Then {
    let viewModel = MainViewModel()

    private var viewController: UIViewController?
    private var navController: UINavigationController?
    private var webview: WKWebView?

    var chaiApproveCallBack: ((IamportApprove) -> Void)? // 차이 결제 확인 콜백
    var resultCallBack: ((IamportResponse?) -> Void)? // 결제 결과 콜백

    var iamportWebViewMode: IamportWebViewMode?
    var iamportMobileWebMode: IamportMobileWebMode?
    var disposeBag = DisposeBag()

    var animate = true
    var useNavigationButton = false

    public init(navController: UINavigationController) {
        self.navController = navController
    }

    /**
     for WebView Mode (WKWebView 를 넘기지만 결제요청은 네이티브에서)
      - Parameter webViewMode
      */
    public init(webViewMode: WKWebView) {
        webview = webViewMode
        iamportWebViewMode = IamportWebViewMode(eventBus: viewModel.eventBus)
    }

    /**
     for MobileWeb Mode (WKWebView 를 넘기고, 결제요청 또한 JS 에서 사용)
     - Parameter mobileWebMode
     */
    public init(mobileWebMode: WKWebView) {
        webview = mobileWebMode
        iamportMobileWebMode = IamportMobileWebMode(eventBus: viewModel.eventBus).then { mode in
            mode.start(webview: mobileWebMode)
        }
    }

    public init(viewController: UIViewController) {
        self.viewController = viewController
    }

    // 뷰모델 데이터 클리어
    func clearData() {
        print("IamportSdk clearData!")

        iamportWebViewMode?.close()
        iamportMobileWebMode?.close()

        viewModel.clear()
        viewModel.eventBus.clearRelay.accept(())

        disposeBag = DisposeBag()
    }

    private func finish(_ iamportResponse: IamportResponse?) {
        print("IamportSdk :: SDK Finished")
        clearData()
        resultCallBack?(iamportResponse)
    }

    internal func initStart(request: IamportRequest, approveCallback: ((IamportApprove) -> Void)?, paymentResultCallback: @escaping (IamportResponse?) -> Void) {
        print("IamportSdk :: initStart(payment)")

        chaiApproveCallBack = approveCallback
        resultCallBack = paymentResultCallback

        subscribe(request) // 관찰할 옵저버블
    }

    internal func initStart(request: IamportRequest, certificationResultCallback: @escaping (IamportResponse?) -> Void) {
        print("IamportSdk :: initStart(certification)")

        resultCallBack = certificationResultCallback

        subscribeCertification(request) // 관찰할 옵저버블
    }

    func postReceivedURL(_ url: URL) {
        debug_log("외부앱 종료 후 전달 받음 => \(url)")
        RxBus.shared.post(event: EventBus.WebViewEvents.ReceivedAppDelegateURL(url: url))
    }

    private func subscribe(_ request: IamportRequest) {
        // 결제결과 옵저빙
        viewModel.eventBus.impResponseBus.subscribe { [weak self] iamportResponse in
            self?.finish(iamportResponse)
        }.disposed(by: disposeBag)

        // TODO: subscribe 결제결과

        // subscribe 웹뷰열기
        viewModel.eventBus.paymentBus.subscribe { [weak self] event in
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

            self?.openApp(request, appAddress: el.appAddress)

        }.disposed(by: disposeBag)

        // 차이 결제 상태 approve 처리
        RxBus.shared.asObservable(event: EventBus.MainEvents.AskApproveFromChai.self).subscribe { [weak self] event in
            guard let el = event.element else {
                print("Error not found ChaiApprove")
                return
            }

            self?.askApproveFromChai(approve: el.approve)

        }.disposed(by: disposeBag)

        // 결제요청
        requestPayment(request)
    }

    private func subscribeCertification(_ request: IamportRequest) {
        // 본인인증 옵저빙
        viewModel.eventBus.impResponseBus.subscribe { [weak self] iamportResponse in
            self?.finish(iamportResponse)
        }.disposed(by: disposeBag)

        // subscribe 웹뷰열기
        viewModel.eventBus.paymentBus.subscribe { [weak self] event in
            guard let el = event.element, let pay = el else {
                print("Error paymentBus is nil")
                return
            }

            self?.openWebViewController(pay)
        }.disposed(by: disposeBag)

        // 본인인증 요청
        requestCertification(request)
    }

    private func openApp(_: IamportRequest, appAddress: URL) {
        let result = Utils.openAppWithCanOpen(appAddress) // 앱 열기
        // TODO: openApp result = false 일 떄, 이미 chai strategy 가 동작할 시나리오
        // 취소? 타임아웃 연장? 그대로 진행? ... 등
        // 어차피 앱 재설치시, 다시 차이 결제 페이지로 진입할 방법이 없음
        if !result {
            Utils.justOpenApp(appAddress) { [weak self] in

                self?.viewModel.stopChaiStrategy()

                if let scheme = appAddress.scheme,
                   let urlString = AppScheme.getAppStoreUrl(scheme: scheme),
                   let url = URL(string: urlString)
                {
                    Utils.justOpenApp(url) // 앱스토어 이동
                }
            }
        }
    }

    // approveCallBack 이 있으면, 머천트의 컨펌을 받음
    private func askApproveFromChai(approve: IamportApprove) {
        if let cb = chaiApproveCallBack {
            cb(approve)
        } else {
            requestApprovePayments(approve: approve) // 없으면 바로 차이 최종 결제 요청
        }
    }

    // 차이 최종 결제 요청
    public func requestApprovePayments(approve: IamportApprove) {
        viewModel.requestApprovePayments(approve: approve)
    }

    private func requestPayment(_ request: IamportRequest) {
        IamportRequest.validator(request) { valid, desc in
            print("Payment validator valid :: \(valid), valid :: \(desc)")
            if !valid {
                self.finish(IamportResponse.makeFail(request: request, msg: desc))
                return
            }
        }

        if !Utils.isInternetAvailable() {
            finish(IamportResponse.makeFail(request: request, msg: "네트워크 연결 안됨"))
            return
        }

        // webview mode 라면 네이티브 연동 사용하지 않음
        // 동작의 문제는 없으나 UI 에서 표현하기 애매함
        if webview != nil {
            viewModel.judgePayment(request, ignoreNative: true)
            return
        }

        viewModel.judgePayment(request)
    }

    private func requestCertification(_ request: IamportRequest) {
        if !Utils.isInternetAvailable() {
            finish(IamportResponse.makeFail(request: request, msg: "네트워크 연결 안됨"))
            return
        }

        viewModel.judgePayment(request)
    }

    // 웹뷰 컨트롤러 열기 및 데이터 전달
    private func openWebViewController(_ request: IamportRequest) {
        DispatchQueue.main.async { [weak self] in

            self!.viewModel.eventBus.webViewPaymentRelay.accept(request) // 여기서 먼저 결제 데이터를 넘김

            if let wv = self?.webview {
                self?.iamportWebViewMode?.start(webview: wv)
                return
            }

            let wvc = WebViewController(eventBus: self!.viewModel.eventBus)

            self?.navController?.pushViewController(wvc, animated: self?.animate ?? true)

            wvc.modalPresentationStyle = .fullScreen
            wvc.useNavigationButton = self?.useNavigationButton ?? false
            self?.viewController?.present(wvc, animated: self?.animate ?? true)

            debug_log("check viewController :: \(String(describing: self?.viewController))")
            debug_log("check navigationController :: \(String(describing: self?.navController))")
        }
    }
}
