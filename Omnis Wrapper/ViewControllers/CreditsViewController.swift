//
//  CreditsViewController.swift
//  Omnis Wrapper
//
//  Created by Jason Gissing on 20/06/2018.
//  Copyright © 2018 Omnis Software. All rights reserved.
//

import UIKit

class CreditsViewController: WebBaseViewController {
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		// Add Left button to navbar if there's not one shown (i.e. we have displayed Credits directly - not through the About screen):
		let navStackSize = navigationController?.viewControllers.count ?? 0
		let needsLeftButton = navStackSize < 2 || navigationController?.viewControllers[navStackSize - 2].navigationItem.leftBarButtonItem == nil
		if (needsLeftButton) {
			let leftButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action:#selector(CreditsViewController.closeCredits))
			navigationItem.leftBarButtonItem = leftButton
		}
		
	}
	
	override func getPageURL() -> URL? {
		return Bundle.main.url(forResource: "credits", withExtension: "html")
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	
	@objc
	func closeCredits() {
		performSegue(withIdentifier: "unwindToMainScreen", sender: self)
	}
	
}
