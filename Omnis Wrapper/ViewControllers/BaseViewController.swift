//
//  BaseViewController.swift
//  Omnis Wrapper
//
//  Created by Jason Gissing on 22/06/2018.
//  Copyright © 2018 Omnis Software. All rights reserved.
//

import UIKit

class BaseViewController: UIViewController {
	
	let hideStatusBar = !SettingsHelper.shared.getSettingBool(name: SettingsHelper.SETTING_APP_TITLE, defaultValue: true)!
	let useLightStatusBar = SettingsHelper.shared.getSettingBool(name: SettingsHelper.SETTING_LIGHT_STATUSBAR, defaultValue: true)!
	

	override func viewDidLoad() {
		super.viewDidLoad()
		
		// Do any additional setup after loading the view.
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	// MARK: statusbar appearance
	override var prefersStatusBarHidden: Bool
	{
		return hideStatusBar
	}
	
	override var preferredStatusBarStyle: UIStatusBarStyle
	{
		return useLightStatusBar ? .lightContent : .default
	}
	
}
