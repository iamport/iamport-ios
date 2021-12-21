//
//  ContentView.swift
//  iamportiostest
//
//  Created by BingBong on 2021/06/11.
//

import SwiftUI
import Then

struct ContentView: View {

    @EnvironmentObject var viewModel: ViewModel

    @State var buttonTag: Int? = nil

    @State var paymentView: PaymentView = PaymentView()
    @State var paymentWebViewMode: PaymentWebViewModeView = PaymentWebViewModeView()

    var body: some View {
        TabView {
            NavigationView {
                VStack {
                    Form {
                        Image("logo_black").resizable()
                                .aspectRatio(contentMode: .fit)

                        Section(header: Text("PG정보")) {

                            Toggle(isOn: $viewModel.isCardDirect) {
                                Text("카드 다이렉트")
                            }.padding()

                            if viewModel.isCardDirect {
                                TextField("카드코드", text: $viewModel.order.cardCode.value)
                                        .frame(height: 45)
                                        .textFieldStyle(PlainTextFieldStyle())
                            }

                            getNaviPickerView(itemType: .UserCode)
                            getNaviPickerView(itemType: .PG)
                            getNaviPickerView(itemType: .PayMethod)
                        }

                        Section(header: Text("주문정보")) {
                            ForEach(viewModel.orderInfos, id: \.0) {
                                getNaviOrderInfoView($0.0, $0.1.value)
                            }
                            if viewModel.isDigital {
                                Toggle(isOn: $viewModel.order.digital.flag) {
                                    Text("휴대폰소액결제 digital")
                                }.padding()
                            }
                        }
                    }

                    HStack(spacing: 30) {
                        buttonPayment()
                        Divider().frame(maxHeight: 20)
                        buttonPaymentWebViewMode()
                    }.padding()

                }.navigationBarTitle(Text("아임포트로 결제~~"), displayMode: .inline)
            }.tabItem {
                Image(systemName: "list.dash")
                Text("결제")
                        .font(.title)
                        .fontWeight(.heavy)
            }


            // 본인인증 뷰
            NavigationView {
                VStack {
                    Form {
                        Section(header: Text("본인인증 정보")) {
                            getNaviPickerView(itemType: .Carrier)
                            ForEach(viewModel.certInfos, id: \.0) {
                                getNaviCertInfoView($0.0, $0.1.value)
                            }
                        }
                    }
                    buttonCertification()
                }
            }.tabItem {
                Image(systemName: "gift")
                Text("본인인증")
                        .font(.title)
                        .fontWeight(.heavy)
            }


            // 모바일 웹모드 뷰
            PaymentMobileViewModeView().tabItem {
                Image(systemName: "heart")
                Text("모바일웹")
                        .font(.title)
                        .fontWeight(.heavy)
            }

        }.actionSheet(isPresented: $viewModel.showResult) {
            ActionSheet(title: Text("결제 결과 도착~"),
                    message: Text("\(String(describing: viewModel.iamPortResponse))"),
                    buttons: [.default(Text("닫기"))])
        }
    }

    private func listItem(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text("\(value)").padding(.horizontal, 15).lineLimit(1)
        }
    }

    private func getNaviPickerView(itemType: ItemType) -> some View {
        NavigationLink(destination: PickerView(itemType: itemType)) {
            listItem(itemType.name, viewModel.iamportInfos[itemType.rawValue].1.value)
        }
    }

    private func getNaviOrderInfoView(_ title: String, _ value: String) -> some View {
        NavigationLink(destination: OrderInfoView(infos: $viewModel.orderInfos)) {
            listItem(title, value)
        }
    }

    private func getNaviCertInfoView(_ title: String, _ value: String) -> some View {
        NavigationLink(destination: OrderInfoView(infos: $viewModel.certInfos)) {
            listItem(title, value)
        }
    }


    // 웹뷰모드
    private func buttonPaymentWebViewMode() -> some View {
        ZStack {
            Button(action: {
                buttonTag = 1
                viewModel.updateMerchantUid()
            }) {
                NavigationLink(destination: paymentWebViewMode, tag: 1, selection: $buttonTag) {
                    Text("웹뷰모드 결제")
                            .font(.headline)
                }
            }.buttonStyle(GradientBackgroundStyle())
        }
    }

    // 일반모드 결제
    private func buttonPayment() -> some View {
        ZStack {
            Button(action: {
                viewModel.isPayment = true
                viewModel.updateMerchantUid()
            }) {
                Text("결제하기")
                        .font(.headline)
            }.onBackgroundDisappear {
                viewModel.clearButton()
            }.buttonStyle(GradientBackgroundStyle())

            if viewModel.isPayment {
                // trick size & opacity
                paymentView
                        .frame(width: 0, height: 0).opacity(0)
            }
        }
    }

    // 일반모드 본인인증
    private func buttonCertification() -> some View {
        ZStack {
            Button(action: {
                viewModel.isCert = true
                viewModel.updateMerchantUid()
            }) {
                Text("본인인증")
                        .font(.headline)
            }.onBackgroundDisappear {
                viewModel.clearButton()
            }.buttonStyle(GradientBackgroundStyle())

            if viewModel.isCert {
                // trick size & opacity
                CertificationView()
                        .frame(width: 0, height: 0).opacity(0)
            }
        }
    }

}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ContentView()
        }
    }
}
