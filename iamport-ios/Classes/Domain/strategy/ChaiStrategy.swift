//
// Created by BingBong on 2021/01/25.
//

import Foundation
import RxBus
import RxSwift
import Alamofire


// TODO API 들을 따로 모아서 관리하기
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

        let headers: HTTPHeaders = ["Content-Type": "application/json"]
        let url = CONST.IAMPORT_PROD_URL + "/chai_payments/prepare"
        dlog(url)


        let prepareRequest = PrepareRequest.makeDictionary(chaiId: pgId, payment: payment)
        dlog(prepareRequest ?? "not make prepareRequest")


        let doNetwork = Network.alamoFireManager.request(url, method: .post, parameters: prepareRequest, encoding: JSONEncoding.default, headers: headers)
        dlog(doNetwork)

        doNetwork.responseJSON { [weak self] response in
            switch response.result {
            case .success(let data):
                do {
                    dlog(data)
                    let dataJson = try JSONSerialization.data(withJSONObject: data, options: .prettyPrinted)
                    dlog(dataJson)
                    let getData = try JSONDecoder().decode(Prepare.self, from: dataJson)

                    guard getData.code == 0 else {
                        self?.failureFinish(payment: payment, msg: "code : \(getData.code), msg : \(String(describing: getData.msg))")
                        return
                    }
                    dlog(getData)

                    self?.processPrepare(getData.data)

                } catch {
                    self?.failureFinish(payment: payment, msg: "success but \(error.localizedDescription)")
                }
            case .failure(let error):
                self?.failureFinish(payment: payment, msg: "네트워크 연결실패 \(error.localizedDescription)")
            }
        }
    }

    private func getChaiStatusUrl(_ prepareData: PrepareData) -> String {

        guard let mode = prepareData.mode else {
            print("getChaiStatusUrl :: mode 가 없습니다")
            return CONST.EMPTY_STR
        }

        let url = "\(CHAI_MODE.getChaiUrl(mode: mode))/v1/payment"
        if (isSubscription(prepareData: prepareData)) {

            guard let subscriptionId = prepareData.subscriptionId else {
                print("getChaiStatusUrl :: subscriptionId 가 없습니다")
                return CONST.EMPTY_STR
            }
            // 정기결제 상황~~
            return "\(url)/subscription/\(subscriptionId)"
        }

        guard let paymentId = prepareData.paymentId else {
            print("getChaiStatusUrl :: paymentId 가 없습니다")
            return CONST.EMPTY_STR
        }
        // 일반결제~
        return "\(url)/\(paymentId)"
    }

    private func getDisplayStatus(payment: Payment, prepareData: PrepareData, dataJson: Data) -> String? {
        do {
            if (isSubscription(prepareData: prepareData)) {
                let getData = try JSONDecoder().decode(ChaiPaymentSubscription.self, from: dataJson)
                ddump(getData)
                return getData.displayStatus
            }

            let getData = try JSONDecoder().decode(ChaiPayment.self, from: dataJson)
            ddump(getData)
            return getData.displayStatus
        } catch {
            failureFinish(payment: payment, msg: "success but \(error.localizedDescription)")
            return nil
        }
    }

    func checkRemoteChaiStatus() {

        guard let prepare = prepareData,
              prepare.subscriptionId != nil || prepare.paymentId != nil else {
            print("prepareData 정보 찾을 수 없음")
            return
        }

        let headers: HTTPHeaders = [
            "Content-Type": "application/json",
            "Idempotency-Key": prepare.idempotencyKey,
            "public-API-Key": prepare.publicAPIKey
        ]

        // GET CHAI 일반결제 or 정기결제에 따라 api url 을 달리 가져옴
        let url = getChaiStatusUrl(prepare)
        dlog(url)

        let doNetwork = Network.alamoFireManager.request(url, method: .get, encoding: JSONEncoding.default, headers: headers)

        doNetwork.responseJSON { [weak self] response in

            guard let payment = self?.payment, let prepareData = self?.prepareData else {
                return
            }

            switch response.result {
            case .success(let data):
                do {
                    dlog(data)
                    let dataJson = try JSONSerialization.data(withJSONObject: data, options: .prettyPrinted)

                    // CHAI 일반결제 or 정기결제에 따라 response data parsing 후 displayStatus 를 가져옴
                    let displayStatus = self?.getDisplayStatus(payment: payment, prepareData: prepareData, dataJson: dataJson)

                    if let status = ChaiPaymentStatus.from(displayStatus: displayStatus ?? CONST.EMPTY_STR) {
                        switch status {
                        case .approved:
                            print("결제승인! \(status.rawValue)")
                            self?.confirmMerchant(payment: payment, prepareData: prepareData, status: status)

                        case .confirmed:
                            self?.successFinish(payment: payment, prepareData: prepareData, msg: "가맹점 측 결제 승인 완료 (결제 성공) \(status.rawValue)")

                        case .partial_confirmed:
                            self?.successFinish(payment: payment, prepareData: prepareData, msg: "부분 취소된 결제 \(status.rawValue)")

                        case .waiting, .prepared:
                            self?.tryPolling()

                        case .user_canceled, .canceled, .failed, .timeout, .inactive, .churn:
                            print("결제취소 \(status.rawValue)")
//                            self?.failureFinish(payment: payment, prepareData: prepareData, msg: "결제취소 \(status.rawValue)")
                            IamPortApprove.make(payment: payment, prepareData: prepareData, status: status).do {
                                self?.requestApprovePayments(approve: $0)
                            }

                        }
                    }
                } catch {
                    self?.failureFinish(payment: payment, msg: "success but \(error.localizedDescription)")
                }
            case .failure(let error):
//                self?.failureFinish(payment: payment, msgC: "통신실패 \(error.localizedDescription)")
                print("네트워크 통신실패로 인한 폴링 시도!! \(error.localizedDescription)")
                self?.tryPolling()
            }
        }
    }

    private func tryPolling() {
        if (isTimeOut()) {
            guard let payment = payment, let prepareData = prepareData else {
                print("isTimeOut 이나, payment : \(self.payment), prepareData : \(self.prepareData)")
//                sdkFinish(nil)
                clear()
                return
            }

//            failureFinish(payment: payment, prepareData: prepareData, msg: "I'mport : 타임아웃으로 인해 결제를 진행하지 않습니다")
            print("[\(CONST.TIME_OUT_MIN)] 분 이상 결제되지 않아 미결제 처리합니다. 결제를 재시도 해주세요.")
            clear()
            return
        }

        Utils.delay(bySeconds: Double(CONST.POLLING_DELAY), dispatchLevel: .userInteractive) {
            print("폴링!!")
            self.checkRemoteChaiStatus()
        }
    }

    func isTimeOut() -> Bool {
        if let timeOut = timeOutTime {
            dlog("now time \(DispatchTime.now()) : timeout \(timeOut)")
            return DispatchTime.now() >= timeOut
        }
        return true
    }


    private func confirmMerchant(payment: Payment, prepareData: PrepareData, status: ChaiPaymentStatus) {

        IamPortApprove.make(payment: payment, prepareData: prepareData, status: status).do {
            RxBus.shared.post(event: EventBus.MainEvents.AskApproveFromChai(approve: $0))
        }

        Utils.delay(bySeconds: Double(CONST.CHAI_FINAL_PAYMENT_TIME_OUT_SEC), dispatchLevel: .userInteractive) {
            print("최종 결제 타임아웃! over \(CONST.CHAI_FINAL_PAYMENT_TIME_OUT_SEC) sec")
            self.clear()
        }
    }


    private func isSubscription(prepareData: PrepareData) -> Bool {
        guard prepareData.subscriptionId == nil else {
            return true
        }
        return false
    }

    private func isSubscription(approve: IamPortApprove) -> Bool {
        guard approve.subscriptionId == nil else {
            return true
        }
        return false
    }

