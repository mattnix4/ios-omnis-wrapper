//
//  OmnisCommsDelegate.swift
//  Omnis Wrapper
//
//  Created by Jason Gissing on 5/22/19.
//  Copyright © 2019 Omnis Software. All rights reserved.
//

import UIKit
import OmnisAppInterface

class OmnisCommsDelegate: NSObject, OMCommsDelegate  {
	
	private let PREF_SETTING_PREFIX = "_SETTING_"
	
	
	func messageFromJSClient( data: [String : AnyObject], omnisInterface: OmnisInterface ) -> Bool! {
		
		
		switch data["ID"] as? String {
			
		// If the pref name begins with "_SETTING_", override the default load pref handling to instead access native app settings:
		case OMCommsDelegateActions.ACTION_LOAD_PREF:
			let dataObj = data["Data"] as? [String:AnyObject]
			let key = dataObj?["key"] as? String ?? ""
			
			if (key.starts(with: PREF_SETTING_PREFIX)) {
				let realKey = String(key.dropFirst(PREF_SETTING_PREFIX.count))
				let theValue = SettingsHelper.shared.getSettingString(name: realKey, defaultValue: "")
				
				omnisInterface.callJS("window.wrapperInterface.setInstanceVar(\(dataObj!["omnisIndex"] as? Int ?? -1), \(dataObj!["formIndex"] as? Int ?? -1), \(dataObj!["dataIndex"] as? Int ?? -1), \"\(theValue!)\");")
				return true
			}
			
		// If the pref name begins with "_SETTING_", override the default save pref handling to instead access native app settings:
		case OMCommsDelegateActions.ACTION_SAVE_PREF:
			let dataObj = data["Data"] as? [String:AnyObject]
			let key = dataObj?["key"] as? String ?? ""
			let newValue = dataObj?["value"] as? String ?? ""
			
			if (key.starts(with: PREF_SETTING_PREFIX)) {
				let realKey = String(key.dropFirst(PREF_SETTING_PREFIX.count))
				let settingsHelper = SettingsHelper.shared
				settingsHelper.setSetting(name: realKey, value: newValue)
				settingsHelper.saveSettings()
				
				return true
			}
			
		default:
			return false
		}
		
		return false // Unhandled - fall back to default OmnisInterface implementation
	}
	

	
	
}
