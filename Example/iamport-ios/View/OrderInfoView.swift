//
// Created by BingBong on 2021/06/30.
// Copyright (c) 2021 CocoaPods. All rights reserved.
//

import Foundation
import SwiftUI


struct OrderInfoView: View {
    @EnvironmentObject var viewModel: ViewModel

    var body: some View {
        NavigationView {
            Form {
                let orderInfos = viewModel.orderInfos
                ForEach(0..<orderInfos.count) { i in
                    let item = orderInfos[i]
                    Section(header: Text("\(item.0)")) {
                        TextField("\(item.0) 입력", text: $viewModel.orderInfos[i].1.value)
                                .frame(height: 45)
                                .textFieldStyle(PlainTextFieldStyle())

                    }
                }
            }.navigationBarTitle(Text("주문정보"), displayMode: .inline)
        }
    }
}