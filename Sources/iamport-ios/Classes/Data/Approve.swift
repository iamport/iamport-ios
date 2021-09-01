//
// Created by BingBong on 2021/02/01.
//

import Foundation

class Approve: Codable {
    var code: Int
    var msg: String
    var data: ApproveData
}

class ApproveData: Codable {
    var impUid: String
    var merchantUid: String
    var success: Bool
    var reason: String?
}