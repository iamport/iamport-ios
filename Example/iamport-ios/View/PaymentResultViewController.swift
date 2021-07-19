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

// TODO: UIKit 용
// 결과 화면
class PaymentResultViewController: UIViewController, UIGestureRecognizerDelegate {

    // 결과 전달 받을 RxSubject
    let impResponseRelay = BehaviorRelay<IamPortResponse?>(value: nil)
    var disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.interactivePopGestureRecognizer?.delegate = self
        print("종료 됐어요")

        let successColor = UIColor.green
        let failColor = UIColor.orange
        let justCloseColor = UIColor.darkGray
        impResponseRelay.asObservable().subscribe { iamportResponseEvent in
            var color: UIColor = failColor
            var desc = "Just Close"

            // 성공 케이스
            if let iamportResponse = iamportResponseEvent.element, let response = iamportResponse {
//                dump(iamportResponse)
                if (self.isSuccess(response)) {
                    color = successColor
                }

                desc = iamportResponse?.description ?? ""
            } else {
                color = justCloseColor
            }

            print(desc)
            self.view.backgroundColor = color
        }.disposed(by: disposeBag)
    }

    // imp_success, success 해당 값을 맹신할 수 없습니다.
    // 뱅크페이 실시간 계좌이체는 해당 값이 전달되지 않는 케이스가 있습니다.
    // 결과 콜백을 받으면, Iamport REST API 등을 통해 "실제 결제 여부" 를 체크하셔야 합니다.
    private func isSuccess(_ iamportResponse: IamPortResponse) -> Bool {
        iamportResponse.imp_success ?? false || iamportResponse.success ?? false
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        disposeBag = DisposeBag()
    }

    @IBOutlet var paymentButton: UIButton!
}

