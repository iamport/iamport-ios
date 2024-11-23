//
// Created by BingBong on 2021/06/30.
// Copyright (c) 2021 CocoaPods. All rights reserved.
//

import Foundation
import Then
import SwiftUI
import iamport_ios


public enum ItemType: Int, CaseIterable {
    case UserCode, PG, PayMethod, Carrier

    public var name: String {
        switch self {
        case .UserCode:
            return "가맹점 식별코드"
        case .PG:
            return "PG"
        case .PayMethod:
            return "결제수단"
        case .Carrier:
            return "(선택)통신사"
        }
    }
}

public class ViewModel: ObservableObject, Then {

    var userCodeList = Utils.getUserCodeList() // 유저코드 리스트(예제용)
    var pgList = PG.allCases // PG 리스트
    var payMethodList: Array<PayMethod> = [] // PayMethod 리스트
    var carrierList: Array<String> = ["SKT", "KTF", "LGT", "MVNO"] // PayMethod 리스트

    @Published var order: Order // 옵저빙할 결제 데이터 객체
    @Published var cert: Cert // 옵저빙할 본인인증 데이터 객체

    @Published var iamportInfos: Array<(ItemType, PubData)> = []
    @Published var orderInfos: Array<(String, PubData)> = []
    @Published var certInfos: Array<(String, PubData)> = []
    @Published var customerInfos: Array<(String, PubData)> = []

    @Published var isDigital = false
    @Published var isCardDirect = false
    @Published var isPayment: Bool = false
    @Published var isCert: Bool = false
    @Published var showResult: Bool = false
    @Published var CardDirectCode: String = ""
    var iamportResponse: IamportResponse?

    init() {
        order = Order().then { order in
            order.userCode.value = Utils.SampleUserCode.iamport.rawValue
            order.price.value = "1000"
            order.name.value = "테스트 결제"
            order.pg.value = PG.html5_inicis.rawValue
            order.appScheme.value = "iamport"
        }

        cert = Cert().then { cert in
            cert.userCode.value = Utils.SampleUserCode.iamport.rawValue
        }

        // pub data init
        iamportInfos = [
            (.UserCode, order.userCode),
            (.PG, order.pg),
            (.PayMethod, order.payMethod),
            (.Carrier, cert.carrier)
        ]

        orderInfos = [
            ("주문명", order.name),
            ("가격", order.price),
            ("주문번호", order.merchantUid),
        ]

        certInfos = [
            ("주문번호", cert.merchantUid),
//            ("(선택)통신사", cert.carrier),
            ("(선택)이름", cert.name),
            ("(선택)휴대폰번호", cert.phone),
            ("(선택)최소나이", cert.minAge),
        ]

        customerInfos = [
            ("구매자 이름", order.buyerName),
            ("구매자 연락처", order.buyerTel),
            ("구매자 이메일", order.buyerEmail),
            ("구매자 주소", order.buyerAddr),
        ]

        updatePayMethodList(pg: order.pg.value)
    }

    // 아임포트 결제 데이터 생성
    func createPaymentData() -> IamportPayment? {
        let payMethod = order.payMethod.value

        let req = IamportPayment(
                pg: order.pg.value,
                merchant_uid: order.merchantUid.value,
                amount: order.price.value).then {
            $0.pay_method = payMethod
            $0.name = order.name.value
            $0.buyer_name = order.buyerName.value
            $0.buyer_tel = order.buyerTel.value
            $0.buyer_email = order.buyerEmail.value
            $0.buyer_addr = order.buyerAddr.value
                    
            if (payMethod == PayMethod.phone.rawValue) {
                $0.digital = order.digital.flag
            } else if (payMethod == PayMethod.vbank.rawValue) {
                // @FIXME: PG마다 vbank_due의 형식이 다르므로 입력 컴포넌트를 만들거나(RN처럼) 예제 고도화 필요
                if (order.pg.value.hasPrefix(PG.ksnet.rawValue)) {
                    $0.vbank_due = "20250101153000"
                } else {
                    $0.vbank_due = "202501011530"
                }
            }
            $0.app_scheme = order.appScheme.value
            if (isCardDirect) {
                $0.card = Card(direct: CardDirect(code: order.cardCode.value))
            }
        }

        return req
    }


    // 결제 완료 후 콜백 함수 (예시)
    func iamportCallback(_ response: IamportResponse?) {
        print("------------------------------------------")
        print("결과 왔습니다~~")
        if let res = response {
            print("Iamport response: \(res)")
        }
        print("------------------------------------------")

        iamportResponse = response
        showResult = true
        clearButton()
    }

    func clearButton() {
        isPayment = false
        isCert = false
    }

    // 아임포트 본인인증 데이터 생성
    func createCertificationData() -> IamportCertification {
        IamportCertification(merchant_uid: cert.merchantUid.value).then {
            $0.min_age = Int(cert.minAge.value)
            $0.name = cert.name.value
            $0.phone = cert.phone.value
            $0.carrier = cert.carrier.value
        }
    }

    func updatePayMethodList(pg: String) {
        setPayMethodList(pg: pg)
        initPayMethod()
    }
    
    private func initPayMethod() {
        order.payMethod.value = payMethodList[0].rawValue
    }

    private func setPayMethodList(pg: String) {
        guard let pg = PG.convertPG(pgString: pg) else {
            print("PG를 찾을 수 없음 \(pg)")
            payMethodList = PayMethod.allCases
            return
        }
        payMethodList = Utils.getPayMethodList(pg: pg)
    }

    func getItemList(type: ItemType) -> Array<(String, String)> {
        switch type {
        case .UserCode:
            return userCodeList.map {
                ($0.rawValue, $0.name)
            }
        case .PG:
            return pgList.map {
                ($0.rawValue, $0.name)
            }
        case .PayMethod:
            return payMethodList.map {
                ($0.rawValue, $0.name)
            }

        case .Carrier:
            return carrierList.map {
                ($0, "")
            }
        }
    }

    //

}
