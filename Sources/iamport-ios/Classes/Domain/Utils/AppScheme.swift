//
// Created by BingBong on 2021/02/17.
//

import Foundation

enum AppScheme: CaseIterable {
    case bankpay // 뱅크페이
    case ispmobile // ISP/페이북
    case hdcard // 현대카드 앱카드
    case shinhan // 신한 앱카드
    case kb // KB국민 앱카드
    case samsung // 삼성앱카드
    case lottemobile // 롯데 모바일결제
    case lottecard // 롯데 앱카드
    case hana1qpay // 하나1Q페이(앱카드)
    case citi // 시티은행 앱카드
    case payco // 페이코
    case kakaotalk // 카카오톡
    case lpay // 롯데 L.pay(구)
    case lmslpay // 롯데 L.pay(L.POINT App 신규 2021.05.27)
    case woori // 우리페이(구, 종료가능성 있음)
    case wooricard // 우리카드(신규)
    case nhcard // NH농협카드 올원페이(앱카드)
    case hanacard // 하나카드(하나멤버스 월렛)
    case ssgpay // 신세계 SSGPAY
    case chai // 차이
    case kbauth // 국민 본인인증
    case hyundaicardappcardid // 현대 본인인증
    case lguthepayxpay // 페이나우
    case liivbank // Liiv 국민
    case supertoss // 토스
    case newsmartpib // 우리WON뱅킹

    var scheme: String {
        switch self {
        case .bankpay:
            return "kftc-bankpay"
        case .ispmobile:
            return "ispmobile"
        case .hdcard:
            return "hdcardappcardansimclick"
        case .shinhan:
            return "shinhan-sr-ansimclick"
        case .kb:
            return "kb-acp"
        case .samsung:
            return "mpocket.online.ansimclick"
        case .lottemobile:
            return "lottesmartpay"
        case .lottecard:
            return "lotteappcard"
        case .hana1qpay:
            return "cloudpay"
        case .citi:
            return "citimobileapp"
        case .payco:
            return "payco"
        case .kakaotalk:
            return "kakaotalk"
        case .lpay:
            return "lpayapp"
        case .woori:
            return "wooripay"
        case .nhcard:
            return "nhallonepayansimclick"
        case .hanacard:
            return "hanawalletmembers"
        case .ssgpay:
            return "shinsegaeeasypayment"
        case .chai:
            return "chaipayment"
        case .kbauth:
            return "kb-auth"
        case .hyundaicardappcardid:
            return "hyundaicardappcardid"
        case .lmslpay:
            return "lmslpay"
        case .wooricard:
            return "com.wooricard.wcard"
        case .lguthepayxpay:
            return "lguthepay-xpay"
        case .liivbank:
            return "liivbank"
        case .supertoss:
            return "supertoss"
        case .newsmartpib:
            return "newsmartpib"
        }
    }

    var appID: String {
        switch self {
        case .bankpay:
            return "id398456030"
        case .ispmobile:
            return "id369125087"
        case .hdcard:
            return "id702653088"
        case .shinhan:
            return "id572462317"
        case .kb:
            return "id695436326"
        case .samsung:
            return "id535125356"
        case .lottemobile:
            return "id668497947"
        case .lottecard:
            return "id688047200"
        case .hana1qpay:
            return "id847268987"
        case .citi:
            return "id1179759666"
        case .payco:
            return "id924292102"
        case .kakaotalk:
            return "id362057947"
        case .lpay:
            return "id1036098908"
        case .woori:
            return "id1201113419"
        case .nhcard:
            return "id1177889176"
        case .hanacard:
            return "id1038288833"
        case .ssgpay:
            return "id666237916"
        case .chai:
            return "id1459979272"
        case .kbauth:
            return "id695436326"
        case .hyundaicardappcardid:
            return "id702653088"
        case .lmslpay:
            return "id473250588"
        case .wooricard:
            return "id1499598869"
        case .lguthepayxpay:
            return "id760098906"
        case .liivbank:
            return "id1126232922"
        case .supertoss:
            return "id839333328"
        case .newsmartpib:
            return "id1470181651"
        }
    }

    private static func findAppScheme(_ scheme: String) -> AppScheme? {
        for value in AppScheme.allCases {
            if scheme.caseInsensitiveCompare(value.scheme) == .orderedSame {
                return value
            }
        }

        return nil
    }

    // TODO: appId 를 api 에서 받아왔으면 좋겠다..
    static func getAppStoreUrl(scheme: String) -> String? {
        let appScheme = findAppScheme(scheme)

        guard let appId = appScheme?.appID else {
            print("지원하지 않는 App Scheme [\(scheme)] 입니다.")
            return nil
        }

        let marketUrl = "itms-apps://itunes.apple.com/app/\(appId)"
        return marketUrl
    }
}
