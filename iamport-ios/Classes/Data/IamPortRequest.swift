//
// Created by BingBong on 2021/01/06.
//

import Foundation
import Then

public class IamPortRequest: Codable {
    let pg: String // 없음안됨
    public var pay_method: PayMethod = PayMethod.card // 명세상 필수인지 불명확함 default card
    public var escrow: Bool? = nil // default false
    public let merchant_uid: String // 없음안됨 // default "random"
    public var name: String? = nil
    let amount: String // 없음안됨
    public var custom_data: String? = nil // 명세상 불명확
    public var tax_free: String? = nil
    public var currency: Currency? = nil // default KRW 페이팔은 USD 이어야 함
    public var language: String? = nil // default "ko"
    public var buyer_name: String? = nil
    public var buyer_tel: String? = nil
    public var buyer_email: String? = nil
    public var buyer_addr: String? = nil
    public var buyer_postcode: String? = nil
    public var notice_url: Array<String>? = nil
    public var display: CardQuota? = nil
    public var digital: Bool? = nil // default false
    public var vbank_due: String? = nil // YYYYMMDDhhmm
    public var m_redirect_url: String? = CONST.IAMPORT_DUMMY_URL // 콜백
    public var app_scheme: String? = nil // 명세상 nilable 이나 RN 에서 필수
    public var biz_num: String? = nil
    public var popup: Bool? = nil // 명세상 없으나 RN 에 있음

    public init(pg: String, merchant_uid: String, amount: String) {
        self.pg = pg
        self.merchant_uid = merchant_uid
        self.amount = amount
    }
}

extension IamPortRequest {

    /**
     * string pg 으로 enum PG 가져옴
     */
    var pgEnum: PG? {
        get {
            PG.convertPG(pgString: pg)
        }
    }

}

extension IamPortRequest: Then {
}