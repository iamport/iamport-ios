//
// Created by BingBong on 2021/02/05.
//

import Foundation
import Alamofire

// TODO Alamofire -> Moya 로 변경하자
class Network {

    static func getURLSessionConfiguration(useShortTimeout: Bool = false) -> URLSessionConfiguration {
        var timeout = CONST.NETWORK_TIMEOUT_SEC
        if (useShortTimeout) {
            timeout = CONST.NETWORK_SHORT_TIMEOUT_SEC
        }
        let sessionConfiguration = URLSessionConfiguration.default.then { config in
            config.timeoutIntervalForRequest = TimeInterval(timeout)
            config.timeoutIntervalForResource = TimeInterval(timeout)
        }

        return sessionConfiguration
    }

    static let alamoFireManager: Alamofire.Session = {
        Alamofire.Session(configuration: getURLSessionConfiguration())
    }()

    static let alamoFireManagerShortTimeOut: Alamofire.Session = {
        Alamofire.Session(configuration: getURLSessionConfiguration(useShortTimeout: true))
    }()

}
