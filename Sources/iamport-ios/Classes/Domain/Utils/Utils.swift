//
// Created by BingBong on 2021/01/06.
//

import Foundation
import RxSwift
import SystemConfiguration
import UIKit

#if !IAMPORTSPM
    extension Bundle {
        static var module: Bundle {
            Bundle(identifier: "org.cocoapods.iamport-ios")!
        }
    }
#endif

func debug_log(_ log: Any..., file: String = #file, line: UInt = #line, column: UInt = #column, function: String = #function) {
    #if DEBUG
    debugPrint("\((file as NSString).lastPathComponent)(\(function)):\(line):\(column) \(log)")
    #endif
}

func debug_dump<T>(_ value: T) {
    #if DEBUG
        dump(value)
    #endif
}

extension UIView {
    var viewController: UIViewController? {
        if let vc = next as? UIViewController {
            return vc
        } else if let superView = superview {
            return superView.viewController
        } else {
            return nil
        }
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

    func valueOf(_ queryParameterName: String) -> String? {
        guard let url = URLComponents(string: absoluteString) else {
            return nil
        }
        return url.queryItems?.first(where: { $0.name == queryParameterName })?.value
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
        return trimmingCharacters(in: CharacterSet.whitespaces)
    }
}

extension Optional where Wrapped == String {
    var nilOrEmpty: Bool {
        guard let strongSelf = self else {
            return true
        }

        return strongSelf.trim().isEmpty ? true : false
    }
}

enum Utils {
    public static func getQueryStringToImpResponse(_ url: URL) -> IamportResponse? {
        #if DEBUG
            debug_log(url.queryParams().toJsonString())
        #endif
        let data = url.queryParams().toJsonData()
        if let impStruct = try? JSONDecoder().decode(IamportResponseStruct.self, from: data) {
            return IamportResponse.structToClass(impStruct)
        }
        return nil
    }

    static func justOpenApp(_ url: URL, moveAppStore: (() -> Void)? = nil) {
        return UIApplication.shared.open(url, options: [:]) { openApp in
            if !openApp {
                if let move = moveAppStore {
                    debug_log("앱스토어로 이동")
                    move()
                }
            }
        }
    }

    static func openAppWithCanOpen(_ url: URL) -> Bool {
        let result = UIApplication.shared.canOpenURL(url)
        if result {
            justOpenApp(url)
        }
        return result
    }

    /**
     * 앱 uri 인지 여부
     */
    static func isAppUrl(_ uri: URL) -> Bool {
        if let it = uri.scheme {
            return it != Constant.HTTP_SCHEME && it != Constant.HTTPS_SCHEME && it != Constant.ABOUT_BLANK_SCHEME && it != Constant.FILE_SCHEME
        }
        return false
    }

    /**
     * 결제 끝났는지 여부
     */
    static func isPaymentOver(_ uri: URL) -> Bool {
        return uri.absoluteString.contains(Constant.IAMPORT_DETECT_URL)
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

    static func getOrEmpty(value: String?) -> String {
        if let result = value {
            return !result.isEmpty ? result : Constant.EMPTY_STR
        }

        return Constant.EMPTY_STR
    }

    public static func delay(bySeconds seconds: Double, dispatchLevel: DispatchLevel = .userInteractive, closure: @escaping () -> Void) {
        let dispatchTime = DispatchTime.now() + seconds
        dispatchLevel.dispatchQueue.asyncAfter(deadline: dispatchTime, execute: closure)
    }

    public static func getRedirectUrl(platformKey: String) -> String {
        "\(Constant.IAMPORT_DETECT_SCHEME)\(Constant.IAMPORT_DETECT_ADDRESS)/\(platformKey)"
    }

    public enum DispatchLevel {
        case main, userInteractive, userInitiated, utility, background
        var dispatchQueue: DispatchQueue {
            switch self {
            case .main: return DispatchQueue.main
            case .userInteractive: return DispatchQueue.global(qos: .userInteractive)
            case .userInitiated: return DispatchQueue.global(qos: .userInitiated)
            case .utility: return DispatchQueue.global(qos: .utility)
            case .background: return DispatchQueue.global(qos: .background)
            }
        }
    }
}

extension String {
    func getBase64Encode() -> String? {
        data(using: .utf8)?.base64EncodedString()
    }
}
