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
import RxCocoa
import RxSwift
import RxViewController

class ViewController: UIViewController, UIGestureRecognizerDelegate {
    var disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        print("Merchant viewDidLoad")
        navigationController?.interactivePopGestureRecognizer?.delegate = self
        view.backgroundColor = UIColor.white
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("Merchant viewWillAppear")
        bindUI()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        print("Merchant viewDidDisappear")
        disposeBag = DisposeBag()
    }

    func bindUI() {
        paymentButton?.rx.tap.bind { [weak self] in
            self?.requestPayment()
        }.disposed(by: disposeBag)
    }

    // 아임포트 SDK 결제 요청
    func requestPayment() {
        let userCode = "imp96304110"
        let request = createPaymentData()
        dump(request)
        Iamport.shared.payment(navController: navigationController, userCode: userCode, iamPortRequest: request) { [weak self] iamPortResponse in
            self?.paymentCallback(iamPortResponse)
        }
    }

    // 아임포트 결제 데이터 생성
    func createPaymentData() -> IamPortRequest {
        IamPortRequest(
                pg: PG.chai.makePgRawName(storeId: ""),
                merchant_uid: "muid_ios_\(Int(Date().timeIntervalSince1970))",
                amount: "1000").then {
            $0.pay_method = PayMethod.trans
            $0.name = "배달의 민족 주문~"
            $0.buyer_name = "남궁안녕"
            $0.app_scheme = "iamport"
        }
    }

    // 결제 완료 후 콜백 함수 (예시)
    func paymentCallback(_ response: IamPortResponse?) {
        print("결과 왔습니다~~")
        let resultVC = PaymentResultViewController()
        resultVC.impResponseRelay.accept(response)
        navigationController?.present(resultVC, animated: true)
//        navigationController?.pushViewController(resultVC, animated: true)
    }

    @IBOutlet var paymentButton: UIButton?
}

