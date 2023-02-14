import Foundation
import SwiftUI
import UIKit
import WebKit
import iamport_ios
import RxSwift
import RxCocoa


struct PaymentMobileViewModeView: UIViewControllerRepresentable {
    @EnvironmentObject var viewModel: ViewModel

    func makeUIViewController(context: Context) -> UIViewController {
        let view = PaymentMobileViewModeViewController()
        return view
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
    }

}

class PaymentMobileViewModeViewController: UIViewController, WKUIDelegate, WKNavigationDelegate {
    var disposeBag = DisposeBag()
    let webViewDelegate = MyWKWebViewDelegate()

    private lazy var wkWebView: WKWebView = {
        var view = WKWebView()
        view.backgroundColor = UIColor.clear
        return view
    }()

    private func attachWebView() {
        print("attachWebView")
        view.addSubview(wkWebView)
        wkWebView.frame = view.frame

        let safeAreaInsets = view.safeAreaInsets
        wkWebView.translatesAutoresizingMaskIntoConstraints = false
        wkWebView.topAnchor.constraint(equalTo: view.topAnchor, constant: safeAreaInsets.top).isActive = true
        wkWebView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: safeAreaInsets.bottom).isActive = true
        wkWebView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0).isActive = true
        wkWebView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0).isActive = true
    }

    private func removeWebView() {
        view.willRemoveSubview(wkWebView)
        wkWebView.stopLoading()
        wkWebView.removeFromSuperview()
        wkWebView.uiDelegate = nil
        wkWebView.navigationDelegate = nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        print("PaymentMobileViewModeViewController viewDidLoad")
        view.backgroundColor = UIColor.white
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("PaymentMobileViewModeViewController viewDidAppear")
        attachWebView()
        requestPayment()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        print("PaymentMobileViewModeViewController viewWillDisappear")
        removeWebView()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        print("PaymentMobileViewModeView viewDidDisappear")
        disposeBag = DisposeBag()
        Iamport.shared.close()
    }


    private func openWebView() {
        print("오픈! 샘플 웹뷰")

        /*
          setup I'mport WKUIDelegate & WKNavigationDelegate
          url 을 통해 업데이트 하는 로직이 있을 경우에 [IamportWKWebViewDelegate] 사용
         */
//        wkWebView.uiDelegate = webViewDelegate as WKUIDelegate
//        wkWebView.navigationDelegate = webViewDelegate as WKNavigationDelegate

        let bundle = Bundle(for: type(of: self))
        guard let url = bundle.url(forResource: "mobileweb", withExtension: "html") else {
            print("html file url 비정상")
            return
        }

        let urlRequest = URLRequest(url: url)
        self.wkWebView.load(urlRequest)
    }


    // 아임포트 SDK 결제 요청
    func requestPayment() {
        openWebView()

        // IamportWKWebViewDelegate 또는 아래의 Iamport.shared.updateWebViewUrl 을 통해 변경되는 url 을 체크 가능합니다.
        Iamport.shared.updateWebViewUrl.subscribe { url in
            print("updateWebViewUrl received url : \(String(describing: url.element))")
        }.disposed(by: disposeBag)

        Iamport.shared.pluginMobileWebSupporter(mobileWebMode: wkWebView)
    }

}


/**
 url 을 통해 업데이트 하는 로직이 있을 경우에 [IamportWKWebViewDelegate] 사용하시거나,
 또는 Iamport.shared.updateWebViewUrl 의 subscribe 을 통해 변경되는 url 을 체크 가능합니다.
 */
class MyWKWebViewDelegate: IamportWKWebViewDelegate {
    override func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let url = navigationAction.request.url {
            // TODO : write your logic
            print("MyWKNavigationDelegate received url : \(url)")
        }

        super.webView(webView, decidePolicyFor: navigationAction, decisionHandler: decisionHandler)
    }
}

struct PaymentMobileViewModeView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            PaymentMobileViewModeView()
        }
    }
}

