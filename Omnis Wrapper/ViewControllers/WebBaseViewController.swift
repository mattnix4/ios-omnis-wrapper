//
//  WebBaseViewController.swift
//  Omnis Wrapper
//
//  Created by Jason Gissing on 21/06/2018.
//  Copyright © 2018 Omnis Software. All rights reserved.
//

import UIKit
import WebKit

class WebBaseViewController: BaseViewController, WKUIDelegate {
	
	var webview: WKWebView?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		// Do any additional setup after loading the view.
		let viewRect = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height)
		webview = WKWebView(frame: viewRect)
		webview?.uiDelegate = self
		webview!.autoresizingMask = [.flexibleWidth , .flexibleHeight] // Make the webview resize with its parent view
		view.addSubview(webview!)
		
		if let pageUrl = getPageURL() {
			webview?.load(URLRequest(url: pageUrl))
		}
		
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	func getPageURL() -> URL? {
		assert(false, "This method must be overriden by the subclass")
		return nil
	}
	
	
	// Handle opening of new tabs by passing off to Safari (or whatever default app is):
	func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
		if (navigationAction.targetFrame == nil && navigationAction.request.url != nil) {
			if #available(iOS 10.0, *) {
				UIApplication.shared.open(navigationAction.request.url!)
			} else {
				// Fallback on earlier versions
				UIApplication.shared.openURL(navigationAction.request.url!)
			}
		}
		return nil
	}
	
}
