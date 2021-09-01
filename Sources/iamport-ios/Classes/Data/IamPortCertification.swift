//
// Created by BingBong on 2021/02/22.
//

import Foundation
import Then

// https://docs.iamport.kr/tech/mobile-authentication
public class IamPortCertification: Codable, Then {

    let merchant_uid: String

    public var min_age: Int?
    public var name: String?
    public var phone: String?

    /**
     (선택항목) 본인인증 화면 진입 시 지정된 통신사만 선택이 가능하도록 제한합니다. 아래 4가지 중 택일
        SKT : SKT
        KT : KTF
        LGU+ : LGT
        알뜰폰 : MVNO
     */
    public var carrier: String?

    // (선택항목) 본인인증 동작에 영향을 주는 파라메터는 아니지만, KISA의 ePrivacy Clean 서비스연동을 위해 지정이 권장되는 파라메터입니다.
    //  가맹점 개발 편의를 위해, 아임포트에서 IMP.certification()이 호출되는 URL 도메인을 자동으로 지정하고 있습니다만,
    //  ReactNative / Ionic 등 앱 내 local html을 통해 IMP.certification()이 호출되는 경우에는 URL 도메인을 인식할 수 없으므로 본 파라메터 지정이 권장됩니다.(지정하지 않으면 아임포트라고 전달합니다)
    //  운영하시는 서비스의 대표 도메인 URL(예시 : https://www.iamport.co.kr) 또는 서비스 명칭(예시 : 아임포트)을 지정하시면 됩니다.
    public var company: String?
    private var m_redirect_url: String? = CONST.IAMPORT_DETECT_URL // 콜백

    public init(merchant_uid: String) {
        self.merchant_uid = merchant_uid
    }
}
