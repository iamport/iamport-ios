//
// Created by BingBong on 2021/02/01.
//

import Foundation
import Then

public class IamPortApprove: Then {
    var userCode: String
    var merchantUid: String
    var paymentId: String?
    var impUid: String?
    var idempotencyKey: String?
    var publicAPIKey: String?
    var msg: String? = nil

    init(userCode: String, merchantUid: String, paymentId: String?, impUid: String?, idempotencyKey: String?, publicAPIKey: String?) {
        self.userCode = userCode
        self.merchantUid = merchantUid
        self.paymentId = paymentId
        self.impUid = impUid
        self.idempotencyKey = idempotencyKey
        self.publicAPIKey = publicAPIKey
    }

    static func make(payment: Payment, prepareData: PrepareData) -> IamPortApprove {
        IamPortApprove(userCode: payment.userCode,
                merchantUid: payment.getMerchantUid(),
                paymentId: prepareData.paymentId,
                impUid: prepareData.impUid,
                idempotencyKey: prepareData.idempotencyKey,
                publicAPIKey: prepareData.publicAPIKey)
    }
}

