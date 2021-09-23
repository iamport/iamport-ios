//
// Created by BingBong on 2021/01/19.
//

import Foundation

protocol IStrategy {
    func clear()
    func doWork(_ payment: Payment)
    func sdkFinish(_ response: IamPortResponse?)
}