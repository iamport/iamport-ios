import Foundation
import SwiftUI
import UIKit
import WebKit
import iamport_ios


struct PaymentMobileViewModeView: UIViewControllerRepresentable {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @EnvironmentObject var viewModel: ViewModel

    func makeUIViewController(context: Context) -> UIViewController {
        viewModel.updateMerchantUid()
        let view = PaymentMobileViewModeViewController()
        view.presentationMode = presentationMode
        return view
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
    }

}

class PaymentMobileViewModeViewController: UIViewController, WKNavigationDelegate {
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
        Iamport.shared.close()
    }

    private func openWebView() {
        print("오픈! 샘플 웹뷰")

        let bundle = Bundle(for: type(of: self))

        guard let url = bundle.url(forResource: "mobileweb", withExtension: "html") else {
            print("html file url 비정상")
            return
        }

        let urlRequest = URLRequest(url: url)
        DispatchQueue.main.async { [weak self] in
            self?.wkWebView.load(urlRequest)
        }
    }

    // 아임포트 SDK 결제 요청
    func requestPayment() {
        openWebView()
        Iamport.shared.pluginMobileWebSupporter(mobileWebMode: wkWebView)
    }

}

struct PaymentMobileViewModeView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            PaymentMobileViewModeView()
        }
    }
}

