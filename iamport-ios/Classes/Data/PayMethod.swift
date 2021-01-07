//
// Created by BingBong on 2021/01/06.
//

import Foundation

public enum PayMethod: String, Codable {
    case card = "신용카드"
    case trans = "실시간계좌이체"
    case vbank = "가상계좌"
    case phone = "휴대폰소액결제"
    case samsung = "삼성페이 / 이니시스, KCP 전용"
    case kpay = "KPay앱 직접호출 / 이니시스 전용"
    case kakaopay = "카카오페이 직접호출 / 이니시스, KCP, 나이스페이먼츠 전용"
    case payco = "페이코 직접호출 / 이니시스, KCP 전용"
    case lpay = "LPAY 직접호출 / 이니시스 전용"
    case ssgpay = "SSG페이 직접호출 / 이니시스 전용"
    case tosspay = "토스간편결제 직접호출 / 이니시스 전용"
    case cultureland = "문화상품권 / 이니시스, LGU+, KCP 전용"
    case smartculture = "스마트문상 / 이니시스, LGU+, KCP 전용"
    case happymoney = "해피머니 / 이니시스, KCP 전용"
    case booknlife = "도서문화상품권 / LGU+, KCP 전용"
    case point = "베네피아 포인트 등 포인트 결제 / KCP 전용"
}
