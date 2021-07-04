//
// Created by BingBong on 2021/07/01.
// Copyright (c) 2021 CocoaPods. All rights reserved.
//

import Foundation
import SwiftUI

struct BackToHomeView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>

    var body: some View {
        VStack {
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Text("돌아가기")
            }
        }
                .navigationBarTitle("")
                .navigationBarBackButtonHidden(true)
                .navigationBarHidden(true)
    }
}

