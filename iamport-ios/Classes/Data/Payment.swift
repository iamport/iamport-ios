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

    init(userCode: String, iamPortRequest: IamPortRequest) {
        self.userCode = userCode
        self.iamPortRequest = iamPortRequest
    }

    init(userCode: String, iamPortCertification: IamPortCertification) {
        self.userCode = userCode
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

        var merchantUid: String = CONST.EMPTY_STR
        if (isCertification()) {
            merchantUid = iamPortCertification?.merchant_uid ?? merchantUid
        } else {
            merchantUid = iamPortRequest?.merchant_uid ?? merchantUid
        }

        return merchantUid
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
