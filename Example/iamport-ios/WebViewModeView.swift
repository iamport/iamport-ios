import Foundation
import SwiftUI
import UIKit
import WebKit
import iamport_ios


struct WebViewModeView: UIViewControllerRepresentable {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @EnvironmentObject var viewModel: ViewModel

    func makeUIViewController(context: Context) -> UIViewController {
        print("생성이야????")
        viewModel.updateMerchantUid()
        let view = IamportPaymentWebViewModeController()
        view.viewModel = viewModel
        view.presentationMode = presentationMode
        return view
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
    }

}

class IamportPaymentWebViewModeController: UIViewController, WKNavigationDelegate {
    var viewModel: ViewModel? = nil
    var presentationMode: Binding<PresentationMode>?

    private lazy var wkWebView: WKWebView = {
        var view = WKWebView()
        view.backgroundColor = UIColor.clear
        view.navigationDelegate = self
        return view
    }()

    private func setupWebView() {
        print("setupWebView")
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
        print("IamportPaymentWebViewMode viewDidLoad")

        view.backgroundColor = UIColor.white
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("IamportPaymentWebViewMode viewWillAppear")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("IamportPaymentWebViewMode viewDidAppear")
        setupWebView()
        requestPayment()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        print("IamportPaymentWebViewMode viewWillDisappear")
        removeWebView()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        print("IamportPaymentWebViewMode viewDidDisappear")
        Iamport.shared.close()
    }


    // 아임포트 SDK 결제 요청
    func requestPayment() {
        let userCode = "imp96304110" // iamport 에서 부여받은 가맹점 식별코드
        if let request = viewModel?.createPaymentData() {
            dump(request)

            //WebView 사용
            Iamport.shared.paymentWebView(webViewMode: wkWebView, userCode: userCode, iamPortRequest: request) { [weak self] iamPortResponse in
                self?.paymentCallback(iamPortResponse)
            }
        }
    }

    // 결제 완료 후 콜백 함수 (예시)
    func paymentCallback(_ response: IamPortResponse?) {
        print("------------------------------------------")
        print("결과 왔습니다~~")
        print("Iamport Payment response: \(response)")
        print("------------------------------------------")

        presentationMode?.wrappedValue.dismiss()
    }

}

struct IamportPaymentWebViewMode_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            WebViewModeView()
        }
    }
}

