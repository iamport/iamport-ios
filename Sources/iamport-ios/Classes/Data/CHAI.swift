//
// Created by BingBong on 2021/01/25.
//

import Foundation

struct CHAI {
    static let SCHEME_HOST: String = "\(AppScheme.chai.scheme)://payment"
    static let PUBLIC_API_KEY = "publicAPIKey"
    static let PAYMENT_ID = "paymentId"
    static let SUBSCRIPTION_ID = "subscriptionId"
    static let IDEMPOTENCY_KEY = "idempotencyKey"
    static let STATUS = "status"
    static let NATIVE = "native"
    static let CHANNEL = "mobile"
}

public enum CHAI_MODE: String, CaseIterable, Codable {
    case prod
    case staging
    case dev

    var url: String {
        switch self {
        case .prod:
            return Constant.CHAI_SERVICE_URL
        case .staging:
            return Constant.CHAI_SERVICE_STAGING_URL
        case .dev:
            return Constant.CHAI_SERVICE_DEV_URL
        }
    }

    static func getChaiUrl(mode: String) -> String {
        for value in allCases {
            if mode == value.rawValue {
                debug_log("Found CHAI mode => [\(mode)]")
                return value.url
            }
        }

        print("Not found CHAI mode => [\(mode)]")
        return prod.url // default
    }
}
