//
// Created by BingBong on 2021/01/06.
//

import Foundation

class CONST {

    static let COLON_SLASH_SLASH = "://"

    static let HTTP_SCHEME = "http"
    static let HTTPS_SCHEME = "https"
    static let ABOUT_BLANK_SCHEME = "about"
    static let FILE_SCHEME = "file"

    static let EMPTY_STR = ""

    static let IMP_USER_CODE = "impUserCode"
    static let IMP_UID = "impUid"
    static let PAYMENT_WEBVIEW_JS_INTERFACE_NAME = "IAMPORT"

    static let NICE_PG_PROVIDER = "nice"

    // 이 url 로 감지되면, 결제완료 콜백이란 의미 + 붙은 파라미터로 결제결과 처리
    static let IAMPORT_DETECT_SCHEME = "\(HTTP_SCHEME)://"
    static let IAMPORT_DETECT_ADDRESS = "detectchangingwebview/iamport/i"
    static let IAMPORT_DETECT_URL = "\(IAMPORT_DETECT_SCHEME)\(IAMPORT_DETECT_ADDRESS)"

//    static let IAMPORT_PROD_URL = "https://service.iamport.kr"
    static let IAMPORT_PROD_URL = "https://pay3.iamport-dev.co"

//    static let IAMPORT_PROD_URL = "http://1b8309246be2.ngrok.io"
//    static let IAMPORT_TEST_URL = "https://kicc.iamport.kr"


    static let CHAI_SERVICE_URL = "https://api.chai.finance"
    static let CHAI_SERVICE_DEV_URL = "https://api-dev.chai.finance"
    static let CHAI_SERVICE_STAGING_URL = "https://api-staging.chai.finance"

    static let SMILE_PAY_BASE_URL = "https://www.mysmilepay.com"

    static let PAYMENT_PLAY_STORE_URL = "market://details?id="

    static let CDN_FILE_NAME = "iamportcdn"
    static let CDN_FILE_EXTENSION = "html"

    static let IAMPORT_LOG = "IAMPORT"

    static let CONTRACT_INPUT = "input"
    static let CONTRACT_OUTPUT = "output"
    static let BUNDLE_PAYMENT = "payment"

    static let NETWORK_TIMEOUT_SEC = 20
    static let NETWORK_SHORT_TIMEOUT_SEC = 5
    static let POLLING_DELAY = 1
//
    private static let TIME_OUT_ONE_MIN = 60

//    // POLLING_DELAY // 1분 단위
    static let TIME_OUT_MIN = 5 // 분
    static let TIME_OUT = TIME_OUT_ONE_MIN * TIME_OUT_MIN // 차이 폴링 타임아웃

    static let CHAI_FINAL_PAYMENT_TIME_OUT_SEC = 6 * POLLING_DELAY // 차이 최종결제 위한 머천트 컨펌 타임아웃

    static let USER_TYPE_PAYMENT = "payment"
    static let USER_TYPE_CERTIFICATION = "certification"


    // payment 객체 validation 관련
    static let PASS_PAYMENT_VALIDATOR = "성공"

    private static let PREFIX_ERR = "[SDK ERR]"
    static let ERR_PAYMENT_VALIDATOR_VBANK = "\(PREFIX_ERR) 가상계좌 결제는 만료일자(vbank_due) 항목 필수입니다 (YYYYMMDDhhmm 형식)"
    static let ERR_PAYMENT_VALIDATOR_PHONE = "\(PREFIX_ERR) 휴대폰 소액결제는 digital 항목 필수입니다"
    static let ERR_PAYMENT_VALIDATOR_DANAL_VBANK = "\(PREFIX_ERR) 다날 가상계좌 결제는 사업자 등록번호(biz_num) 항목 필수입니다 (계약된 사업자등록번호 10자리)"
    static let ERR_PAYMENT_VALIDATOR_EXIMBAY = "\(PREFIX_ERR) eximbay 는 모바일앱 결제시 IamPortRequest popup 파라미터를 false 로 지정해야 결제창이 열립니다."
//    static let ERR_PAYMENT_VALIDATOR_PAYPAL = "페이팔 결제는 m_redirect_url 항목 필수입니다"
}
