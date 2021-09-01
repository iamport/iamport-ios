//
// Created by BingBong on 2021/01/07.
//

import Foundation
import Then

struct Payment: Codable, Then {
    let userCode: String
    var tierCode: String? = nil
    var iamPortRequest: IamPortRequest?
    var iamPortCertification: IamPortCertification?

    init(userCode: String, tierCode: String? = nil, iamPortRequest: IamPortRequest) {
        self.userCode = userCode
        self.tierCode = tierCode
        self.iamPortRequest = iamPortRequest
    }

    init(userCode: String, tierCode: String? = nil, iamPortCertification: IamPortCertification) {
        self.userCode = userCode
        self.tierCode = tierCode
        self.iamPortCertification = iamPortCertification
    }

    func isCertification() -> Bool {
        if iamPortCertification != nil {
            return true
        } else {
            return false
        }
    }

    func getMerchantUid() -> String {
        if (isCertification()) {
            return iamPortCertification?.merchant_uid ?? CONST.EMPTY_STR
        }
        return iamPortRequest?.merchant_uid ?? CONST.EMPTY_STR
    }

    func getCustomerUid() -> String {
        if (isCertification()) {
            return CONST.EMPTY_STR
        }
        return iamPortRequest?.customer_uid ?? CONST.EMPTY_STR
    }

    static func validator(_ payment: Payment, _ validateResult: @escaping ((Bool, String)) -> Void) {

        var validResult = ((true, CONST.PASS_PAYMENT_VALIDATOR))

        payment.iamPortRequest?.do { it in

            let payMethod = it.pay_method

            if (payMethod == PayMethod.vbank) {
                if (it.vbank_due.nilOrEmpty) {
                    validResult = (false, CONST.ERR_PAYMENT_VALIDATOR_VBANK)
                }
            }

            if (payMethod == PayMethod.phone) {
                if (it.digital == nil) {
                    validResult = (false, CONST.ERR_PAYMENT_VALIDATOR_PHONE)
                }
            }

            if (PG.convertPG(pgString: it.pg) == PG.danal_tpay && payMethod == PayMethod.vbank) {
                if (it.biz_num.nilOrEmpty) {
                    validResult = (false, CONST.ERR_PAYMENT_VALIDATOR_DANAL_VBANK)
                }
            }

        }

        validateResult(validResult)
    }

}
