//
//  ViewController.swift
//  iamport-ios
//
//  Created by bingbong on 01/04/2021.
//  Copyright (c) 2021 bingbong. All rights reserved.
//

import UIKit
import WebKit
import iamport_ios


class ViewController: UIViewController, WKUIDelegate, WKScriptMessageHandler {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        guard let webView = Iamport.sharedInstance.getWebView() else {
            print("웹뷰가 없음")
            return
        }

        view.addSubview(webView)
        webView.frame = view.bounds

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {

    }
}

