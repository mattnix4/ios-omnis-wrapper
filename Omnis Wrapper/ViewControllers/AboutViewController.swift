//
//  SecondaryViewController.swift
//  Omnis Wrapper
//
//  Created by Jason Gissing on 20/06/2018.
//  Copyright © 2018 Omnis Software. All rights reserved.
//

import Foundation

class AboutViewController: WebBaseViewController
{
	override func getPageURL() -> URL? {
		return Bundle.main.url(forResource: "about", withExtension: "htm")
	}
	
}
