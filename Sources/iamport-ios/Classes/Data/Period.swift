//
// Created by BingBong on 2022/09/27.
//

import Foundation


// 이니시스 정기결제 제공기간 옵션
// 참조 : https://guide.iamport.kr/32498112-82c4-44cb-a23a-ef5b896ee548
public class Period: Codable {
    var from: String // YYYYMMDD
    var to: String // YYYYMMDD
    public init(from: String, to: String)  {
        self.from = from
        self.to = to
    }
}
