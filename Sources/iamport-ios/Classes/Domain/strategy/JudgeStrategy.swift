//
// Created by BingBong on 2021/01/08.
//

import Alamofire
import Foundation
import RxBusForPort
import RxSwift

public class JudgeStrategy: BaseStrategy {
    // 유저 정보 판단 결과 타입
    enum JudgeKind {
        case CHAI, WEB, CERT, ERROR
    }
    var ignoreNative = false
    override init(eventBus: EventBus) {
        super.init(eventBus: eventBus)
    }
    func doWork(_ request: IamportRequest, ignoreNative: Bool) {
        self.ignoreNative = ignoreNative
        doWork(request)
    }

    override func doWork(_ request: IamportRequest) {
        super.doWork(request)

        let headers: HTTPHeaders = ["Content-Type": "application/json"]
        let url = Constant.IAMPORT_PROD_URL + "/users/pg/\(request.userCode)"
        print(url)

        let doNetwork = Network.alamoFireManagerShortTimeOut.request(url, method: .get, encoding: JSONEncoding.default, headers: headers)
        doNetwork.responseJSON { [weak self] response in
            switch response.result {
            case let .success(data):
                do {
                    debug_log(data)
                    let dataJson = try JSONSerialization.data(withJSONObject: data, options: .prettyPrinted)
                    let getData = try JSONDecoder().decode(Users.self, from: dataJson)

                    guard getData.code == 0 else {
                        self?.failure(request: request, msg: "code : \(getData.code), msg : \(String(describing: getData.msg))")
                        return
                    }

                    // 통신 결과로 판단시작
                    if let result = self?.judge(request, getData.data) {
                        // 결과 전송
                        RxBus.shared.post(event: EventBus.MainEvents.JudgeEvent(judge: result))
                    }
                } catch {
                    self?.failure(request: request, msg: "success but \(error.localizedDescription)")
                }
            case let .failure(error):
                self?.failure(request: request, msg: "네트워크 연결실패 \(error.localizedDescription)")
            }
        }
    }

    private func judge(_ request: IamportRequest, _ userDataList: [UserData]) -> (JudgeKind, UserData?, IamportRequest) {
        guard !userDataList.isEmpty else {
            failure(request: request, msg: "User data list is empty")
            return (JudgeKind.ERROR, nil, request)
        }
        debug_log("userDataList :: \(userDataList)")

        // 1. 본인인증의 경우 판단 (현재 있는지 없는지만 판단)
        if request.isCertification {
            guard let defCertUser = (userDataList.first { data in
                data.pg_provider != nil && data.type == Constant.USER_TYPE_CERTIFICATION
            }) else {
                failure(request: request, msg: "본인인증 설정 또는 가입을 먼저 해주세요.")
                return (JudgeKind.ERROR, nil, request)
            }

            return (JudgeKind.CERT, defCertUser, request)
        }

        // 2. 결제요청의 경우 판단
        guard let defPaymentUser = findDefaultUserData(userDataList) else {
            failure(request: request, msg: "Not found Default PG. All PG empty.")
            return (JudgeKind.ERROR, nil, request)
        }

        guard case let .payment(payment) = request.payload else {
            failure(request: request, msg: "Not found My PG.")
            return (JudgeKind.ERROR, nil, request)
        }

        let split = payment.pg.split(separator: ".")

        let myPg = String(split[0])
        var findPg: UserData?

        if split.count > 1 {
            let pgId = String(split[1])
            findPg = userDataList.first { data in
                data.pg_provider == myPg && data.pg_id == pgId
            }
        } else {
            findPg = userDataList.first { data in
                data.pg_provider == myPg
            }
        }

        debug_log("findPg \(String(describing: findPg))")

        let result: (JudgeKind, UserData?, IamportRequest)
        switch findPg {
        case .none:
            guard let pg_provider = defPaymentUser.pg_provider,
                  let pg = PG.convertPG(pgString: pg_provider)
            else {
                failure(request: request, msg: "Not found defPaymentUser pg_provider")
                return (JudgeKind.ERROR, nil, request)
            }

            result = getPgTriple(user: defPaymentUser, request: replacePG(pg: pg, request: request))
        case let .some(pg):
            result = getPgTriple(user: pg, request: request)
        }

        return result
    }

    private func findDefaultUserData(_ userDataList: [UserData]) -> UserData? {
        userDataList.first { data in
            data.pg_provider != nil && data.type == Constant.USER_TYPE_PAYMENT
        }
    }

    /**
     * pg 정보 값 가져옴 first : 타입, second : pg유저, third : 결제 요청 데이터
     */
    private func getPgTriple(user: UserData, request: IamportRequest) -> (JudgeKind, UserData?, IamportRequest) {
        if let pgProvider = user.pg_provider, let pg = PG.convertPG(pgString: pgProvider) {
            switch pg {
            case .chai:
                if ignoreNative { // ignoreNative 인 경우 webview strategy 가 동작하기 위하여
                    return (JudgeKind.WEB, user, request)
                }
                return (JudgeKind.CHAI, user, request)

            default:
                return (JudgeKind.WEB, user, request)
            }
        } else {
            return (JudgeKind.WEB, user, request)
        }
    }

    /**
     * payment PG 를 default PG 로 수정함
     */
    private func replacePG(pg: PG, request: IamportRequest) -> IamportRequest {
        guard case let .payment(payment) = request.payload else { return request }
        return request.with {
            $0.payload = .payment(payment.with {
                $0.pg = pg.makePgRawName()
            })
        }
    }
}
