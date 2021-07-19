//
// Created by BingBong on 2021/01/07.
//

import Foundation

public enum PG: String, CaseIterable, Codable {

    case chai
    case kcp
    case html5_inicis // only for 결제
//    case inicis // only for 본인인증
    case kcp_billing
    case uplus
    case jtnet
    case kakaopay
    case nice
    case danal
    case danal_tpay
    case kicc
    case paypal
    case mobilians
    case payco
    case eximbay
    case settle
    case settle_firm
    case naverco
    case naverpay
    case smilepay
    case payple
    case alipay
    case bluewalnut
    case tosspay

    public var name: String {
        switch self {
        case .chai:
            return "차이 간편결제"
        case .kcp:
            return "NHN KCP"
        case .html5_inicis:
            return "이니시스웹표준"
        case .kcp_billing:
            return "NHN KCP 정기결제"
        case .uplus:
            return "LGU+"
        case .jtnet:
            return "JTNet"
        case .kakaopay:
            return "카카오페이"
        case .nice:
            return "나이스페이"
        case .danal:
            return "다날휴대폰소액결제"
        case .danal_tpay:
            return "다날일반결제"
        case .kicc:
            return "한국정보통신"
        case .paypal:
            return "페이팔"
        case .mobilians:
            return "모빌리언스 휴대폰소액결제"
        case .payco:
            return "페이코"
        case .eximbay:
            return "엑심베이"
        case .settle:
            return "세틀뱅크"
        case .settle_firm:
            return "세틀뱅크_펌"
        case .naverco:
            return "네이버페이-주문형"
        case .naverpay:
            return "네이버페이-결제형"
        case .smilepay:
            return "스마일페이"
        case .payple:
            return "페이플"
        case .alipay:
            return "알리페이"
        case .bluewalnut:
            return "bluewalnut"
        case .tosspay:
            return "토스페이"
//        case .inicis:
//            return "이니시스본인인증"
        }
    }

    public func makePgRawName(pgId: String? = nil) -> String {
        var id: String = CONST.EMPTY_STR
        if let pg = pgId {
            if (pg.count > 0) {
                id = ".\(pg)"
            }
        }
        return "\(self)\(id)"
    }

    public static func convertPG(pgString: String) -> PG? {
        for value in self.allCases {
            if (pgString == value.rawValue) {
                return value
            }
        }

        return nil
    }

//    static func getPGNames() -> Array<String> {
//        values().map {
//            "${it.korName} (${it.name})"
//        }.toList()
//    }
}