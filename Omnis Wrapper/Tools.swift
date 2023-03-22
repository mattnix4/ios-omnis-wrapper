//
//  Tools.swift
//  Omnis Wrapper
//
//  Created by Jason Gissing on 22/06/2018.
//  Copyright © 2018 Omnis Software. All rights reserved.
//

import UIKit

class Tools: NSObject {
	
	
	/// Create a UIColor from a Hex color string.
	///
	/// - Parameter hex: Hex color string. Must contain 6 hex characters. May contain a '#' prefix.
	/// - Returns: A UIColor matching the passed hex color. Or white if it fails to parse.
	static func hexStringToUIColor (hex: String) -> UIColor {
		var colorString = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
		
		// Remove the # prefix (if it has one)
		if (colorString.hasPrefix("#")) {
			colorString.remove(at: colorString.startIndex)
		}
		
		// If there are not 6 hex characters, just return white.
		if ((colorString.count) != 6) {
			return UIColor.white
		}
		
		var rgbValue: UInt32 = 0
		if Scanner(string: colorString).scanHexInt32(&rgbValue) {
			
			return UIColor(
				red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
				green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
				blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
				alpha: CGFloat(1.0)
			)
		}
		else {
			return UIColor.white
		}
		
	}
}
