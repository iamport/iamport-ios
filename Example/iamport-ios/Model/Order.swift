//
// Created by BingBong on 2021/06/30.
// Copyright (c) 2021 CocoaPods. All rights reserved.
//

import Foundation
import Then
import SwiftUI

class Order: ObservableObject, Then {
    var userCode = PubData()
    var payMethod = PubData()
    var pg = PubData()
    var orderName = PubData()
    var price = PubData()
    var name = PubData()
    var appScheme = PubData()
    var merchantUid = PubData()
    var digital = PubData()
}
