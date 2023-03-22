//
//  UILocalization.swift
//  Omnis Wrapper
//
//  Created by Jason Gissing on 5/29/19.
//  Copyright © 2019 Omnis Software. All rights reserved.
//

import Foundation

/**
	Adds a stringId InterfaceBuilder property to this class, to allow its title to be set by a string in Localizable.strings
*/
extension UINavigationItem {
	
	@IBInspectable var stringId: String {
		set(value) {
			self.title = NSLocalizedString(value, comment: "")
		}
		get {
			return ""
		}
	}
	
}

/**
Adds a stringId InterfaceBuilder property to this class, to allow its title to be set by a string in Localizable.strings
*/
extension UIBarButtonItem {
	
	@IBInspectable var stringId: String {
		set(value) {
			self.title = NSLocalizedString(value, comment: "")
		}
		get {
			return ""
		}
	}
	
}
