//
// Created by BingBong on 2021/01/25.
//

import Foundation
import Then

class PrepareRequest: DictionaryEncodable, Then {

    var channel: String = CHAI.CHANNEL //fixed
    var provider: PG = PG.chai //fixed
    var pay_method: PayMethod = PayMethod.trans //fixed
    var escrow: Bool? // true or false
    var amount: String // 결제금액
    var tax_free: String? // 결제금액 중 면세공급가액
    var name: String //주문명
    var merchant_uid: String // 가맹점 주문번호
    var user_code: String // 아임포트 가맹점 식별코드
    var tier_code: String? // 아임포트 agency 하위계정 tier code
    var pg_id: String // 차이계정 public Key // 복수PG로직에 따라 Http 요청 1에서 받은 정보 + 요청인자 활용
    var buyer_name: String? // 구매자 이름
    var buyer_email: String? // 구매자 Email
    var buyer_tel: String? // 구매자 전화번호
    var buyer_addr: String? // 구매자 주소
    var buyer_postcode: String? // 구매자 우편번호
    var app_scheme: String? // 결제 후 돌아갈 app scheme
    var custom_data: String? // 결제 건에 연결해 저장할 meta data
    var notice_url: String? // Webhook Url
    var confirm_url: String? // Confirm process Url
    var _extra: Extra // 차이 마케팅 팀과 사전협의된 파라메터

    public init(user_code: String, merchant_uid: String, amount: String, name: String, pg_id: String, _extra: Extra) {
        self.user_code = user_code
        self.amount = amount
        self.merchant_uid = merchant_uid
        self.name = name
        self.pg_id = pg_id
        self._extra = _extra
    }


    static func make(chaiId: String, payment: Payment) -> PrepareRequest {
        let empty = CONST.EMPTY_STR
        let request = payment.iamPortRequest.with { _ in
        }
        return PrepareRequest(user_code: payment.userCode,
                merchant_uid: request.merchant_uid,
                amount: request.amount,
                name: Utils.getOrEmpty(value: request.name),
                pg_id: chaiId,
                _extra: Extra(native: OS.ios, bypass: empty)).then {
            $0.escrow = false
            $0.tax_free = Utils.getOrZeroString(value: request.tax_free)
            $0.tier_code = empty
            $0.buyer_name = request.buyer_name
            $0.buyer_email = request.buyer_email
            $0.buyer_tel = request.buyer_tel
            $0.buyer_addr = request.buyer_addr
            $0.buyer_postcode = request.buyer_postcode
            $0.app_scheme = request.app_scheme
            $0.custom_data = request.custom_data
            $0.notice_url = request.m_redirect_url
            $0.confirm_url = nil
        }
    }

    static func makeDictionary(chaiId: String, payment: Payment) -> [String: Any]? {
        make(chaiId: chaiId, payment: payment).dictionary()
    }

}

