import Foundation
import SwiftUI
import UIKit
import WebKit
import iamport_ios


struct CertificationView: UIViewControllerRepresentable {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @EnvironmentObject var viewModel: ViewModel

    func makeUIViewController(context: Context) -> UIViewController {
        let view = CertificationViewController()
        view.viewModel = viewModel
        view.presentationMode = presentationMode
        return view
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
    }

}

class CertificationViewController: UIViewController, WKNavigationDelegate {
    var viewModel: ViewModel? = nil
    var presentationMode: Binding<PresentationMode>?

    override func viewDidLoad() {
        super.viewDidLoad()
        print("CertificationView viewDidLoad")
        view.backgroundColor = UIColor.white
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("CertificationView viewDidAppear")
        requestCertification()
    }

    // 아임포트 SDK 본인인증 요청
    func requestCertification() {

        guard let viewModel = viewModel else {
            print("viewModel 이 존재하지 않습니다.")
            return
        }

        let userCode = viewModel.cert.userCode // iamport 에서 부여받은 가맹점 식별코드
        let request = viewModel.createCertificationData()
        dump(request)

//            WebViewContorller 용 닫기버튼 생성
        Iamport.shared.useNaviButton(enable: true)

//         use for UIViewController
        Iamport.shared.certification(viewController: self,
                userCode: userCode.value, iamPortCertification: request) { [weak self] iamPortResponse in
            viewModel.iamportCallback(iamPortResponse)
            self?.presentationMode?.wrappedValue.dismiss()
        }
    }

}

struct PaymentVieww_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            PaymentView()
        }
    }
}

