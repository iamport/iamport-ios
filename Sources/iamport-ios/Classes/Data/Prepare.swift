//
// Created by BingBong on 2021/01/25.
//

import Foundation
import Then

/*
 * code 값이 0이면 CHAI로 "결제등록"이 정상처리되었음을 의미합니다.
 * code 값이 0이 아니면 비정상적인 상황이므로 msg 속성을 통해 에러메세지가 전달됩니다.
 * msg 속성은 아임포트에서 가공한 메세지이므로,
 * CHAI로부터 내려온 오류메세지 원본을 사용하시려면 data.errorMsg 속성을 참고하시면 됩니다.
 * 참고로, data.errorCode 속성은 reserved 필드로 의미없습니다.
 */

struct Prepare: Codable, Then {
    var code: Int
    var msg: String
    var data: PrepareData

    public init(code: Int, msg: String, data: PrepareData) {
        self.code = code
        self.msg = msg
        self.data = data
    }
}

struct PrepareError: Codable, Then {
    var code: Int
    var msg: String
    var data: PrepareDataError

    public init(code: Int, msg: String, data: PrepareDataError) {
        self.code = code
        self.msg = msg
        self.data = data
    }
}
