//
// Created by BingBong on 2021/01/08.
//

import Foundation

struct PrepareData: Codable {
    let impUid: String
    let paymentId: String? = nil
    let idempotencyKey: String? = nil
    let returnUrl: String? = nil
    let publicAPIKey: String? = nil
    let mode: String? = nil

    init(impUid: String) {
        self.impUid = impUid
    }
}
