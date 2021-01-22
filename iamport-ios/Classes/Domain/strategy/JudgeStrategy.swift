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
        case CHAI, WEB, EMPTY
    }

    override func doWork(_ payment: Payment) {

        let url = CONST.IAMPORT_PROD_URL + "/users/pg/\(payment.userCode)"
        print(url)
        let headers: HTTPHeaders = [
            "Content-Type": "varlication/json"
        ]
        let doNetwork = Alamofire.request(url, method: .get, encoding: JSONEncoding.default, headers: headers)

        doNetwork.responseJSON { [weak self] response in
            switch response.result {
            case .success(let data):
                do {
                    let dataJson = try JSONSerialization.data(withJSONObject: data, options: .prettyPrinted)
                    let getData = try JSONDecoder().decode(Users.self, from: dataJson)
                    print(getData)

                    // TODO judge 처리
                    guard getData.code == 0 else {
                        self?.failureFinish(payment: payment, msg: "code : \(getData.code), msg : \(String(describing: getData.msg))")
                        return
                    }

                    self?.judge(payment, getData.data)
                } catch {
                    self?.failureFinish(payment: payment, msg: "success but \(error.localizedDescription)")
                }
            case .failure(let error):
                self?.failureFinish(payment: payment, msg: "통신실패 \(error.localizedDescription)")
            }
        }
    }

    // -> (JudgeKinds, UserData?, Payment)
    private func judge(_ payment: Payment, _ userDataList: Array<UserData>) -> (JudgeKinds, UserData?, Payment) {

        guard !userDataList.isEmpty else {
            failureFinish(payment: payment, msg: "Not found PF [ \(payment.iamPortRequest.pg) ] and any PG in your info.")
            // -> (JudgeKinds, UserData?, Payment)
            // Triple(JudgeKinds.EMPTY, null, payment)
            return (JudgeKinds.EMPTY, nil, payment)
        }

        guard let defUser = findDefaultUserData(userDataList) else {
            failureFinish(payment: payment, msg: "Not found Default PG. All PG empty.")
            // -> (JudgeKinds, UserData?, Payment)
            // Triple(JudgeKinds.EMPTY, null, payment)
            return (JudgeKinds.EMPTY, nil, payment)
        }

        print("userDataList :: \(userDataList)")
        let myPg = String(payment.iamPortRequest.pg.split(separator: ".")[0])
        let findPg = userDataList.first { data in
            data.pg_provider?.getPgSting() == myPg
        }

        let result: (JudgeKinds, UserData?, Payment)
        switch findPg {
        case .none:
            result = getPgTriple(user: defUser, payment: replacePG(pg: defUser.pg_provider!, payment: payment))
        case .some(let pg):
            result = getPgTriple(user: pg, payment: payment)
        }
        print(result)
        return result
    }


    private func findDefaultUserData(_ userDataList: Array<UserData>) -> UserData? {
        userDataList.first { data in
            data.pg_provider != nil
        }
    }


    /**
     * pg 정보 값 가져옴 first : 타입, second : pg유저, third : 결제 요청 데이터
     */
    private func getPgTriple(user: UserData, payment: Payment) -> (JudgeKinds, UserData?, Payment) {
        if let pgProvider = user.pg_provider {
            switch pgProvider {
            case .chai:
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
        let iamPortRequest = payment.iamPortRequest.with {
            $0.pg = pg.getPgSting()
        }
        return payment.with {
            $0.iamPortRequest = iamPortRequest
        }
    }

}
