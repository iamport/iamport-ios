//
// Created by BingBong on 2021/01/20.
//

import Foundation
import Then

struct UserData: Codable, Then {
    var pg_provider: PG? // TODO: 2020-12-15 015 nullable 로 오는데.. 확인필요..
    var pg_id: String
    var sandbox: Bool
    var type: String

    public init(pg_id: String, sandbox: Bool, type: String) {
        self.pg_id = pg_id
        self.sandbox = sandbox
        self.type = type
    }
}
