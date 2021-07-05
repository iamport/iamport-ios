import Foundation
import SwiftUI
import UIKit
import WebKit
import iamport_ios


struct PaymentView: UIViewControllerRepresentable {
    @EnvironmentObject var viewModel: ViewModel


    func makeUIViewController(context: Context) -> UIViewController {
        let view = PaymentViewController()
        view.viewModel = viewModel
        return view
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
    }

}

class PaymentViewController: UIViewController, WKNavigationDelegate {
    var viewModel: ViewModel? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        print("IamportPaymentViewController viewDidLoad")

        view.backgroundColor = UIColor.white
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("IamportPaymentViewController viewWillAppear")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("IamportPaymentViewController viewDidAppear")
        requestPayment()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        print("IamportPaymentViewController viewWillDisappear")
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        print("IamportPaymentViewController viewDidDisappear")
    }


    // 아임포트 SDK 결제 요청
    func requestPayment() {
        let userCode = "imp96304110" // iamport 에서 부여받은 가맹점 식별코드
        if let request = viewModel?.createPaymentData() {
            dump(request)

//            WebViewContorller 용 닫기버튼 생성(PG "uplus(구 토스페이먼츠)" 는 자체취소 버튼이 없는 것으로 보임)
            Iamport.shared.useNaviButton(enable: true)

//         use for UIViewController
            Iamport.shared.payment(viewController: self,
                    userCode: userCode, iamPortRequest: request) { [weak self] iamPortResponse in
                self?.paymentCallback(iamPortResponse)
            }
        }
    }

    // 결제 완료 후 콜백 함수 (예시)
    func paymentCallback(_ response: IamPortResponse?) {
        print("------------------------------------------")
        print("결과 왔습니다~~")
        print("Iamport Payment response: \(response)")
        print("------------------------------------------")
    }

}

struct PaymentVieww_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            PaymentView()
        }
    }
}

