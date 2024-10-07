//
// Created by BingBong on 2021/07/14.
//

import Foundation
import RxRelay
import RxSwift
import Then
import UIKit
import WebKit

open class IamportWKWebViewDelegate: NSObject, WKNavigationDelegate {
    var popupWebView: WKWebView? /// window.open()으로 열리는 새창

    @available(iOS 8.0, *)
    open func webView(_: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        // url 변경 시점
        if let url = navigationAction.request.url {
            RxBus.shared.post(event: EventBus.WebViewEvents.UpdateUrl(url: url))
            Iamport.shared.updateWebViewUrl.accept(url)

            let policy = Utils.getActionPolicy(url)
            decisionHandler(policy ? .cancel : .allow)
        } else {
            decisionHandler(.cancel)
        }
    }
}

extension IamportWKWebViewDelegate: WKUIDelegate {
    public func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for _: WKNavigationAction, windowFeatures _: WKWindowFeatures) -> WKWebView? {
        let frame = UIScreen.main.bounds
        popupWebView = WKWebView(frame: frame, configuration: configuration)
        if let popup = popupWebView {
            popup.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            popup.navigationDelegate = self
            popup.uiDelegate = self
            webView.superview?.addSubview(popup)
            return popup
        }

        return nil
    }

    public func webViewDidClose(_ webView: WKWebView) {
        if webView == popupWebView {
            popupWebView?.removeFromSuperview()
            popupWebView = nil
        }
    }

    private func presentAlert(webView: WKWebView, alertController: UIAlertController) {
        DispatchQueue.main.async {
            guard let controller = webView.superview?.viewController else {
                print("viewController 를 찾을 수 없습니다.")
                return
            }
            controller.present(alertController, animated: true, completion: nil)
        }
    }

    public func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame _: WKFrameInfo,
                        completionHandler: @escaping () -> Void)
    {
        debug_log("팝업 호출 1")
        let completionHandlerWrapper = CompletionHandlerWrapper(completionHandler: completionHandler, defaultValue: ())

        let alertController = UIAlertController(title: "", message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "확인", style: .default, handler: { _ in
            completionHandlerWrapper.respondHandler(())
        }))
        presentAlert(webView: webView, alertController: alertController)
    }

    public func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame _: WKFrameInfo,
                        completionHandler: @escaping (Bool) -> Void)
    {
        debug_log("팝업 호출 2")
        let completionHandlerWrapper = CompletionHandlerWrapper(completionHandler: completionHandler, defaultValue: false)

        let alertController = UIAlertController(title: "", message: message, preferredStyle: .alert)

        alertController.addAction(UIAlertAction(title: "확인", style: .default, handler: { _ in
            completionHandlerWrapper.respondHandler(true)
        }))
        alertController.addAction(UIAlertAction(title: "취소", style: .cancel, handler: { _ in
            completionHandlerWrapper.respondHandler(false)
        }))

        presentAlert(webView: webView, alertController: alertController)
    }

    public func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame _: WKFrameInfo,
                        completionHandler: @escaping (String?) -> Void)
    {
        debug_log("팝업 호출 3")
        let completionHandlerWrapper = CompletionHandlerWrapper(completionHandler: completionHandler, defaultValue: "")
        let alertController = UIAlertController(title: "", message: prompt, preferredStyle: .alert)
        alertController.addTextField { textField in
            textField.text = defaultText
        }

        alertController.addAction(UIAlertAction(title: "확인", style: .default, handler: { _ in
            if let text = alertController.textFields?.first?.text {
                completionHandlerWrapper.respondHandler(text)
            } else {
                completionHandlerWrapper.respondHandler(defaultText)
            }
        }))

        alertController.addAction(UIAlertAction(title: "취소", style: .default, handler: { _ in
            completionHandlerWrapper.respondHandler(nil)
        }))

        presentAlert(webView: webView, alertController: alertController)
    }
}
