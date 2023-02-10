//
// Created by BingBong on 2021/01/29.
//

import Foundation

enum ChaiPaymentStatus: String, CaseIterable {
    case waiting, prepared,
         approved,
         user_canceled, canceled, failed, timeout,
         confirmed, partial_confirmed, inactive, churn

    static func from(displayStatus: String) -> ChaiPaymentStatus? {
        for value in allCases {
            if displayStatus == value.rawValue {
                return value
            }
        }

        return nil
    }
}
