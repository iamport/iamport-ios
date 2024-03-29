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

class BaseChaiPayment {}

class ChaiPayment: BaseChaiPayment, Codable {
    var paymentId: String // "198ad2c1cc485629447c4527247c198bdb0cd82c"
    var type: String // "payment"
    var status: String // "waiting"
    var displayStatus: String // "waiting"
    var idempotencyKey: String // "CHAIINIpayTest20201027153612605769"
    var currency: String // "KRW"
    var checkoutAmount: Float // 1004
    var discountAmount: Float = 0 // 0
    var billingAmount: Float // 1004
    var pointAmount: Float = 0 // 0
    var cashAmount: Float = 0 // 0
    var chargingAmount: Float = 0 // 0
    var cashbackAmount: Float = 0 // 0
    var taxFreeAmount: Float = 0 // 0
    var bookShowAmount: Float = 0 // 0
    var serviceFeeAmount: Float = 0 // 0
    var merchantDiscountAmount: Float = 0 // 0
    var merchantCashbackAmount: Float = 0 // 0
    var canceledAmount: Float = 0 // 0
    var canceledBillingAmount: Float = 0 // 0
    var canceledPointAmount: Float = 0 // 0
    var canceledCashAmount: Float = 0 // 0
    var canceledDiscountAmount: Float = 0 // 0
    var canceledCashbackAmount: Float = 0 // 0
    var returnUrl: String // "https://ksmobile.inicis.com/smart/chaipayAcsResult.ini"
    var description: String // "결제테스트"
    var createdAt: String // "2020-10-27T06:36:12.218Z"
    var updatedAt: String // "2020-10-27T06:36:12.218Z"
    var metadata: PaymentMetadata

    init(paymentId: String, type: String, status: String, displayStatus: String,
         idempotencyKey: String, currency: String, checkoutAmount: Float,
         discountAmount: Float, billingAmount: Float, pointAmount: Float,
         cashAmount: Float, chargingAmount: Float, cashbackAmount: Float,
         taxFreeAmount: Float, bookShowAmount: Float, serviceFeeAmount: Float,
         merchantDiscountAmount: Float, merchantCashbackAmount: Float,
         canceledAmount: Float, canceledBillingAmount: Float, canceledPointAmount: Float,
         canceledCashAmount: Float, canceledDiscountAmount: Float,
         canceledCashbackAmount: Float, returnUrl: String, description: String,
         createdAt: String,
         updatedAt: String, metadata: PaymentMetadata)
    {
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
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.metadata = metadata
    }
}
