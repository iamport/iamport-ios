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


// TODO: UIKit 용
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

        certificationButton?.rx.tap.bind { [weak self] in
            self?.requestCertification()
        }.disposed(by: disposeBag)
    }

    // 아임포트 SDK 본인인증 요청
    func requestCertification() {
        let userCode = "iamport" // 다날
        let request = createCertificationData()
        dump(request)

        guard let navController = navigationController else {
            print("navigationController 를 찾을 수 없습니다")
            return
        }

        Iamport.shared.certification(navController: navController, userCode: userCode, iamPortCertification: request) { [weak self] iamPortResponse in
            self?.paymentCallback(iamPortResponse)
        }

        // use for UIViewController
//        Iamport.shared.certification(viewController: self, userCode: userCode, iamPortCertification: request) { [weak self] iamPortResponse in
//            self?.paymentCallback(iamPortResponse)
//        }
    }

    // 아임포트 SDK 결제 요청
    func requestPayment() {
        let userCode = "iamport"
        let request = createPaymentData()
        dump(request)

//        guard let navController = navigationController else {
//            print("navigationController 를 찾을 수 없습니다")
//            return
//        }

        // case 1
//        Iamport.shared.payment(navController: navController,
//                userCode: userCode, iamPortRequest: request,
//                approveCallback: { approve in
//                    self.approveCallback(iamPortApprove: approve)
//                },
//                paymentResultCallback: { [weak self] iamPortResponse in
//                    self?.paymentCallback(iamPortResponse)
//                })

        // 결제요청 case 2
//        Iamport.shared.payment(navController: navigationController,
//                userCode: userCode, iamPortRequest: request) { [weak self] iamPortResponse in
//            self?.paymentCallback(iamPortResponse)
//        }

        // use for UIViewController
//        Iamport.shared.payment(viewController: self,
//                userCode: userCode, iamPortRequest: request) { [weak self] iamPortResponse in
//            self?.paymentCallback(iamPortResponse)
//        }

        if #available(iOS 11.0, *) {
            setupWebView()
        } else {
        }
        Iamport.shared.paymentWebView(webViewMode: wkWebView,
                userCode: userCode, iamPortRequest: request) { [weak self] iamPortResponse in
            self?.paymentCallback(iamPortResponse)
        }

//        openWebView()
//        Iamport.shared.pluginMobileWebSupporter(mobileWebMode: wkWebView)
    }


    private func openWebView() {
        print("오픈! 샘플 웹뷰")

        let bundle = Bundle(for: type(of: self))

        guard let url = bundle.url(forResource: "mobileweb", withExtension: "html") else {
            print("html file url 비정상")
            return
        }

        let urlRequest = URLRequest(url: url)
        DispatchQueue.main.async { [weak self] in
            self?.wkWebView.load(urlRequest)
        }
    }

    // 아임포트 결제 데이터 생성
    func createPaymentData() -> IamPortRequest {
        let display = CardQuota()
        display.card_quota = []

        return IamPortRequest(
                pg: PG.html5_inicis.makePgRawName(pgId: ""),
                merchant_uid: "muid_ios_\(Int(Date().timeIntervalSince1970))",
                amount: "1000").then {
            $0.pay_method = PayMethod.card
            $0.name = "아임포트의 민족 주문~~"
            $0.buyer_name = "남궁안녕"
            $0.app_scheme = "iamport"
//            $0.customer_uid = "cuid_ios_\(Int(Date().timeIntervalSince1970))"
        }
    }

    // 아임포트 본인인증 데이터 생성
    func createCertificationData() -> IamPortCertification {
        IamPortCertification(merchant_uid: "muid_ios_\(Int(Date().timeIntervalSince1970))").then {
            $0.min_age = 19
            $0.name = "김빙봉"
            $0.phone = "010-1234-5678"
            $0.carrier = "MVNO"
            $0.company = "유어포트"
        }
    }

    // 결제 완료 후 콜백 함수 (예시)
    func paymentCallback(_ response: IamPortResponse?) {
        print("------------------------------------------")
        print("결과 왔습니다~~")
        print("Iamport Payment response: \(response)")
        print("------------------------------------------")
        let resultVC = PaymentResultViewController()
        resultVC.impResponseRelay.accept(response)
        navigationController?.present(resultVC, animated: true)
//        navigationController?.pushViewController(resultVC, animated: true)
    }


    /**
     *  TODO: PG "CHAI" 결제시 재고확인 등 최종결제를 위한 처리를 해주세요
     *  CONST.CHAI_FINAL_PAYMENT_TIME_OUT_SEC 만큼 타임아웃 후 결제 데이터가
     *  초기화 되기 때문에 타임아웃 시간 안에 Iamport.chaiPayment 함수를 호출해주셔야 합니다.
     */
    private func approveCallback(iamPortApprove: IamPortApprove) {
        print("재고확인 합니다~~")

        let delaySec = Double(1)
        // delaySec 초 동안 머천트의 재고상황을 체크하는 것으로 "가정" 합니다
        DispatchQueue.global(qos: .userInteractive).asyncAfter(deadline: DispatchTime.now() + delaySec) {
            // delaySec 초 후 최종 결제 요청
            Iamport.shared.approvePayment(approve: iamPortApprove) // 최종 결제 요청
        }
    }


    @available(iOS 11.0, *)
    private func setupWebView() {
        view.addSubview(wkWebView)
        wkWebView.frame = view.frame

        let safeAreaInsets = view.safeAreaInsets
        wkWebView.translatesAutoresizingMaskIntoConstraints = false
        wkWebView.topAnchor.constraint(equalTo: view.topAnchor, constant: safeAreaInsets.top).isActive = true
        wkWebView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: safeAreaInsets.bottom).isActive = true
        wkWebView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0).isActive = true
        wkWebView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0).isActive = true
    }

    // test use webview
    lazy var wkWebView: WKWebView = {
        var view = WKWebView()
        view.backgroundColor = UIColor.clear
        return view
    }()

    @IBOutlet var paymentButton: UIButton?
    @IBOutlet var certificationButton: UIButton?
}