//    /**
//     * 현재 결제중인 데이터와 머천트앱으로부터 전달받은 데이터가 동일한가 비교
//     */
//    private func matchApproveData(approve: IamPortApprove) -> Bool {
//        payment?.userCode == approve.userCode
//                && payment?.getMerchantUid() == approve.merchantUid
//                && payment?.getCustomerUid() == approve.customerUid
//                && prepareData?.paymentId == approve.paymentId
//                && prepareData?.subscriptionId == approve.subscriptionId
//                && prepareData?.impUid == approve.impUid
//                && prepareData?.idempotencyKey == approve.idempotencyKey
//                && prepareData?.publicAPIKey == approve.publicAPIKey
//    }

    func requestApprovePayments(approve: IamPortApprove) {

// 어차피 밖에서 수정하지 못함
//        if (!matchApproveData(approve: approve)) {
//            print("결제 데이터 매칭 실패로 최종결제하지 않습니다.")
//            dlog("상세정보\n payment :: \(payment) \n prepareData :: \(prepareData) \n approve :: \(approve)")
//            return
//        }

        if (isSubscription(approve: approve)) {
            processApprovePaymentsSubscription(approve: approve)
            return
        }

        processApprovePayments(approve: approve)
    }

    private func processApprovePayments(approve: IamPortApprove) {
        print("일반결제 최종 승인 요청")

        let headers: HTTPHeaders = ["Content-Type": "application/json"]

        guard let paymentId = approve.paymentId else {
            print("paymentId 를 찾을 수 없음")
            return
        }

        let getUrl = CONST.IAMPORT_PROD_URL + "/chai_payments/result/\(approve.userCode)/\(approve.idempotencyKey)"

        let queryItems = [
            URLQueryItem(name: CHAI.PAYMENT_ID, value: paymentId),
            URLQueryItem(name: CHAI.IDEMPOTENCY_KEY, value: approve.idempotencyKey),
            URLQueryItem(name: CHAI.STATUS, value: ChaiPaymentStatus.from(displayStatus: approve.status)?.rawValue),
            URLQueryItem(name: CHAI.NATIVE, value: OS.ios.rawValue), ]

        var urlComponents = URLComponents(string: getUrl)
        urlComponents?.queryItems = queryItems

        guard let url = urlComponents?.url else {
            print("urlComponents 에서 url 을 찾을 수 없음")
            return
        }

        dlog(url)

        let doNetwork = Network.alamoFireManager.request(url, method: .get, encoding: JSONEncoding.default, headers: headers)
        dlog(doNetwork)

        doNetwork.responseJSON { [weak self] response in
            guard let payment = self?.payment, let prepareData = self?.prepareData else {
                print("payment :: \(String(describing: self?.payment)), prepareData :: \(String(describing: self?.prepareData))")
                return
            }

            switch response.result {
            case .success(let data):
                do {

                    let dataJson = try JSONSerialization.data(withJSONObject: data, options: .prettyPrinted)
                    dlog(dataJson)

                    let getData = try JSONDecoder().decode(Approve.self, from: dataJson)
                    ddump(getData)

                    guard getData.code == 0 else {
                        self?.failureFinish(payment: payment, prepareData: prepareData, msg: "결제실패 :: \(getData.msg)")
                        return
                    }

                    self?.successFinish(payment: payment, prepareData: prepareData, msg: "결제성공")

                } catch {
                    self?.failureFinish(payment: payment, prepareData: prepareData, msg: "결제콜백")
                }
            case .failure(let error):
                self?.failureFinish(payment: payment, prepareData: prepareData, msg: "네트워크 통신오류로 인한 최종결제 실패 :: \(error.localizedDescription)")
            }
        }
    }

    private func processApprovePaymentsSubscription(approve: IamPortApprove) {
        print("정기결제 최종 승인 요청")

        let headers: HTTPHeaders = ["Content-Type": "application/json"]

        guard let customerUid = approve.customerUid else {
            print("customerUid 를 찾을 수 없음")
            return
        }

        guard let subscriptionId = approve.subscriptionId else {
            print("subscriptionId 를 찾을 수 없음")
            return
        }

        let getUrl = CONST.IAMPORT_PROD_URL + "/chai_payments/result/\(approve.userCode)/\(approve.idempotencyKey)/\(customerUid)"

        let queryItems = [
            URLQueryItem(name: CHAI.SUBSCRIPTION_ID, value: subscriptionId),
            URLQueryItem(name: CHAI.IDEMPOTENCY_KEY, value: approve.idempotencyKey),
//            URLQueryItem(name: CHAI.STATUS, value: ChaiPaymentStatus.approved.rawValue),
            URLQueryItem(name: CHAI.STATUS, value: ChaiPaymentStatus.from(displayStatus: approve.status)?.rawValue),
            URLQueryItem(name: CHAI.NATIVE, value: OS.ios.rawValue), ]

        var urlComponents = URLComponents(string: getUrl)
        urlComponents?.queryItems = queryItems

        guard let url = urlComponents?.url else {
            print("urlComponents 에서 url 을 찾을 수 없음")
            return
        }

        dlog(url)

        let doNetwork = Network.alamoFireManager.request(url, method: .get, encoding: JSONEncoding.default, headers: headers)
        dlog(doNetwork)

        doNetwork.responseJSON { [weak self] response in
            guard let payment = self?.payment, let prepareData = self?.prepareData else {
                print("payment :: \(String(describing: self?.payment)), prepareData :: \(String(describing: self?.prepareData))")
                return
            }

            switch response.result {
            case .success(let data):
                do {

                    let dataJson = try JSONSerialization.data(withJSONObject: data, options: .prettyPrinted)
                    dlog(dataJson)

                    let getData = try JSONDecoder().decode(Approve.self, from: dataJson)
                    ddump(getData)

                    guard getData.code == 0 else {
                        self?.failureFinish(payment: payment, prepareData: prepareData, msg: "결제실패 :: \(getData.msg)")
                        return
                    }

                    self?.successFinish(payment: payment, prepareData: prepareData, msg: "결제성공")

                } catch {
                    self?.failureFinish(payment: payment, prepareData: prepareData, msg: "결제콜백")
                }
            case .failure(let error):
                self?.failureFinish(payment: payment, prepareData: prepareData, msg: "네트워크 통신오류로 인한 최종결제 실패 :: \(error.localizedDescription)")
            }
        }
    }

    private func processPrepare(_ prepareData: PrepareData) {

        guard prepareData.subscriptionId != nil || prepareData.paymentId != nil else {
            guard let payment = payment else {
                print("processPrepare :: payment is null")
                return
            }

            let errMsg = "subscriptionId & paymentId 모두 값이 없습니다."
            print(errMsg)
            failureFinish(payment: payment, msg: errMsg)
            return
        }

        self.prepareData = prepareData

        if let url = URL(string: prepareData.returnUrl) {
            dlog(url)
            RxBus.shared.post(event: EventBus.MainEvents.ChaiUri(appAddress: url))
        }

        timeOutTime = DispatchTime.now() + Double(CONST.TIME_OUT)
        dlog("set timeOutTime \(String(describing: timeOutTime))")

        checkRemoteChaiStatus()
    }

}
