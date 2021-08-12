import Foundation
import SwiftUI
import UIKit
import WebKit
import iamport_ios


struct PaymentWebViewModeView: UIViewControllerRepresentable {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @EnvironmentObject var viewModel: ViewModel

    func makeUIViewController(context: Context) -> UIViewController {
        let view = PaymentWebViewModeViewController()
        view.viewModel = viewModel
        view.presentationMode = presentationMode
        return view
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
    }

}

class PaymentWebViewModeViewController: UIViewController, WKNavigationDelegate {
    var viewModel: ViewModel? = nil
    var presentationMode: Binding<PresentationMode>?

    private lazy var wkWebView: WKWebView = {
        var view = WKWebView()
        view.backgroundColor = UIColor.clear
        view.navigationDelegate = self
        return view
    }()

    private func attachWebView() {
        print("attachWebView")
        view.addSubview(wkWebView)
        wkWebView.frame = view.frame

        wkWebView.translatesAutoresizingMaskIntoConstraints = false
        wkWebView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        wkWebView.heightAnchor.constraint(equalTo: view.heightAnchor).isActive = true
        wkWebView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        wkWebView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
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
        print("PaymentWebViewModeView viewDidLoad")

        view.backgroundColor = UIColor.white
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("PaymentWebViewModeView viewDidAppear")
        attachWebView()
        requestPayment()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        print("PaymentWebViewModeView viewWillDisappear")
        removeWebView()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        print("PaymentWebViewModeView viewDidDisappear")
        Iamport.shared.close()
        presentationMode?.wrappedValue.dismiss()
    }

    // 아임포트 SDK 결제 요청
    func requestPayment() {
        guard let viewModel = viewModel else {
            print("viewModel 이 존재하지 않습니다.")
            return
        }

        let userCode = viewModel.order.userCode // iamport 에서 부여받은 가맹점 식별코드
        if let request = viewModel.createPaymentData() {
            dump(request)

            //WebView 사용
            Iamport.shared.paymentWebView(webViewMode: wkWebView, userCode: userCode.value, iamPortRequest: request) { [weak self] iamPortResponse in
                viewModel.iamportCallback(iamPortResponse)
                self?.presentationMode?.wrappedValue.dismiss()
            }
        }
    }
}

struct PaymentWebViewModeView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            PaymentWebViewModeView()
        }
    }
}

