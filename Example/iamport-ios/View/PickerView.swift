//
// Created by BingBong on 2021/06/30.
// Copyright (c) 2021 CocoaPods. All rights reserved.
//

import Foundation
import SwiftUI
import iamport_ios

struct PickerView: View {
    @EnvironmentObject var viewModel: ViewModel
    var itemType: ItemType

    @State private var isPresent = false

    private func getPicker() -> some View {
        Picker(selection: $viewModel.iamportInfos[itemType.rawValue].1.value.onUpdate {
            update()
        }, label: Text("\(itemType.rawValue)")) {
            ForEach(viewModel.getItemList(type: itemType), id: \.0) {
                Text("\($0.0)  \($0.1)")
            }
        }
    }

    private func update() {
        updatePayMethodList()
        updateHiddenItem()
    }

    private func updatePayMethodList() {
        print("updatePayMethodList! \(itemType)")
        if (itemType == ItemType.PG) {
            print(viewModel.order.pg.value)
            viewModel.updatePayMethodList(pg: viewModel.order.pg.value)
        }
    }

    private func updateHiddenItem() {
        print("updateHiddenItem! \(viewModel.order.payMethod.value)")
        if (PayMethod.phone == PayMethod.convertPayMethod(viewModel.order.payMethod.value)) {
            viewModel.isDigital = true
            return
        }
        viewModel.isDigital = false
    }

    var body: some View {
        VStack {

            Text("적용할 \(itemType.name) 값 :\(viewModel.iamportInfos[itemType.rawValue].1.value)")
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
                TextField("입력하세요", text: $viewModel.iamportInfos[itemType.rawValue].1.value.onUpdate {
                    update()
                })
                        .font(.title).frame(height: 50).multilineTextAlignment(.center)
                        .padding(10).border(Color.green, width: 1)

            }.buttonStyle(OutlineButton())
        }
    }
}

