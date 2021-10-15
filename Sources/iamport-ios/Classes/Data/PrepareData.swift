//
// Created by BingBong on 2021/01/08.
//

import Foundation

struct PrepareData: Codable {
    let impUid: String
    var paymentId: String? = nil
    var subscriptionId: String? = nil
    let idempotencyKey: String
    let returnUrl: String
    let publicAPIKey: String
    var mode: String? = nil
    var isSbcr: Bool? // FIXME : 서버 배포 후 non nullable 로 수정해야댐

    init(impUid: String, paymentId: String? = nil,
         subscriptionId: String? = nil, idempotencyKey: String,
         returnUrl: String, publicAPIKey: String,
         isSbcr: Bool?) {
        self.impUid = impUid
        self.paymentId = paymentId
        self.subscriptionId = subscriptionId
        self.idempotencyKey = idempotencyKey
        self.returnUrl = returnUrl
        self.publicAPIKey = publicAPIKey
        self.isSbcr = isSbcr
    }
}

struct PrepareDataError: Codable {
    let impUid: String
    var errorCode: String? = nil
    var errorMsg: String? = nil

    init(impUid: String, errorCode: String?, errorMsg: String?) {
        self.impUid = impUid
        self.errorCode = errorCode
        self.errorMsg = errorMsg
    }
}