//
// Created by BingBong on 2021/01/07.
//

import Foundation
import Then

struct Payment: Codable, Then {
    let userCode: String
    var iamPortRequest: IamPortRequest

    init(userCode: String, iamPortRequest: IamPortRequest) {
        self.userCode = userCode
        self.iamPortRequest = iamPortRequest
    }
}
