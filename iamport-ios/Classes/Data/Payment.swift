//
// Created by BingBong on 2021/01/07.
//

import Foundation
import Then

struct Payment: Codable, Then {
    let userCode: String
    var iamPortRequest: IamPortRequest

    init(userCode: String, iamPortRequest: IamPortRequest) {
        self.userCode = userCode
        self.iamPortRequest = iamPortRequest
    }

    static func validator(_ payment: Payment, _ validateResult: @escaping ((Bool, String)) -> Void) {

        var validResult = ((true, CONST.PASS))

        payment.iamPortRequest.do { it in

            if (it.pay_method == PayMethod.vbank) {
                if (it.vbank_due.nilOrEmpty) {
                    validResult = (false, CONST.ERR_PAYMENT_VALIDATOR_VBANK)
                }
            }

            if (it.pay_method == PayMethod.phone) {
                if (it.digital == nil) {
                    validResult = (false, CONST.ERR_PAYMENT_VALIDATOR_PHONE)
                }
            }

            if (PG.convertPG(pgString: it.pg) == PG.danal_tpay && it.pay_method == PayMethod.vbank) {
                if (it.biz_num.nilOrEmpty) {
                    validResult = (false, CONST.ERR_PAYMENT_VALIDATOR_DANAL_VBANK)
                }
            }

//            if (PG.convertPG(pgString: it.pg) == PG.paypal) {
//                if (it.m_redirect_url.nilOrEmpty || it.m_redirect_url == CONST.IAMPORT_DETECT_URL) {
//                    validResult = (false, CONST.ERR_PAYMENT_VALIDATOR_PAYPAL)
//                }
//            }
        
        }

        validateResult(validResult)
    }

}
