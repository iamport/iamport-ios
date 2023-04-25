//
// Created by BingBong on 2021/01/07.
//

import Foundation
import Then

public class IamportResponse: Encodable, Then {
    public var success: Bool? = false
    public var imp_uid: String?
    public var merchant_uid: String?
    public var error_msg: String?
    public var error_code: String?

    static func structToClass(_ impStruct: IamportResponseStruct) -> IamportResponse {
        IamportResponse().then { it in
            it.success = impStruct.success
            it.imp_uid = impStruct.imp_uid
            it.merchant_uid = impStruct.merchant_uid
            it.error_msg = impStruct.error_msg
            it.error_code = impStruct.error_code
        }
    }

    static func makeSuccess(request: IamportRequest, prepareData: PrepareData? = nil, msg: String) -> IamportResponse {
        IamportResponse().then { it in
            it.success = true
            it.imp_uid = prepareData?.impUid
            it.merchant_uid = request.getMerchantUid()
            it.error_msg = msg
        }
    }

    static func makeFail(request: IamportRequest, prepareData: PrepareData? = nil, msg: String) -> IamportResponse {
        IamportResponse().then { it in
            it.success = false
            it.imp_uid = prepareData?.impUid
            it.merchant_uid = request.getMerchantUid()
            it.error_msg = msg
        }
    }
}

extension IamportResponse: CustomStringConvertible {
    public var description: String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let jsonData = try? encoder.encode(self)
        if let json = jsonData, let responseJson = String(data: json, encoding: .utf8) {
            return responseJson
        } else {
            return """
            IamportResponse ::
                success: \(String(describing: success))
                imp_uid: \(String(describing: imp_uid))
                merchant_uid : \(String(describing: merchant_uid))
                error_msg: \(String(describing: error_msg))
                error_code: \(String(describing: error_code)))
            """
        }
    }
}

public struct IamportResponseStruct {
    var success: Bool? = false
    var imp_uid: String?
    var merchant_uid: String?
    var error_msg: String? = nil
    var error_code: String? = nil

    enum CodingKeys: String, CodingKey {
        case imp_success
        case success
        case imp_uid
        case merchant_uid
        case error_msg
        case error_code
        case txId // v1 imp_uid
        case paymentId // v1 merchant_uid
        case code // v1 error_code
        case message // v1 error_msg
    }
}

extension IamportResponseStruct: Decodable {
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        imp_uid = (try? values.decode(String.self, forKey: .imp_uid)) ?? (try? values.decode(String.self, forKey: .txId))
        merchant_uid = (try? values.decode(String.self, forKey: .merchant_uid)) ?? (try? values.decode(String.self, forKey: .paymentId))
        error_code = (try? values.decode(String.self, forKey: .error_code)) ?? (try? values.decode(String.self, forKey: .code))
        error_msg = (try? values.decode(String.self, forKey: .error_msg)) ?? (try? values.decode(String.self, forKey: .message))
        guard let decodedSuccess = (try? values.decode(String.self, forKey: .imp_success)) ?? (try? values.decode(String.self, forKey: .success)) else {
            success = (error_code == nil)
            return
        }
        success = Bool(decodedSuccess)
    }
}
