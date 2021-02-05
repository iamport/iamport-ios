//
// Created by BingBong on 2021/01/29.
//

import Foundation

class PaymentMetadata: Codable {
    var merchantId: String?

    init(merchantId: String?) {
        self.merchantId = merchantId
    }
}

class ChaiPayment: Codable {

    var paymentId: String // "198ad2c1cc485629447c4527247c198bdb0cd82c"
    var type: String // "payment"
    var status: String // "waiting"
    var displayStatus: String // "waiting"
    var idempotencyKey: String // "CHAIINIpayTest20201027153612605769"
    var currency: String // "KRW"
    var checkoutAmount: Int // 1004
    var discountAmount: Int = 0 // 0
    var billingAmount: Int // 1004
    var pointAmount: Int = 0 // 0
    var cashAmount: Int = 0 // 0
    var chargingAmount: Int = 0 // 0
    var cashbackAmount: Int = 0 // 0
    var taxFreeAmount: Int = 0 // 0
    var bookShowAmount: Int = 0 // 0
    var serviceFeeAmount: Int = 0// 0
    var merchantDiscountAmount: Int = 0// 0
    var merchantCashbackAmount: Int = 0// 0
    var canceledAmount: Int = 0// 0
    var canceledBillingAmount: Int = 0// 0
    var canceledPointAmount: Int = 0// 0
    var canceledCashAmount: Int = 0// 0
    var canceledDiscountAmount: Int = 0// 0
    var canceledCashbackAmount: Int = 0// 0
    var returnUrl: String // "https://ksmobile.inicis.com/smart/chaipayAcsResult.ini"
    var description: String // "결제테스트"
    var cashbacks: Array<String?> // [] // TODO 이거 모르겠네
    var createdAt: String // "2020-10-27T06:36:12.218Z"
    var updatedAt: String // "2020-10-27T06:36:12.218Z"
    var metadata: PaymentMetadata

    init(paymentId: String, type: String, status: String, displayStatus: String, idempotencyKey: String, currency: String, checkoutAmount: Int, discountAmount: Int, billingAmount: Int, pointAmount: Int, cashAmount: Int, chargingAmount: Int, cashbackAmount: Int, taxFreeAmount: Int, bookShowAmount: Int, serviceFeeAmount: Int, merchantDiscountAmount: Int, merchantCashbackAmount: Int, canceledAmount: Int, canceledBillingAmount: Int, canceledPointAmount: Int, canceledCashAmount: Int, canceledDiscountAmount: Int, canceledCashbackAmount: Int, returnUrl: String, description: String, cashbacks: Array<String?>, createdAt: String, updatedAt: String, metadata: PaymentMetadata) {
        self.paymentId = paymentId
        self.type = type
        self.status = status
        self.displayStatus = displayStatus
        self.idempotencyKey = idempotencyKey
        self.currency = currency
        self.checkoutAmount = checkoutAmount
        self.discountAmount = discountAmount
        self.billingAmount = billingAmount
        self.pointAmount = pointAmount
        self.cashAmount = cashAmount
        self.chargingAmount = chargingAmount
        self.cashbackAmount = cashbackAmount
        self.taxFreeAmount = taxFreeAmount
        self.bookShowAmount = bookShowAmount
        self.serviceFeeAmount = serviceFeeAmount
        self.merchantDiscountAmount = merchantDiscountAmount
        self.merchantCashbackAmount = merchantCashbackAmount
        self.canceledAmount = canceledAmount
        self.canceledBillingAmount = canceledBillingAmount
        self.canceledPointAmount = canceledPointAmount
        self.canceledCashAmount = canceledCashAmount
        self.canceledDiscountAmount = canceledDiscountAmount
        self.canceledCashbackAmount = canceledCashbackAmount
        self.returnUrl = returnUrl
        self.description = description
        self.cashbacks = cashbacks
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.metadata = metadata
    }
}
