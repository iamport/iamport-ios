//
// Created by BingBong on 2021/01/12.
//

import Foundation

enum BankPayResultCode: String, CaseIterable {
    case OK
    case CANCEL
    case TIME_OUT
    case FAIL_SIGN
    case FAIL_OTP
    case FAIL_CERT_MODULE_INIT

    static func from(_ s: String) -> BankPayResultCode? {
        for value in allCases {
            if s == value.code {
                return value
            }
        }
        return nil
    }

    var code: String {
        switch self {
        case .OK:
            return "000"
        case .CANCEL:
            return "091"
        case .TIME_OUT:
            return "060"
        case .FAIL_SIGN:
            return "050"
        case .FAIL_OTP:
            return "040"
        case .FAIL_CERT_MODULE_INIT:
            return "030"
        }
    }

    var description: String {
        switch self {
        case .OK:
            return "결제성공 하였습니다"
        case .CANCEL:
            return "계좌이체 결제를 취소하였습니다."
        case .TIME_OUT:
            return "타임아웃"
        case .FAIL_SIGN:
            return "전자서명 실패"
        case .FAIL_OTP:
            return "OTP/보안카드 처리 실패"
        case .FAIL_CERT_MODULE_INIT:
            return "인증모듈 초기화 오류"
        }
    }
}
