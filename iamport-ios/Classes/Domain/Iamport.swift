//
// Created by BingBong on 2021/01/05.
//

import Foundation
import WebKit

open class Iamport {

    public static let sharedInstance = Iamport()

    var sdk: IamportSdk? = nil

    fileprivate init() {
        sdk = IamportSdk()
    }

    public func getWebView() -> WKWebView? {
        sdk?.getWebView() ?? nil
    }

}