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

// 결과 화면
class PaymentResultViewController: UIViewController, UIGestureRecognizerDelegate {

    // 결과 전달 받을 RxSubject
    let impResponseSubject = BehaviorSubject<IamPortResponse?>(value: nil)
    var disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.interactivePopGestureRecognizer?.delegate = self

        print("종료 됐어요")

        let successColor = UIColor.green
        let failColor = UIColor.orange
        impResponseSubject.asObservable().subscribe { iamportResponseEvent in
            var color: UIColor = failColor
            // 성공 케이스
            if let iamportResponse = iamportResponseEvent.element, let response = iamportResponse {
                dump(iamportResponse)
                if (self.isSuccess(response)) {
                    color = successColor
                }
            }
            self.view.backgroundColor = color
        }.disposed(by: disposeBag)
    }

    private func isSuccess(_ iamportResponse: IamPortResponse) -> Bool {
        iamportResponse.imp_success ?? false || iamportResponse.success ?? false
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        disposeBag = DisposeBag()
    }

    @IBOutlet var paymentButton: UIButton!
}

