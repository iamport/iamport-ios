//
// Created by BingBong on 2021/01/06.
//

import Foundation
import Then

/**
 app_scheme 에 대하여..
 (PG : .html5_inicis, pay_method : .trans) 일 때, :// 을 붙여주세요. 간헐적으로 결제를 못해서 미결제남.
 (PG : .smilepay, pay_method : .card) 또한 :// 으로 CNS 측에 등록되어있을 수 있으니 확인해주세요. 안그러면 스마일페이 앱에서 404 에러남.
 */
public class IamPortRequest: Codable, Then {
    var pg: String // 없음안됨
    public var pay_method: String = PayMethod.card.rawValue
    public var escrow: Bool? // default false
    public let merchant_uid: String // 없음안됨 // default "random"
    public var customer_uid: String?
    public var name: String?
    let amount: String // 없음안됨
    public var custom_data: String?
    public var tax_free: Float?
    public var currency: String? // default KRW 페이팔은 USD 이어야 함
    public var language: String? // default "ko"
    public var buyer_name: String?
    public var buyer_tel: String?
    public var buyer_email: String?
    public var buyer_addr: String?
    public var buyer_postcode: String?
    public var notice_url: Array<String>?
    public var display: CardQuota?
    public var digital: Bool? // default false
    public var vbank_due: String? // YYYYMMDDhhmm
    private var m_redirect_url: String? = CONST.IAMPORT_DETECT_URL // 콜백
    public var app_scheme: String? // 명세상 nilable 이나 RN 에서 필수
    public var biz_num: String?
    public var popup: Bool? // 엑심베이일때 false 로 해야 열림
    private var niceMobileV2: Bool? = true


    // 네이버 관련
    public var naverPopupMode: Bool?
    public var naverUseCfm: String?

    public var naverProducts: [BaseProduct]? // 네이버페이 주문형

    public var naverCultureBenefit: Bool?
    public var naverProductCode: String?
    public var naverActionType: String?

    public var cultureBenefit: Bool?
    public var naverInterface: NaverInterface?

    public var card: Card? // 카드사 다이렉트 호출
    public var confirm_url: String? // confirm process

    // 이니시스 정기결제 제공기간
    public var period: Period?

    public init(pg: String, merchant_uid: String, amount: String) {
        self.pg = pg
        self.merchant_uid = merchant_uid
        self.amount = amount
    }

    func getRedirectUrl() -> String? {
        m_redirect_url
    }

    private enum CodingKeys: String, CodingKey {
        case pg, pay_method, escrow, merchant_uid, customer_uid, name, amount, tax_free, currency, language, buyer_name, buyer_tel, buyer_email, buyer_addr, buyer_postcode, notice_url, display, digital, vbank_due, m_redirect_url, app_scheme, biz_num, popup, niceMobileV2, naverPopupMode, naverUseCfm, naverProducts, naverCultureBenefit, naverProductCode, naverActionType, cultureBenefit, naverInterface, card, confirm_url, period
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

    public func setPlatform(platform: String) {
        if let p = Platform.convertPlatform(platformStr: platform) {
            m_redirect_url = p.redirectUrl
        } else {
            m_redirect_url = Utils.getRedirectUrl(platformKey: platform)
        }
    }

}
