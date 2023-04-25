//
// Created by BingBong on 2021/02/05.
//

import Alamofire
import Foundation

// TODO: Alamofire -> Moya 로 변경하자
class Network {
    static func getURLSessionConfiguration(useShortTimeout: Bool = false) -> URLSessionConfiguration {
        var timeout = Constant.NETWORK_TIMEOUT_SEC
        if useShortTimeout {
            timeout = Constant.NETWORK_SHORT_TIMEOUT_SEC
        }
        let sessionConfiguration = URLSessionConfiguration.default.then { config in
            config.timeoutIntervalForRequest = TimeInterval(timeout)
            config.timeoutIntervalForResource = TimeInterval(timeout)
        }

        return sessionConfiguration
    }

    static let alamoFireManager: Alamofire.Session = .init(configuration: getURLSessionConfiguration())

    static let alamoFireManagerShortTimeOut: Alamofire.Session = .init(configuration: getURLSessionConfiguration(useShortTimeout: true))
}
