//
// Created by BingBong on 2021/06/30.
// Copyright (c) 2021 CocoaPods. All rights reserved.
//

import Foundation
import Then
import SwiftUI
import iamport_ios


public enum ItemType: Int, CaseIterable {
    case UserCode, PG, PayMethod

    public var name: String {
        switch self {
        case .UserCode:
            return "가맹점 식별코드"
        case .PG:
            return "PG"
        case .PayMethod:
            return "결제수단"
        }
    }
}

public class ViewModel: ObservableObject, Then {

    var userCodeList = Utils.getUserCodeList() // 유저코드 리스트(예제용)
    var pgList = PG.allCases // PG 리스트
    var payMethodList: Array<PayMethod> = [] // PayMethod 리스트

    @Published var order: Order // 옵저빙할 결제 데이터 객체
    @Published var pgInfos: Array<(ItemType, PubData)> = []
    @Published var orderInfos: Array<(String, PubData)> = []
    @Published var isPayment = false

    init() {
        order = Order().then { order in
            order.userCode.value = Utils.SampleUserCode.iamport.rawValue
            order.price.value = "1000"
            order.orderName.value = "주문할건데요?"
            order.name.value = "빙봉"
            order.pg.value = PG.html5_inicis.rawValue
            order.appScheme.value = "iamport"
        }

        updateMerchantUid()

        // pub data init
        pgInfos = [
            (.UserCode, order.userCode),
            (.PG, order.pg),
            (.PayMethod, order.payMethod)
        ]

        orderInfos = [
            ("주문명", order.orderName),
            ("가격", order.price),
            ("이름", order.name),
            ("주문번호", order.merchantUid),
        ]

        updatePayMethodList(pg: order.pg.value)
    }

//        아임포트 결제 데이터 생성
    func createPaymentData() -> IamPortRequest? {
        guard let payMethod = PayMethod.convertPayMethod(order.payMethod.value) else {
            print("미지원 PayMethod : \(order.payMethod.value)")
            return nil
        }

        return IamPortRequest(
                pg: order.pg.value,
                merchant_uid: order.merchantUid.value,
                amount: order.price.value).then {
            $0.pay_method = payMethod
            $0.name = order.orderName.value
            $0.buyer_name = order.name.value
            $0.app_scheme = order.appScheme.value
        }
    }

    func updatePayMethodList(pg: String) {
        setPayMethodList(pg: pg)
        initPayMethod()
    }

    func updateMerchantUid() {
//        order.merchantUid.value = "muid_ios_\(Int(Date().timeIntervalSince1970))"
        order.merchantUid.value = UUID().uuidString
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
        }
    }

    //

}