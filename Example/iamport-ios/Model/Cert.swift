//
// Created by BingBong on 2021/06/30.
// Copyright (c) 2021 CocoaPods. All rights reserved.
//

import Foundation
import Then
import SwiftUI

class Cert: ObservableObject, Then {
    var userCode = PubData()
    var carrier = PubData() // 통신사
    var name = PubData()
    var phone = PubData()
    var minAge = PubData()
    var merchantUid = PubData()
}
