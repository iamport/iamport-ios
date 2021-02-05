//
// Created by BingBong on 2021/01/25.
//

import Foundation
import Then


enum OS: String, Codable {
    case aos, ios
}

class Extra: Codable, Then {
    var native: OS
    var bypass: String

    public init(native: OS, bypass: String) {
        self.native = native
        self.bypass = bypass
    }
}
