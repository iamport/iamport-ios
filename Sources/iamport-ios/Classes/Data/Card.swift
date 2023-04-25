//
// Created by BingBong on 2021/11/29.
//

import Foundation

public class Card: Codable {
    var direct: CardDirect
    public init(direct: CardDirect) {
        self.direct = direct
    }
}

public class CardDirect: Codable {
    var code: String
    var quota: Int?
    public init(code: String) {
        self.code = code
    }
}
