//
// Created by BingBong on 2021/01/06.
//

import Foundation

public enum PayMethod: String, CaseIterable, Codable {
    case card
    case trans
    case vbank
    case phone
    case samsung
    case kpay
    case kakaopay
    case payco
    case lpay
    case ssgpay
    case tosspay
    case cultureland
    case smartculture
    case happymoney
    case booknlife
    case point
    case unionpay
    case alipay
    case tenpay
    case wechat
    case molpay
    case paysbuy

    public var name: String {
        switch self {
        case .card:
            return "신용카드"
        case .trans:
            return "실시간계좌이체"
        case .vbank:
            return "가상계좌"
        case .phone:
            return "휴대폰소액결제"
        case .samsung:
            return "삼성페이 / 이니시스, KCP 전용"
        case .kpay:
            return "KPay앱 직접호출 / 이니시스 전용"
        case .kakaopay:
            return "카카오페이 직접호출 / 이니시스, KCP, 나이스페이먼츠 전용"
        case .payco:
            return "페이코 직접호출 / 이니시스, KCP 전용"
        case .lpay:
            return "LPAY 직접호출 / 이니시스 전용"
        case .ssgpay:
            return "SSG페이 직접호출 / 이니시스 전용"
        case .tosspay:
            return "토스간편결제 직접호출 / 이니시스 전용"
        case .cultureland:
            return "문화상품권 / 이니시스, LGU+, KCP 전용"
        case .smartculture:
            return "스마트문상 / 이니시스, LGU+, KCP 전용"
        case .happymoney:
            return "해피머니 / 이니시스, KCP 전용"
        case .booknlife:
            return "도서문화상품권 / LGU+, KCP 전용"
        case .point:
            return "베네피아 포인트 등 포인트 결제 / KCP 전용"
        case .unionpay:
            return "유니온페이"
        case .alipay:
            return "알리페이"
        case .tenpay:
            return "텐페이"
        case .wechat:
            return "위챗페이"
        case .molpay:
            return "몰페이"
        case .paysbuy:
            return "태국 paysbuy"
        }
    }

    public static func convertPayMethod(_ payMethodString: String) -> PayMethod {
        for value in allCases {
            if payMethodString == value.rawValue {
                return value
            }
        }

        return .card
    }
}
