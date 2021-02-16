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

    var timeOutTime: DispatchTime? //= DispatchTime.now()

    override func clear() {
        chaiId = nil
        prepareData = nil
        timeOutTime = nil
        super.clear()
    }

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

        //* 2. IMP 서버에 결제시작 요청 (+ chai id)

        let headers: HTTPHeaders = [
            "Content-Type": "application/json"
        ]
        let url = CONST.IAMPORT_PROD_URL + "/chai_payments/prepare"
        #if DEBUG
        print(url)
        #endif

        let prepareRequest = PrepareRequest.makeDictionary(chaiId: pgId, payment: payment)
        #if DEBUG
        print(prepareRequest)
        #endif

        let doNetwork = Network.alamoFireManager.request(url, method: .post, parameters: prepareRequest, encoding: JSONEncoding.default, headers: headers)
        #if DEBUG
        print(doNetwork)
        #endif
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

                    #if DEBUG
                    print(dataJson)
                    print(getData)
                    #endif

                    self?.processPrepare(getData.data)

                } catch {
                    self?.failureFinish(payment: payment, msg: "success but \(error.localizedDescription)")
                }
            case .failure(let error):
                self?.failureFinish(payment: payment, msg: "네트워크 연결실패 \(error.localizedDescription)")
            }
        }
    }


    func pollingChaiStatus() {
        guard let prepare = prepareData, let idempotencyKey = prepare.idempotencyKey,
              let publicAPIKey = prepareData?.publicAPIKey, let paymentId = prepareData?.paymentId else {
            print("prepareData 정보 찾을 수 없음")
            return
        }

        let headers: HTTPHeaders = [
            "Content-Type": "application/json",
            "Idempotency-Key": idempotencyKey,
            "public-API-Key": publicAPIKey
        ]
        let url = CONST.CHAI_SERVICE_URL + "/v1/payment/\(paymentId)"
        #if DEBUG
        print(url)
        #endif

        let doNetwork = Network.alamoFireManager.request(url, method: .get, encoding: JSONEncoding.default, headers: headers)

        doNetwork.responseJSON { [weak self] response in

            guard let payment = self?.payment, let prepareData = self?.prepareData else {
                return
            }

            switch response.result {
            case .success(let data):
                do {
                    let dataJson = try JSONSerialization.data(withJSONObject: data, options: .prettyPrinted)
                    let getData = try JSONDecoder().decode(ChaiPayment.self, from: dataJson)
                    #if DEBUG
                    dump(getData)
                    #endif

                    if let status = ChaiPaymentStatus.from(displayStatus: getData.displayStatus) {
                        switch status {
                        case .approved:
                            print("결제승인! \(status.rawValue)")
                            self?.confirmMerchant(payment: payment, prepareData: prepareData)

                        case .confirmed:
                            self?.successFinish(payment: payment, prepareData: prepareData, msg: "가맹점 측 결제 승인 완료 (결제 성공) \(status.rawValue)")

                        case .partial_confirmed:
                            self?.successFinish(payment: payment, prepareData: prepareData, msg: "부분 취소된 결제 \(status.rawValue)")

                        case .waiting, .prepared:
                            self?.tryPolling()

                        case .user_canceled, .canceled, .failed, .timeout:
                            print("결제취소 \(status.rawValue)")
                            self?.failureFinish(payment: payment, prepareData: prepareData, msg: "결제취소 \(status.rawValue)")
                        }
                    }
                } catch {
                    self?.failureFinish(payment: payment, msg: "success but \(error.localizedDescription)")
                }
            case .failure(let error):
//                self?.failureFinish(payment: payment, msgC: "통신실패 \(error.localizedDescription)")
                print("네트워크 통신실패로 인한 폴링 시도!!")
                self?.tryPolling()
            }
        }
    }

    private func tryPolling() {
        if (isTimeOut()) {
            guard let payment = payment, let prepareData = prepareData else {
                print("isTimeOut 이나, payment : \(self.payment), prepareData : \(self.prepareData)")
                sdkFinish(nil)
                return
            }

            failureFinish(payment: payment, prepareData: prepareData, msg: "I'mport : 타임아웃으로 인해 결제를 진행하지 않습니다")
            return
        }

        Utils.delay(bySeconds: Double(CONST.POLLING_DELAY), dispatchLevel: .userInteractive) {
            print("폴링!!")
            self.pollingChaiStatus()
        }
    }

    func isTimeOut() -> Bool {
        if let timeOut = timeOutTime {
            #if DEBUG
            print("now time \(DispatchTime.now()) : timeout \(timeOut)")
            #endif
            return DispatchTime.now() >= timeOut
        }
        return true
    }


    private func confirmMerchant(payment: Payment, prepareData: PrepareData) {

        let approve = IamPortApprove.make(payment: payment, prepareData: prepareData)
        // TODO 머천트의 approve 체크

        requestApprovePayments(approve: approve)
    }

    private func requestApprovePayments(approve: IamPortApprove) {

//        let headers: HTTPHeaders = [
//            "Content-Type": "application/json",
//            "Idempotency-Key": idempotencyKey,
//            "public-API-Key": publicAPIKey
//        ]
//        let url = CONST.CHAI_SERVICE_URL + "/v1/payment/\(paymentId)"
//        print(url)
//
//        let doNetwork = Network.alamoFireManager.request(url, method: .get, encoding: JSONEncoding.default, headers: headers)
//
//        doNetwork.responseJSON { [weak self] response in
//
//        }

        // TODO 최종결제 승인요청
        processApprovePayments(approve: approve)
    }

    private func processApprovePayments(approve: IamPortApprove) {
        print("결제 최종 승인 요청~~~")

        let headers: HTTPHeaders = ["Content-Type": "application/json"]
        guard let idempotencyKey = approve.idempotencyKey else {
            print("idempotencyKey 를 찾을 수 없음")
            return
        }

        let getUrl = CONST.IAMPORT_PROD_URL + "/chai_payments/result/\(approve.userCode)/\(idempotencyKey)"

        let queryItems = [
            URLQueryItem(name: CHAI.PAYMENT_ID, value: approve.paymentId),
            URLQueryItem(name: CHAI.IDEMPOENCY_KEY, value: idempotencyKey),
            URLQueryItem(name: CHAI.STATUS, value: ChaiPaymentStatus.approved.rawValue),
            URLQueryItem(name: CHAI.NATIVE, value: OS.ios.rawValue), ]

        var urlComponents = URLComponents(string: getUrl)
        urlComponents?.queryItems = queryItems

        guard let url = urlComponents?.url else {
            print("urlComponents 에서 url 을 찾을 수 없음")
            return
        }

        print(urlComponents?.url)

        let doNetwork = Network.alamoFireManager.request(url, method: .get, encoding: JSONEncoding.default, headers: headers)
        print(doNetwork)

        doNetwork.responseJSON { [weak self] response in
            guard let payment = self?.payment, let prepareData = self?.prepareData else {
                print("payment :: \(self?.payment), prepareData :: \(self?.prepareData)")
                return
            }

            switch response.result {
            case .success(let data):
                do {
                    let dataJson = try JSONSerialization.data(withJSONObject: data, options: .prettyPrinted)
                    #if DEBUG
                    print(dataJson)
                    #endif
                    let getData = try JSONDecoder().decode(Approve.self, from: dataJson)
                    #if DEBUG
                    dump(getData)
                    #endif

                    guard getData.code == 0 else {
                        self?.failureFinish(payment: payment, prepareData: prepareData, msg: "결제실패 \(String(describing: approve.msg))")
                        return
                    }

                    self?.successFinish(payment: payment, prepareData: prepareData, msg: "결제성공")

                } catch {
                    self?.failureFinish(payment: payment, prepareData: prepareData, msg: "결제콜백")
                }
            case .failure(let error):
                self?.failureFinish(payment: payment, prepareData: prepareData, msg: "결제실패 \(error.localizedDescription)")
            }
        }
    }

    private func processPrepare(_ prepareData: PrepareData) {
        self.prepareData = prepareData

        let queryItems = [
            URLQueryItem(name: "publicAPIKey", value: prepareData.publicAPIKey),
            URLQueryItem(name: "paymentId", value: prepareData.paymentId),
            URLQueryItem(name: "idempotencyKey", value: prepareData.idempotencyKey)]

        var openDeepLink = URLComponents(string: "chaipayment://payment")
        openDeepLink?.queryItems = queryItems
        #if DEBUG
        print(openDeepLink)
        #endif

        if let url = openDeepLink?.url {
            RxBus.shared.post(event: EventBus.MainEvents.ChaiUri(appAddress: url))
        }

        timeOutTime = DispatchTime.now() + Double(CONST.TIME_OUT)
        #if DEBUG
        print("set timeOutTime \(timeOutTime)")
        #endif
        pollingChaiStatus()
    }

}
