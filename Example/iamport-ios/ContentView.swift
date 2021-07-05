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

    @State var isPayment: Bool = false
    @State var buttonTag: Int? = nil

    @State var orderInfoView: OrderInfoView = OrderInfoView()
    @State var iamportPaymentView: PaymentView = PaymentView()
    @State var iamportPaymentWebViewMode: PaymentWebViewModeView = PaymentWebViewModeView()

    var body: some View {

        NavigationView {
            VStack {
                Form {

                    Image("logo_black").resizable()
                            .aspectRatio(contentMode: .fit)

                    Section(header: Text("PG정보")) {
                        getNaviPickerView(itemType: .UserCode)
                        getNaviPickerView(itemType: .PG)
                        getNaviPickerView(itemType: .PayMethod)
                    }

                    Section(header: Text("주문정보")) {
                        ForEach(viewModel.orderInfos, id: \.0) {
                            getNaviOrderInfoView($0.0, $0.1.value)
                        }
                    }
                }

                HStack(spacing: 30) {
                    buttonPayment()
                    Divider().frame(maxHeight: 30)
                    buttonPaymentWebViewMode()
                }.padding(.bottom, 30)

            }.navigationBarTitle(Text("아임포트로 결제~~"), displayMode: .inline)
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
            listItem(itemType.name, viewModel.pgInfos[itemType.rawValue].1.value)
        }
    }

    private func getNaviOrderInfoView(_ title: String, _ value: String) -> some View {
        NavigationLink(destination: orderInfoView) {
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
                NavigationLink(destination: iamportPaymentWebViewMode, tag: 1, selection: $buttonTag) {
                    EmptyView()
                }
                Text("웹뷰모드 결제")
                        .font(.title)
                        .fontWeight(.heavy)
            }
        }
    }

// 일반모드
    private func buttonPayment() -> some View {

        ZStack {

            Button(action: {
                isPayment = true
                viewModel.updateMerchantUid()
            }) {
                Text("결제하기")
                        .font(.title)
                        .fontWeight(.heavy)
            }.onReceiveBackground {
                isPayment = false
            }.onDisappear {
                isPayment = false
            }

            if isPayment {
                // trick size & opacity
                iamportPaymentView
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
