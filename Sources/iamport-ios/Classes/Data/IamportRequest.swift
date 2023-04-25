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
        case .certification:
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
        case .certification: return nil
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

extension IamportRequest {
    private enum legacyCodingKeys: CodingKey {
        case userCode, tierCode
        /// 리팩토링 이전 SDK과 웹뷰 간의 통신에 사용한 키, 하위호환성 보장을 위해 필요함.
        case iamPortRequest, iamPortCertification
        /// 리팩토링 이후 SDK과 웹뷰 간의 통신에 사용할 키
        case payment, certification
    }

    struct RequestDecodingError: Error {
        let message: String
        init(_ message: String) {
            self.message = message
        }
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: legacyCodingKeys.self)
        userCode = try values.decode(String.self, forKey: .userCode)
        tierCode = try? values.decode(String.self, forKey: .tierCode)
        let payment = (try? values.decode(IamportPayment.self, forKey: .iamPortRequest)) ?? (try? values.decode(IamportPayment.self, forKey: .payment))
        let certification = (try? values.decode(IamportCertification.self, forKey: .iamPortCertification)) ?? (try? values.decode(IamportCertification.self, forKey: .certification))
        var data: IamportPayload?
        if let payment = payment {
            data = IamportPayload.payment(payment)
        }
        if let certification = certification {
            data = IamportPayload.certification(certification)
        }
        guard let data = data else { throw RequestDecodingError("Unexpected Error") }
        payload = data
    }
}
