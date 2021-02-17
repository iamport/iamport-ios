//
// Created by BingBong on 2021/01/06.
//

import Foundation
import RxSwift
import SystemConfiguration

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

extension String {
    func trim() -> String {
        return self.trimmingCharacters(in: CharacterSet.whitespaces)
    }

    func NilOrEmpty() -> Bool {
        if (self.trim().isEmpty) {
            return true
        } else {
            return false
        }
    }
}

class Utils {
    static public func getQueryStringToImpResponse(_ url: URL) -> IamPortResponse? {
        #if DEBUG
        print(url.queryParams().toJsonString())
        #endif
        let data = url.queryParams().toJsonData()
        if let impStruct = try? JSONDecoder().decode(IamPortResponseStruct.self, from: data) {
            return IamPortResponse.structToClass(impStruct)
        }
        return nil
    }

    static func openApp(_ url: URL) -> Bool {
        let application = UIApplication.shared
        let result = application.canOpenURL(url)

        if (result) {
            if #available(iOS 10.0, *) {
                application.open(url, options: [:], completionHandler: nil)
            } else {
                application.openURL(url)
            }
        }
        return result
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

    static func isInternetAvailable() -> Bool {

        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        zeroAddress.sin_family = sa_family_t(AF_INET)

        guard let defaultRouteReachability = withUnsafePointer(to: &zeroAddress, {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                SCNetworkReachabilityCreateWithAddress(nil, $0)
            }
        }) else {
            return false
        }

        var flags: SCNetworkReachabilityFlags = []

        if !SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags) {
            return false
        }

        let isReachable = flags.contains(.reachable)
        let needsConnection = flags.contains(.connectionRequired)
        return (isReachable && !needsConnection)
    }

    static func getOrZeroString(value: String?) -> String {
        if let result = value {
            return !result.isEmpty ? result : "0"
        } else {
            return "0"
        }
    }

    static func getOrEmpty(value: String?) -> String {
        if let result = value {
            return !result.isEmpty ? result : CONST.EMPTY_STR
        } else {
            return CONST.EMPTY_STR
        }
    }

    public static func delay(bySeconds seconds: Double, dispatchLevel: DispatchLevel = .userInteractive, closure: @escaping () -> Void) {
        let dispatchTime = DispatchTime.now() + seconds
        dispatchLevel.dispatchQueue.asyncAfter(deadline: dispatchTime, execute: closure)
    }

    public enum DispatchLevel {
        case main, userInteractive, userInitiated, utility, background
        var dispatchQueue: DispatchQueue {
            switch self {
            case .main:                 return DispatchQueue.main
            case .userInteractive:      return DispatchQueue.global(qos: .userInteractive)
            case .userInitiated:        return DispatchQueue.global(qos: .userInitiated)
            case .utility:              return DispatchQueue.global(qos: .utility)
            case .background:           return DispatchQueue.global(qos: .background)
            }
        }
    }

}
