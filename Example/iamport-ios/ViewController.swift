//
//  ViewController.swift
//  iamport-ios
//
//  Created by bingbong on 01/04/2021.
//  Copyright (c) 2021 bingbong. All rights reserved.
//

import UIKit
import WebKit
import Then
import iamport_ios

// 저는 머천트 앱 입니다.
class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        payment()
    }

    func payment() {
        Iamport.sharedInstance.start(self)

        let userCode = "imp96304110"
        let pg = PG.html5_inicis
        let payMethod = PayMethod.card
        let paymentName = "배달의 민족 주문~"
        let merchantUid = "muid_ios_\(Date().timeIntervalSince)"
        let amount = "1000" // 결제금액
        let buyer_name = "남궁안녕"

        let request = IamPortRequest(pg: pg.getPgSting(storeId: ""), merchant_uid: merchantUid, amount: amount).then {
            $0.pay_method = payMethod
            $0.name = paymentName
            $0.buyer_name = buyer_name
        }

        dump(request)

        // 웹뷰고 나발이고 여기선 파라미터 받아서 호출만 해야 함
        Iamport.sharedInstance.payment(userCode: userCode, iamPortRequest: request) { iamPortResponse in
            print("결과 왔습니다~~")
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

