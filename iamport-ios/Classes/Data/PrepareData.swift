//
// Created by BingBong on 2021/01/08.
//

import Foundation

struct PrepareData: Codable {
    let impUid: String
    var paymentId: String? = nil
    var idempotencyKey: String? = nil
    var returnUrl: String? = nil
    var publicAPIKey: String? = nil
    var mode: String? = nil

    init(impUid: String, paymentId: String?) {
        self.impUid = impUid
        self.paymentId = paymentId
    }
}
