//
// Created by BingBong on 2021/01/19.
//

import Foundation

class MainViewModel {

    let repository = StrategyRepository() // TODO dependency inject

    func judgePayment(_ payment: Payment) {

        //  TODO Payment Validator
        repository.judgeStrategy.doWork(payment)

    }
}
