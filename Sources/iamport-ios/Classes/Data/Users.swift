//
// Created by BingBong on 2021/01/20.
//

import Foundation
import Then

struct Users: Codable, Then {
    var code: Int
    var msg: String?
    var data: [UserData]

    public init(code: Int, msg: String?, data: [UserData]) {
        self.code = code
        self.msg = msg
        self.data = data
    }
}
