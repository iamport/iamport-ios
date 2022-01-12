//
// Created by BingBong on 2021/06/30.
// Copyright (c) 2021 CocoaPods. All rights reserved.
//

import Foundation
import iamport_ios
import SwiftUI

class Utils {

    enum SampleUserCode: String, CaseIterable {
        case imp96304110
        case iamport
        case imp19424728
        case imp10391932
        case imp09350031
        case imp60029475
        case imp41073887
        case imp49241793
        case imp37739582
        case imp87936124
        case imp42284830
        case imp02690184

        var name: String {
            switch self {
            case .iamport:
                return "공식 default"
            case .imp19424728:
                return "default 테스트"
            case .imp10391932:
                return "kakao 테스트"
            case .imp09350031:
                return "paypal 테스트"
            case .imp60029475:
                return "mobilians 테스트"
            case .imp41073887:
                return "naverco, naverpay 테스트"
            case .imp49241793:
                return "smilepay 테스트"
            case .imp37739582:
                return "chai 테스트"
            case .imp87936124:
                return "alipay 테스트"
            case .imp42284830:
                return "payple 테스트"
            case .imp02690184:
                return "smartro 테스트"
            case .imp96304110:
                return "빙봉"
            }
        }
    }

    static public func getUserCodeList() -> Array<SampleUserCode> {
        SampleUserCode.allCases
    }


    static public func getPayMethodList(pg: PG) -> Array<PayMethod> {

        let defaultPayMethod = [PayMethod.card, PayMethod.vbank, PayMethod.trans, PayMethod.phone]

        switch pg {
        case .html5_inicis:
            return defaultPayMethod
                    + [PayMethod.samsung,
                       PayMethod.kpay,
                       PayMethod.cultureland,
                       PayMethod.smartculture,
                       PayMethod.happymoney]
        case .kcp:
            return defaultPayMethod
                    + [PayMethod.samsung]
        case .kcp_billing, .kakaopay,
             .paypal, .payco, .smilepay,
             .alipay, .settle_firm:
            return [PayMethod.card]
        case .uplus:
            return defaultPayMethod
                    + [PayMethod.cultureland,
                       PayMethod.smartculture,
                       PayMethod.booknlife]
        case .tosspay:
            return [PayMethod.card,
                    PayMethod.trans]
        case .danal:
            return [PayMethod.phone]
        case .mobilians:
            return [PayMethod.card,
                    PayMethod.phone]
        case .settle:
            return [PayMethod.vbank]
        case .chai, .payple:
            return [PayMethod.trans]
        case .eximbay:
            return [PayMethod.card,
                    PayMethod.unionpay,
                    PayMethod.alipay,
                    PayMethod.tenpay,
                    PayMethod.wechat,
                    PayMethod.molpay,
                    PayMethod.paysbuy]
        case .jtnet, .nice, .danal_tpay, .kicc,
             .naverco, .naverpay:
            return defaultPayMethod
        case .smartro:
            return [PayMethod.card, PayMethod.vbank, PayMethod.trans]
        default:
            return PayMethod.allCases
        }
    }
}

struct DeferView<Content: View>: View {
    let content: () -> Content

    init(@ViewBuilder _ content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        content()          // << everything is created here
    }
}

extension View {
    func onReceiveForeground(_ closure: @escaping () -> Void) -> some View {
        onReceive(NotificationCenter.default.publisher(for: UIScene.willEnterForegroundNotification)) { _ in
            print("Moving to the background!")
            closure()
        }
    }

    func onReceiveBackground(_ closure: @escaping () -> Void) -> some View {
        onReceive(NotificationCenter.default.publisher(for: UIScene.willDeactivateNotification)) { _ in
            print("Moving to the background!")
            closure()
        }
    }

    func onBackgroundDisappear(_ closure: @escaping () -> Void) -> some View {
        onReceiveBackground {
            print("onBackgroundDisappear :: onReceiveBackground!")
            closure()
        }.onDisappear {
            print("onBackgroundDisappear :: onDisappear!")
            closure()
        }
    }
}

extension Binding {

    /// When the `Binding`'s `wrappedValue` changes, the given closure is executed.
    /// - Parameter closure: Chunk of code to execute whenever the value changes.
    /// - Returns: New `Binding`.
    func onUpdate(_ closure: @escaping () -> Void) -> Binding<Value> {
        Binding(get: {
            wrappedValue
        }, set: { newValue in
            wrappedValue = newValue
            closure()
        })
    }
}

struct GradientButtonStyle: ButtonStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
                .foregroundColor(Color.white)
                .padding()
                .background(LinearGradient(gradient: Gradient(colors: [Color.red, Color.orange]), startPoint: .leading, endPoint: .trailing))
                .background(LinearGradient(gradient: Gradient(colors: [Color.red, Color.orange]), startPoint: .leading, endPoint: .trailing))
                .cornerRadius(15.0)
    }
}

struct OutlineButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration
                .label
                .foregroundColor(configuration.isPressed ? .gray : .accentColor)
                .padding()
                .background(
                        RoundedRectangle(
                                cornerRadius: 8,
                                style: .continuous
                        ).stroke(Color.accentColor)
                )
    }
}

struct GradientBackgroundStyle: ButtonStyle {

    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
                .frame(minWidth: 0, maxWidth: .infinity)
                .padding()
                .foregroundColor(.white)
                .background(configuration.isPressed ? Color.accentColor : Color.green)
                .cornerRadius(20)
    }
}

