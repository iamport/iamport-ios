//
// Created by BingBong on 2021/02/01.
//

import Foundation
import Then

public class IamPortApprove: Then {
    var userCode: String
    var merchantUid: String
    var customerUid: String?
    var paymentId: String?
    var subscriptionId: String?
    var impUid: String
    var idempotencyKey: String
    var publicAPIKey: String
    var status: String
    var msg: String? = nil

    init(userCode: String, merchantUid: String, paymentId: String?,
         impUid: String, idempotencyKey: String, publicAPIKey: String,
         status: String,
         subscriptionId: String?, customerUid: String) {
        self.userCode = userCode
        self.merchantUid = merchantUid
        self.customerUid = customerUid
        self.paymentId = paymentId
        self.subscriptionId = subscriptionId
        self.impUid = impUid
        self.idempotencyKey = idempotencyKey
        self.publicAPIKey = publicAPIKey
        self.status = status
    }

    static func make(payment: Payment, prepareData: PrepareData, status: String) -> IamPortApprove {
        IamPortApprove(userCode: payment.userCode,
                merchantUid: payment.getMerchantUid(),
                paymentId: prepareData.paymentId,
                impUid: prepareData.impUid,
                idempotencyKey: prepareData.idempotencyKey,
                publicAPIKey: prepareData.publicAPIKey,
                status: status,
                subscriptionId: prepareData.subscriptionId,
                customerUid: payment.getCustomerUid())
    }
}

