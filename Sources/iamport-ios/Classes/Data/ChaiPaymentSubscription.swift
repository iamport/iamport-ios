//
// Created by BingBong on 2021/06/17.
//

import Foundation

class ChaiPaymentSubscription: BaseChaiPayment, Codable {
    var subscriptionId: String
    var status: String
    var displayStatus: String
    var idempotencyKey: String
    var checkoutAmount: Float
    var returnUrl: String
    var description: String
    var merchantUserId: String
    var createdAt: String // "2020-10-27T06:36:12.218Z"
    var updatedAt: String // "2020-10-27T06:36:12.218Z"
}
