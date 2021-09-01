//
// Created by BingBong on 2021/04/12.
//

import Foundation

public enum Platform: String, CaseIterable {
    case native
    case reactnative
    case flutter
    case cordova
    case capacitor

    var redirectUrl: String {
        switch self {
        case .native:
            return CONST.IAMPORT_DETECT_URL
        case .reactnative:
            return Utils.getRedirectUrl(platformKey: "rn")
        case .flutter:
            return Utils.getRedirectUrl(platformKey: "flu")
        case .cordova:
            return Utils.getRedirectUrl(platformKey: "cor")
        case .capacitor:
            return Utils.getRedirectUrl(platformKey: "cap")
        }
    }

    static func convertPlatform(platformStr: String) -> Platform? {
        for value in self.allCases {
            if (platformStr == value.rawValue) {
                return value
            }
        }

        return nil
    }

}
