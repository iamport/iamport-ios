//
// Created by BingBong on 2021/06/30.
// Copyright (c) 2021 CocoaPods. All rights reserved.
//

import Foundation
import SwiftUI

struct PickerView: View {
    @EnvironmentObject var viewModel: ViewModel
    var itemType: ItemType

    @State private var isPresent = false

    private func getPicker() -> some View {
        Picker(selection: $viewModel.pgInfos[itemType.rawValue].1.value.onUpdate {
            updatePayMethodList()
        }, label: Text("\(itemType.rawValue)")) {
            ForEach(viewModel.getItemList(type: itemType), id: \.0) {
                Text("\($0.0)  \($0.1)")
            }
        }
    }

    private func updatePayMethodList() {
        print("updated! \(itemType)")
        if (itemType == ItemType.PG) {
            print(viewModel.order.pg.value)
            viewModel.updatePayMethodList(pg: viewModel.order.pg.value)
        }
    }

    var body: some View {
        VStack {

            Text("적용할 \(itemType.name) 값 :\(viewModel.pgInfos[itemType.rawValue].1.value)")
                    .padding(.top, 120).frame(height: 30).font(.headline)
                    .multilineTextAlignment(.leading)

            Spacer()
            getPicker()
            Spacer()

            Button(action: {
                isPresent = true
            }) {
                Text("직접 입력하기")
                        .font(.title)
                        .fontWeight(.heavy).multilineTextAlignment(.center).padding(.bottom, 20)
            }.popover(isPresented: $isPresent) {
                Text("아래에 입력하세요")
                TextField("입력하세요", text: $viewModel.pgInfos[itemType.rawValue].1.value.onUpdate {
                    updatePayMethodList()
                })
                        .font(.title).frame(height: 50).multilineTextAlignment(.center)
                        .padding(10).border(Color.green, width: 1)

            }.buttonStyle(OutlineButton())
        }
    }
}

