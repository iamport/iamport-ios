//
// Created by BingBong on 2021/01/20.
//

import Foundation
import Then

// PG정보가 없어도(회원가입 후 즉시 or PG 를 API 방식으로만 이용하는 경우 or 본인인증만 이용하는 경우) 에도
// pg_id 가 null 로 해당 데이터가 하나는 무조건 있으므로 다 nullable 처리한다 ㅠ
struct UserData: Codable, Then {
    var pg_provider: String?
    var pg_id: String?
    var sandbox: Bool?
    var type: String?

    public init(pg_id: String, sandbox: Bool, type: String) {
        self.pg_id = pg_id
        self.sandbox = sandbox
        self.type = type
    }
}
