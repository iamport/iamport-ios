//
// Created by BingBong on 2021/01/25.
//

import Foundation
import RxBus
import RxSwift
import Alamofire

class ChaiStrategy: BaseStrategy {

    var prepareData: PrepareData?
    var chaiId: String?

    /**
     * 간략한 시퀀스 설명
     * 1. IMP 서버에 유저 정보 요청해서 chai id 얻음 -> 결제 시퀀스 전 체크하는 것으로 수정함
     * 2. IMP 서버에 결제시작 요청 (+ chai id)
     * 3. chai 앱 실행
     * 4. 백그라운드 chai 서버 폴링
     * 5. if(차이폴링 approve) IMP 최종승인 요청
     */
    func doWork(_ pgId: String, _ payment: Payment) {
        super.doWork(payment)
        chaiId = pgId
        print("doWork! \(payment)")

        //TODO * 2. IMP 서버에 결제시작 요청 (+ chai id)

        let headers: HTTPHeaders = [
            "Content-Type": "application/json"
        ]
        let url = CONST.IAMPORT_PROD_URL + "/chai_payments/prepare"
        print(url)

        let prepareRequest = PrepareRequest.makeDictionary(chaiId: pgId, payment: payment)
        let doNetwork = Alamofire.request(url, method: .post, parameters: prepareRequest, encoding: JSONEncoding.default, headers: headers)
        print(doNetwork)
        doNetwork.responseJSON { [weak self] response in
            switch response.result {
            case .success(let data):
                do {
                    let dataJson = try JSONSerialization.data(withJSONObject: data, options: .prettyPrinted)
                    let getData = try JSONDecoder().decode(Prepare.self, from: dataJson)

                    guard getData.code == 0 else {
                        self?.failureFinish(payment: payment, msg: "code : \(getData.code), msg : \(String(describing: getData.msg))")
                        return
                    }

                    print(dataJson)
                    print(getData)
                    self?.processPrepare(getData.data)

                } catch {
                    self?.failureFinish(payment: payment, msg: "success but \(error.localizedDescription)")
                }
            case .failure(let error):
                self?.failureFinish(payment: payment, msg: "통신실패 \(error.localizedDescription)")
            }
        }
    }

    private func processPrepare(_ prepareData: PrepareData) {
        self.prepareData = prepareData

        // TODO 차이앱 띄우기 ㄱㄱ
        let queryItems = [
            URLQueryItem(name: "publicAPIKey", value: prepareData.publicAPIKey),
            URLQueryItem(name: "paymentId", value: prepareData.paymentId),
            URLQueryItem(name: "idempotencyKey", value: prepareData.idempotencyKey)]

        var openDeepLink = URLComponents(string: "chaipayment://payment")
        openDeepLink?.queryItems = queryItems
        print(openDeepLink)

        if let url = openDeepLink?.url {
            RxBus.shared.post(event: EventBus.MainEvents.ChaiUri(appAddress: url))
        }

    }

}
