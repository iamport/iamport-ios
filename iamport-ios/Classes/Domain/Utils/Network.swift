//
// Created by BingBong on 2021/02/05.
//

import Foundation
import Alamofire

// TODO Alamofire -> Moya 로 변경하자
class Network {

    static let alamoFireManager: SessionManager = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = TimeInterval(CONST.NETWORK_TIMEOUT_SEC)
        configuration.timeoutIntervalForResource = TimeInterval(CONST.NETWORK_TIMEOUT_SEC)
        let alamoFireManager = Alamofire.SessionManager(configuration: configuration)
        return alamoFireManager
    }()

}
