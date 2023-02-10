//
// Created by BingBong on 2021/01/07.
//

import Foundation
import Then

enum IamportPayload: Codable {
    case payment(IamportPayment)
    case certification(IamportCertification)
}

struct IamportRequest: Codable, Then {
    let userCode: String
    let tierCode: String?
    var payload: IamportPayload

    init(userCode: String, tierCode: String? = nil, payment: IamportPayment) {
        self.userCode = userCode
        self.tierCode = tierCode
        payload = .payment(payment)
    }

    init(userCode: String, tierCode: String? = nil, certification: IamportCertification) {
        self.userCode = userCode
        self.tierCode = tierCode
        payload = .certification(certification)
    }

    var isCertification: Bool {
        switch payload {
        case .payment:
            return true
        default:
            return false
        }
    }

    func getMerchantUid() -> String {
        switch payload {
        case let .payment(payment): return payment.merchant_uid
        case let .certification(certification): return certification.merchant_uid
        }
    }

    func getCustomerUid() -> String? {
        switch payload {
        case let .payment(payment): return payment.customer_uid
        // TODO: throw error instead
        case let .certification(certification): return nil
        }
    }

    static func validator(_ request: IamportRequest, _ validateResult: @escaping ((Bool, String)) -> Void) {
        var validResult = (true, Constant.PASS_PAYMENT_VALIDATOR)
        guard case let .payment(payment) = request.payload else { return }

        payment.do { it in

            let payMethod = it.pay_method

            if payMethod == PayMethod.vbank.rawValue {
                if it.vbank_due.nilOrEmpty {
                    validResult = (false, Constant.ERR_PAYMENT_VALIDATOR_VBANK)
                }
            }

            if payMethod == PayMethod.phone.rawValue {
                if it.digital == nil {
                    validResult = (false, Constant.ERR_PAYMENT_VALIDATOR_PHONE)
                }
            }

            if PG.convertPG(pgString: it.pg) == PG.danal_tpay && payMethod == PayMethod.vbank.rawValue {
                if it.biz_num.nilOrEmpty {
                    validResult = (false, Constant.ERR_PAYMENT_VALIDATOR_DANAL_VBANK)
                }
            }

            if PG.convertPG(pgString: it.pg) == PG.eximbay {
                if it.popup == nil || it.popup == true {
                    validResult = (false, Constant.ERR_PAYMENT_VALIDATOR_EXIMBAY)
                }
            }
        }

        validateResult(validResult)
    }
}
