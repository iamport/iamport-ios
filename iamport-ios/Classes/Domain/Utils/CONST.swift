//
// Created by BingBong on 2021/01/06.
//

import Foundation

class CONST {

    static let APP_SCHME = "iamport_ios"
    static let HTTP_SCHEME = "http"
    static let HTTPS_SCHEME = "https"
    static let ABOUT_BLANK_SCHEME = "about:blank"

    static let EMPTY_STR = ""

    static let IMP_USER_CODE = "impUserCode"
    static let IMP_UID = "impUid"
    static let PAYMENT_WEBVIEW_JS_INTERFACE_NAME = "IAMPORT"

    static let NICE_PG_PROVIDER = "nice"

    // 이 url 로 감지되면, 결제완료 콜백이란 의미 + 붙은 파라미터로 결제결과 처리
    static let IAMPORT_DUMMY_URL = "http://localhost/iamport"

    static let IAMPORT_PROD_URL = "https://service.iamport.kr" // 테스트도 상용서버에서
//    static let IAMPORT_TEST_URL = "https://kicc.iamport.kr"


    static let CHAI_SERVICE_URL = "https://api.chai.finance"
    static let CHAI_SERVICE_STAGING_URL = "https://api-staging.chai.finance"

    static let PAYMENT_PLAY_STORE_URL = "market://details?id="

    static let PAYMENT_FILE_URL = "경로/iamportcdn.html"

    static let IAMPORT_LOG = "IAMPORT"

    static let CONTRACT_INPUT = "input"
    static let CONTRACT_OUTPUT = "output"
    static let BUNDLE_PAYMENT = "payment"


//    static let POLLING_DELAY = 1000
//
//    private static let TRY_OUT_ONE_MIN = 60000
//
//    // POLLING_DELAY // 1분 단위
//    static let TRY_OUT_MIN = 5 // 분
//    static let TRY_OUT_COUNT = TRY_OUT_ONE_MIN * TRY_OUT_MIN // 차이 폴링 타임아웃
////    static let TRY_OUT_COUNT = 15
//
//    static let CHAI_FINAL_PAYMENT_TIME_OUT_SEC = 6 * POLLING_DELAY // 차이 최종결제 위한 머천트 컨펌 타임아웃
//
//    static let BROADCAST_FOREGROUND_SERVICE = "com.iamport.sdk.broadcast.fgservice"
//    static let BROADCAST_FOREGROUND_SERVICE_STOP = "com.iamport.sdk.broadcast.fgservice.stop"


    static let ERR_PAYMENT_VALIDATOR_VBANK = "가상계좌 결제는 만료일자(vbank_due) 항목 필수입니다 (YYYYMMDDhhmm 형식)"
    static let ERR_PAYMENT_VALIDATOR_PHONE = "휴대폰 소액결제는 digital 항목 필수입니다"
    static let ERR_PAYMENT_VALIDATOR_DANAL_VBANK = "다날 가상계좌 결제는 사업자 등록번호(biz_num) 항목 필수입니다 (계약된 사업자등록번호 10자리)"
    static let ERR_PAYMENT_VALIDATOR_PAYPAL = "페이팔 결제는 m_redirect_url 항목 필수입니다"
}
