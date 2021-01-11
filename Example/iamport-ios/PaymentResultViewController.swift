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

// 저는 머천트 앱 입니다.
class PaymentResultViewController: UIViewController, UIGestureRecognizerDelegate {

    let impResponseSubject = BehaviorSubject<IamPortResponse?>(value: nil)

    private var impResponseBus: Observable<IamPortResponse?> {
        impResponseSubject.asObservable()
    }

    var disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()

        print("종료 됐어요")

        // Do any additional setup after loading the view, typically from a nib.

        navigationController?.interactivePopGestureRecognizer?.delegate = self

        let successColor = UIColor.green
        let failColor = UIColor.orange
        impResponseBus.subscribe { [weak self] iamportResponse in
            guard let response = iamportResponse.element else {
                self?.view.backgroundColor = failColor
                return
            }

            let isSuccess = response?.imp_success ?? false || response?.success ?? false
            if (isSuccess) {
                self?.view.backgroundColor = successColor
            } else {
                self?.view.backgroundColor = failColor
            }
        }.disposed(by: disposeBag)

    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        disposeBag = DisposeBag()
    }

    @IBOutlet var paymentButton: UIButton!
}

