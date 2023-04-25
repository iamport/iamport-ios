//
// Created by BingBong on 2021/01/25.
//

import Foundation
import Then

class PrepareRequest: DictionaryEncodable, Then {
    var channel: String = CHAI.CHANNEL // fixed
    var provider: PG = .chai // fixed
    var pay_method: String = PayMethod.trans.rawValue // fixed
    var escrow: Bool? // true or false
    var amount: String // 결제금액
    var tax_free: Float? // 결제금액 중 면세공급가액
    var name: String // 주문명
    var merchant_uid: String // 가맹점 주문번호
    var customer_uid: String?
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
    var notice_url: [String]? // Webhook Url
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

    static func make(chaiId: String, request: IamportRequest) -> PrepareRequest? {
        guard case let .payment(payment) = request.payload else {
            print("PrepareRequest, make, iamportRequest is nil")
            return nil
        }

        return PrepareRequest(user_code: request.userCode,
                              merchant_uid: payment.merchant_uid,
                              amount: payment.amount,
                              name: Utils.getOrEmpty(value: payment.name),
                              pg_id: chaiId,
                              _extra: Extra(native: OS.ios, bypass: Constant.EMPTY_STR)).then {
            $0.escrow = false
            $0.tax_free = payment.tax_free
            $0.tier_code = Constant.EMPTY_STR
            $0.buyer_name = payment.buyer_name
            $0.buyer_email = payment.buyer_email
            $0.buyer_tel = payment.buyer_tel
            $0.buyer_addr = payment.buyer_addr
            $0.buyer_postcode = payment.buyer_postcode
            $0.app_scheme = payment.app_scheme
            $0.custom_data = payment.custom_data
            $0.notice_url = payment.notice_url
            $0.customer_uid = payment.customer_uid
            $0.confirm_url = payment.confirm_url
        }
    }

    static func makeDictionary(chaiId: String, request: IamportRequest) -> [String: Any]? {
        make(chaiId: chaiId, request: request)?.dictionary()
    }
}
