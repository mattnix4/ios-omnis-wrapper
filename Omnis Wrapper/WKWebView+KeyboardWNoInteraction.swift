/*** Changes
Date				Edit			Fault					Description
04-May21		jmg1143	WR/PF/1266		Added optional support to enable software keyboard on input focus without requiring user interaction.
 ***********/

#if KEYBOARD_WITHOUT_USER_INTERACTION

//  WKWebView+KeyboardWNoInteraction.swift
//  Omnis Wrapper
//
//	This extension to WKWebView adds the keyboardDisplayRequiresUserAction property, as was preeviously exposed on UIWebView.
//	In order to use this, add the flag 'KEYBOARD_WITHOUT_USER_INTERACTION' to EXTRA_BEHAVIOR_FLAGS in the project Build Settings.

//	It swizzles private methods to achieve this, so it may break with future iOS updates.
//	If this happens, look at the WebKit source to work out new method signatures etc: https://github.com/WebKit/webkit/blob/main/Source/WebKit/UIProcess/ios/WKContentViewInteraction.mm

//	WARNING! As this is using private methods, it has the potential to be rejected from the App Store.

//  Adapted from https://stackoverflow.com/questions/32449870/programmatically-focus-on-a-form-in-a-webview-wkwebview/46029192#46029192 by Pranit Harekar


import Foundation
import WebKit

typealias OldClosureType =  @convention(c) (Any, Selector, UnsafeRawPointer, Bool, Bool, Any?) -> Void
typealias NewClosureType =  @convention(c) (Any, Selector, UnsafeRawPointer, Bool, Bool, Bool, Any?) -> Void

extension WKWebView {
	
	var keyboardDisplayRequiresUserAction: Bool? {
		get {
			return self.keyboardDisplayRequiresUserAction
		}
		set {
			self.setKeyboardRequiresUserInteraction(newValue ?? true)
		}
	}
	
	
	private func setKeyboardRequiresUserInteraction( _ value: Bool) {
		guard let WKContentView: AnyClass = NSClassFromString("WKContentView") else {
			print("keyboardDisplayRequiresUserAction extension: Cannot find the WKContentView class")
			return
		}
		
		func swizzleMethod(selectorString: String, useOldClosureType: Bool = false) {
			
			let selector = sel_getUid(selectorString)
			if let method = class_getInstanceMethod(WKContentView, selector) {
				
				var newImp: IMP
				
				if (useOldClosureType) {
					let original = unsafeBitCast(method_getImplementation(method), to: OldClosureType.self)
					let newBlock: @convention(block) (Any, UnsafeRawPointer, Bool, Bool, Any?) -> Void = { (this, arg0, arg1, arg2, arg3) in
						original(this, selector, arg0, !value, arg2, arg3) // Pass the inverse of our prop as value for 'userIsInteracting' (2nd param)
					}
					newImp = imp_implementationWithBlock(newBlock)
				}
				else {
					let original = unsafeBitCast(method_getImplementation(method), to: NewClosureType.self)
					let newBlock: @convention(block) (Any, UnsafeRawPointer, Bool, Bool, Bool, Any?) -> Void = { (this, arg0, arg1, arg2, arg3, arg4) in
						original(this, selector, arg0, !value, arg2, arg3, arg4) // Pass the inverse of our prop as value for 'userIsInteracting' (2nd param)
					}
					newImp = imp_implementationWithBlock(newBlock)
				}
				
				method_setImplementation(method, newImp)
			}
			
		}
		
		// iOS 10+
		swizzleMethod(selectorString: "_startAssistingNode:userIsInteracting:blurPreviousNode:userObject:", useOldClosureType: true)
		// iOS 11.3+
		swizzleMethod(selectorString: "_startAssistingNode:userIsInteracting:blurPreviousNode:changingActivityState:userObject:")
		// iOS 12.2+
		swizzleMethod(selectorString: "_elementDidFocus:userIsInteracting:blurPreviousNode:changingActivityState:userObject:")
		// iOS 13.0+
		swizzleMethod(selectorString: "_elementDidFocus:userIsInteracting:blurPreviousNode:activityStateChanges:userObject:")
		
		// View WebKit source to find new method signature if this breaks for newer iOS versions:
		// https://github.com/WebKit/webkit/blob/main/Source/WebKit/UIProcess/ios/WKContentViewInteraction.mm
		
	}
}

#endif
