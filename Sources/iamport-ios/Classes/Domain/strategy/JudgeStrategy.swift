//
// Created by BingBong on 2021/01/08.
//

import Foundation
import RxBus
import RxSwift
import Alamofire

public class JudgeStrategy: BaseStrategy {

    // 유저 정보 판단 결과 타입
    enum JudgeKinds {
        case CHAI, WEB, CERT, ERROR
    }

    var ignoreNative = false

    func doWork(_ payment: Payment, ignoreNative: Bool) {
        self.ignoreNative = ignoreNative
        doWork(payment)
    }

    override func doWork(_ payment: Payment) {
        super.doWork(payment)

        let headers: HTTPHeaders = ["Content-Type": "application/json"]
        let url = CONST.IAMPORT_PROD_URL + "/users/pg/\(payment.userCode)"
        print(url)

        let doNetwork = Network.alamoFireManagerShortTimeOut.request(url, method: .get, encoding: JSONEncoding.default, headers: headers)
        doNetwork.responseJSON { [weak self] response in
            switch response.result {
            case .success(let data):
                do {
                    dlog(data)
                    let dataJson = try JSONSerialization.data(withJSONObject: data, options: .prettyPrinted)
                    let getData = try JSONDecoder().decode(Users.self, from: dataJson)

                    guard getData.code == 0 else {
                        self?.failureFinish(payment: payment, msg: "code : \(getData.code), msg : \(String(describing: getData.msg))")
                        return
                    }

                    // 통신 결과로 판단시작
                    if let result = self?.judge(payment, getData.data) {
                        // 결과 전송
                        RxBus.shared.post(event: EventBus.MainEvents.JudgeEvent(judge: result))
                    }
                } catch {
                    self?.failureFinish(payment: payment, msg: "success but \(error.localizedDescription)")
                }
            case .failure(let error):
                self?.failureFinish(payment: payment, msg: "네트워크 연결실패 \(error.localizedDescription)")
            }
        }
    }

    private func judge(_ payment: Payment, _ userDataList: Array<UserData>) -> (JudgeKinds, UserData?, Payment) {

        guard !userDataList.isEmpty else {
            failureFinish(payment: payment, msg: "Not found PG [ \(String(describing: payment.iamPortRequest?.pg)) ] and any PG in your info.")
            return (JudgeKinds.ERROR, nil, payment)
        }
        dlog("userDataList :: \(userDataList)")

        // 1. 본인인증의 경우 판단 (현재 있는지 없는지만 판단)
        if (payment.isCertification()) {
            guard let defCertUser = (userDataList.first { data in
                data.pg_provider != nil && data.type == CONST.USER_TYPE_CERTIFICATION
            }) else {
                failureFinish(payment: payment, msg: "본인인증 설정 또는 가입을 먼저 해주세요.")
                return (JudgeKinds.ERROR, nil, payment)
            }

            return (JudgeKinds.CERT, defCertUser, payment)
        }

        // 2. 결제요청의 경우 판단
        guard let defPaymentUser = findDefaultUserData(userDataList) else {
            failureFinish(payment: payment, msg: "Not found Default PG. All PG empty.")
            return (JudgeKinds.ERROR, nil, payment)
        }

        guard let split = payment.iamPortRequest?.pg.split(separator: ".") else {
            failureFinish(payment: payment, msg: "Not found My PG.")
            return (JudgeKinds.ERROR, nil, payment)
        }

        let myPg = String(split[0])
        var findPg: UserData?

        if (split.count > 1) {
            let pgId = String(split[1])
            findPg = userDataList.first { data in
                data.pg_provider == myPg && data.pg_id == pgId
            }
        } else {
            findPg = userDataList.first { data in
                data.pg_provider == myPg
            }
        }

        dlog("findPg \(String(describing: findPg))")

        let result: (JudgeKinds, UserData?, Payment)
        switch findPg {
        case .none:
            guard let pg_provider = defPaymentUser.pg_provider,
                  let pg = PG.convertPG(pgString: pg_provider) else {
                failureFinish(payment: payment, msg: "Not found defPaymentUser pg_provider")
                return (JudgeKinds.ERROR, nil, payment)
            }

            result = getPgTriple(user: defPaymentUser, payment: replacePG(pg: pg, payment: payment))
        case .some(let pg):
            result = getPgTriple(user: pg, payment: payment)
        }

        return result
    }


    private func findDefaultUserData(_ userDataList: Array<UserData>) -> UserData? {
        userDataList.first { data in
            data.pg_provider != nil && data.type == CONST.USER_TYPE_PAYMENT
        }
    }


    /**
     * pg 정보 값 가져옴 first : 타입, second : pg유저, third : 결제 요청 데이터
     */
    private func getPgTriple(user: UserData, payment: Payment) -> (JudgeKinds, UserData?, Payment) {
        if let pgProvider = user.pg_provider, let pg = PG.convertPG(pgString: pgProvider) {
            switch pg {
            case .chai:
                if (ignoreNative) { // ignoreNative 인 경우 webview strategy 가 동작하기 위하여
                    return (JudgeKinds.WEB, user, payment)
                }
                return (JudgeKinds.CHAI, user, payment)

            default:
                return (JudgeKinds.WEB, user, payment)
            }
        } else {
            return (JudgeKinds.WEB, user, payment)
        }
    }

    /**
     * payment PG 를 default PG 로 수정함
     */
    private func replacePG(pg: PG, payment: Payment) -> Payment {
        let iamPortRequest = payment.iamPortRequest?.with {
            $0.pg = pg.makePgRawName()
        }
        return payment.with {
            $0.iamPortRequest = iamPortRequest
        }
    }

}
