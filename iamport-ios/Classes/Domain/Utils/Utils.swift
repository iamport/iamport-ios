//
// Created by BingBong on 2021/01/06.
//

import Foundation
import RxSwift

enum BusThread {
    //- utility: 유저의 프로세스에 필요한 연산작업에 사용한다. 프로그래스바, I/O, Networking 등
    //- background: 유저에게 직접적으로 필요하지 않은 작업들. logging 등

    case main, background, utility, `default`

    func toScheduler() -> SchedulerType {
        switch self {
        case .main:
            return MainScheduler.instance
        case .background:
            return ConcurrentDispatchQueueScheduler(qos: .background)
        case .utility:
            return ConcurrentDispatchQueueScheduler(qos: .utility)
        case .default:
            return ConcurrentDispatchQueueScheduler(qos: .default)
        }
    }
}

extension ObservableType {

    public func subscribeOnMain() -> Observable<Element> {
        subscribeOn(BusThread.main.toScheduler())
    }

    public func subscribeOnBg() -> Observable<Element> {
        subscribeOn(BusThread.background.toScheduler())
    }

    public func subscribeOnUtility() -> Observable<Element> {
        subscribeOn(BusThread.utility.toScheduler())
    }

    public func observeOnMain() -> Observable<Element> {
        observeOn(BusThread.main.toScheduler())
    }

    public func observeOnBg() -> Observable<Element> {
        observeOn(BusThread.background.toScheduler())
    }

    public func observeOnUtility() -> Observable<Element> {
        observeOn(BusThread.utility.toScheduler())
    }

    public func main() -> Observable<Element> {
        subscribeOnMain().observeOnMain()
    }

    public func bgMain() -> Observable<Element> {
        subscribeOnBg().observeOnMain()
    }

    public func asyncMain() -> Observable<Element> {
        subscribeOnUtility().observeOnMain()
    }

}

extension URL {
    func queryParams() -> [String: Any] {
        let queryItems = URLComponents(url: self, resolvingAgainstBaseURL: false)?.queryItems
        let queryTuples: [(String, Any)] = queryItems?.compactMap {
            guard let value = $0.value else {
                return nil
            }
            return ($0.name, value)
        } ?? []
        return Dictionary(uniqueKeysWithValues: queryTuples)
    }

    func valueOf(_ queryParamaterName: String) -> String? {
        guard let url = URLComponents(string: self.absoluteString) else {
            return nil
        }
        return url.queryItems?.first(where: { $0.name == queryParamaterName })?.value
    }
}

extension Dictionary {
    func toJsonData() -> Data {
        var jsonData: Data?
        do {
            jsonData = try JSONSerialization.data(withJSONObject: self, options: .init(rawValue: 0))
        } catch {
            print(error)
        }
        return jsonData!
    }

    func toJsonDataPrettyPrinted() -> Data {
        var jsonData: Data?
        do {
            jsonData = try JSONSerialization.data(withJSONObject: self, options: JSONSerialization.WritingOptions.prettyPrinted)
        } catch {
            print(error)
        }
        return jsonData!
    }

    func toJsonString() -> String {
        return toJsonData().toString()
    }

    func toPrettyPrintedJsonString() -> String {
        return toJsonDataPrettyPrinted().toString()
    }
}

extension Data {
    func hexString() -> String {
        return map {
            String(format: "%02hhx", $0)
        }.joined()
    }

    func toString() -> String {
        return String(data: self, encoding: String.Encoding.utf8)!
    }
}


class Utils {
    static public func getQueryStringToImpResponse(_ url: URL) -> IamPortResponse? {
        print(url.queryParams().toJsonString())
        let decoder = JSONDecoder()
        let data = url.queryParams().toJsonData()
        if let impStruct = try? decoder.decode(IamPortResponseStruct.self, from: data) {
            return IamPortResponse.structToClass(impStruct)
        }
        return nil
    }

    static func getMarketUrl(url: String, scheme: String) -> String {
        switch (scheme) {
        case "kftc-bankpay": // 뱅크페이
            return "https://itunes.apple.com/kr/app/id398456030";
        case "ispmobile": // ISP/페이북
            return "https://itunes.apple.com/kr/app/id369125087";
        case "hdcardappcardansimclick": // 현대카드 앱카드
            return "https://itunes.apple.com/kr/app/id702653088";
        case "shinhan-sr-ansimclick": // 신한 앱카드
            return "https://itunes.apple.com/app/id572462317";
        case "kb-acp": // KB국민 앱카드
            return "https://itunes.apple.com/kr/app/id695436326";
        case "mpocket.online.ansimclick": // 삼성앱카드
            return "https://itunes.apple.com/kr/app/id535125356";
        case "lottesmartpay": // 롯데 모바일결제
            return "https://itunes.apple.com/kr/app/id668497947";
        case "lotteappcard": // 롯데 앱카드
            return "https://itunes.apple.com/kr/app/id688047200";
        case "cloudpay": // 하나1Q페이(앱카드)
            return "https://itunes.apple.com/kr/app/id847268987";
        case "citimobileapp": // 시티은행 앱카드
            return "https://itunes.apple.com/kr/app/id1179759666";
        case "payco": // 페이코
            return "https://itunes.apple.com/kr/app/id924292102";
        case "kakaotalk": // 카카오톡
            return "https://itunes.apple.com/kr/app/id362057947";
        case "lpayapp": // 롯데 L.pay
            return "https://itunes.apple.com/kr/app/id1036098908";
        case "wooripay": // 우리페이
            return "https://itunes.apple.com/kr/app/id1201113419";
        case "nhallonepayansimclick": // NH농협카드 올원페이(앱카드)
            return "https://itunes.apple.com/kr/app/id1177889176";
        case "hanawalletmembers": // 하나카드(하나멤버스 월렛)
            return "https://itunes.apple.com/kr/app/id1038288833";
        case "shinsegaeeasypayment": // 신세계 SSGPAY
            return "https://itunes.apple.com/app/id666237916";
        default:
            return url;
        }
    }

    /**
     * 앱 uri 인지 여부
     */
    static func isAppUrl(_ uri: URL) -> Bool {
        if let it = uri.scheme {
            return it != CONST.HTTP_SCHEME && it != CONST.HTTPS_SCHEME && it != CONST.ABOUT_SCHEME && it != CONST.ABOUT_BLANK_SCHEME && it != CONST.FILE_SCHEME;
        }
        return false
    }

    /**
     * 결제 끝났는지 여부
     */
    static func isPaymentOver(_ uri: URL) -> Bool {
        uri.absoluteString.contains(CONST.IAMPORT_DUMMY_URL)
    }

    static func getActionPolicy(_ uri: URL) -> Bool {
        isAppUrl(uri) || isPaymentOver(uri)
    }


}
