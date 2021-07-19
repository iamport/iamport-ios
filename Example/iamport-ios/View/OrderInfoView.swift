//
// Created by BingBong on 2021/06/30.
// Copyright (c) 2021 CocoaPods. All rights reserved.
//

import Foundation
import SwiftUI


struct OrderInfoView: View {
    @EnvironmentObject var viewModel: ViewModel
    @Binding var infos: Array<(String, PubData)>

    var body: some View {
        NavigationView {
            Form {
                ForEach(0..<infos.count) { i in
                    let item = infos[i]
                    Section(header: Text("\(item.0)")) {
                        TextField("\(item.0) 입력", text: $infos[i].1.value)
                                .frame(height: 45)
                                .textFieldStyle(PlainTextFieldStyle())

                    }
                }
            }.navigationBarTitle(Text("입력정보"), displayMode: .inline)
        }
    }
}