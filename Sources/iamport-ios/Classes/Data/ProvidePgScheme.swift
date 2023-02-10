//
// Created by BingBong on 2021/01/12.
//

import Foundation

public enum ProvidePgScheme: String, CaseIterable {
    // url 에서 제공하지 않는 PG와 앱 패키지
    case BANKPAY = "kftc-bankpay"
    case ISP = "ispmobile"
    case KB_BANKPAY = "kb-bankpay"
    case NH_BANKPAY = "nhb-bankpay"
    case MG_BANKPAY = "mg-bankpay"
    case KN_BANKPAY = "kn-bankpay"

//        static func from(s: String) -> ProvidePgPkg? = values().find {
//        it.schme == s

    func getNiceBankPayPrefix() -> String {
        let process = "://eftpay?"
        return "\(rawValue)\(process)"
    }

//    func getNiceBankPayAppCls() -> String {
//        return "\(BANKPAY.second).activity.MainActivity"
//    }
}
