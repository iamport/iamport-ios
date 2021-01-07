//
// Created by BingBong on 2021/01/07.
//

import Foundation

public enum PG: String {
    case chai = "차이 간편결제"
    case kcp = "NHN KCP"
    case html5_inicis = "이니시스웹표준"
    case kcp_billing = "NHN KCP 정기결제"
    case uplus = "LGU+"
    case jtnet = "JTNet"
    case kakaopay = "카카오페이"
    case nice = "나이스페이"
    case danal = "다날휴대폰소액결제"
    case danal_tpay = "다날일반결제"
    case kicc = "한국정보통신"
    case paypal = "페이팔"
    case mobilians = "모빌리언스 휴대폰소액결제"
    case payco = "페이코"
    case eximbay = "엑심베이"
    case settle = "세틀뱅크"
    case settle_firm = "세틀뱅크_펌"
    case naverco = "네이버페이-주문형"
    case naverpay = "네이버페이-결제형"
    case smilepay = "스마일페이"
    case payple = "페이플"
    case alipay = "알리페이"
    case bluewalnut = "bluewalnut"


    public func getPgSting(storeId: String? = nil) -> String {
        var id: String = CONST.EMPTY_STR
        if let store = storeId {
            if (store.count > 0) {
                id = ".\(store)"
            }
        }

        return "\(self)\(id)"
    }

}