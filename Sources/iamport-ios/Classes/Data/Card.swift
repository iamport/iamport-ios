//
// Created by BingBong on 2021/11/29.
//

import Foundation

public class Card: Codable {
    var direct: Direct
    public init(direct: Direct)  {
        self.direct = direct
    }
}

public class Direct: Codable {
    var code: String
    var quota: Int?
    public init(code: String) {
        self.code = code
    }
}