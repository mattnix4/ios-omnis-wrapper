/************* Changes
Date				Edit			Fault					Description
04-May21		jmg1143	  WR/PF/1266		Added optional support to enable software keyboard on input focus without requiring user interaction.
07-Apr-20		jmg0982									Fixed build issue on Catalina. Now able to set a setting by passing an Int (previously it had to be Int64).
21-Oct-19		jmg0941									Print log message if unable to parse config.xml.
21-May-19		jmg0889		WR/WR/326			Use config settings to control which pull-down menu options are shown.
 ***********/

//
//  SettingsHelper.swift
//  Omnis Wrapper
//
//  Created by Jason Gissing on 29/03/2018.
//  Copyright © 2018 Omnis Software. All rights reserved.
//

import UIKit
import OmnisAppInterface // jmg0941

class SettingsHelper: NSObject {
	
	private var settings: [String: SettingEntry]?
	private var currentSetting: SettingEntry?

	private static let RECORD_KEY = "OmnisiOSConfig"
	
	// The singleton SettingsHelper instance.
	public static let shared = SettingsHelper()
	
	
	// MARK: Private functions
	
	private override init() { // Private initialiser - must use static 'shared' property to get singleton instance.
		super.init()
		readConfigXML()
		loadSettingsFromPrefs() // Now load any saved settings from Stored Prefs (those marked as 'exposed'), overwriting their values from the XML.
		
		saveSettings() // Save the (exposed) loaded settings to prefs
	}
	
	private func readConfigXML() {
		let configUrl = Bundle.main.url(forResource: "config", withExtension: "xml")
		
		let parser = XMLParser(contentsOf: configUrl!)
		parser!.delegate = self
		if (!parser!.parse() || settings == nil) { // jmg0941
			print("WARNING! No settings could be parsed. Config.xml is probably missing or invalid XML.") // jmg0941
		}
	}
	
	private func loadSettingsFromPrefs()
	{
		let dict = UserDefaults.standard.dictionaryRepresentation()
		
		let prefixLength = SettingEntry.PREF_PREFIX.count
		
		for entry in dict {
			if (entry.key.starts(with: SettingEntry.PREF_PREFIX)) {
				let keyName = String(entry.key.dropFirst(prefixLength)) // Drop the prefix for the name of the setting.
				settings?[keyName] = SettingEntry.loadFromPrefs(key: entry.key)
			}
		}
	}
	
	// MARK: Public functions
	
	/// Set the value of a setting, without changing the setting's datatype.
	/// The passed value will be coerced to the correct type.
	public func setSetting(name: String, value: Any?) {
		
		var setting: SettingEntry?
		
		if (!settings!.keys.contains(name)) {
			setting = SettingEntry()
			setting!.dataType = SettingEntry.settingTypeFromValue(value)
			settings?[name] = setting
		}
		
		setting = settings![name]
		setting!.exposed = true // As we are changing the value, it is now implicitly exposed (so will be saved to sharedprefs)
		setting!.setValuePreservingType(value)
	}
	
	public func getSettingString(name: String, defaultValue: String?) -> String? {
			return settings?[name]?.getStringValue() ?? defaultValue
	}
	
	public func getSettingBool(name: String, defaultValue: Bool?) -> Bool? {
		return settings?[name]?.value as? Bool ?? defaultValue
	}
	
	public func getSettingLong(name: String, defaultValue: Int64?) -> Int64? {
		if (settings?[name] == nil) {
			return defaultValue
		}
		
		switch settings![name]!.dataType
		{
		case SettingEntry.DATATYPE_LONG:
			return settings![name]!.value as? Int64 ?? defaultValue
			
		case SettingEntry.DATATYPE_BOOL: // coerce into an Int64 from a boolean value
			let boolVal = settings![name]!.value as? Bool
			if (boolVal == nil) {
				return defaultValue
			}
			return boolVal! ? 1 : 0
			
		case SettingEntry.DATATYPE_STRING: // coerce into an Int64 from a string value
			let stringVal = settings![name]!.value as? String
			if (stringVal == nil) {
				return defaultValue
			}
			
			return Int64(stringVal!) ?? defaultValue
			
		default:
			return defaultValue
		}
		
	}
	
	public func saveSettings()
	{
		if (settings == nil) {
			return
		}
		
		for setting in settings! {
			if (setting.value.exposed) {
				setting.value.save(key: setting.key)
			}
		}
		
	}
}


// MARK: XMLParserDelegate
extension SettingsHelper: XMLParserDelegate
{
	func parserDidStartDocument(_ parser: XMLParser) {
		settings = [:]
	}
	

	// We've started a new element - create a SettingEntry for it, store relevant attributes, and assign to currentSetting:
	func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
		currentSetting = SettingEntry()
		
		if (attributeDict["type"] != nil) {
			currentSetting!.dataType = attributeDict["type"]!
		}
		
		if (attributeDict["exposed"] != nil) {
			currentSetting!.exposed = attributeDict["exposed"]! == "1"
		}
	}
	
	// Found text content inside an element
	func parser(_ parser: XMLParser, foundCharacters string: String) {
		
		if (currentSetting != nil)
		{
			switch currentSetting!.dataType {
			case SettingEntry.DATATYPE_STRING:
				currentSetting!.value = (currentSetting!.value as? String ?? "") + string
				
			case SettingEntry.DATATYPE_BOOL:
				currentSetting!.value = string == "1"
				
			case SettingEntry.DATATYPE_LONG:
				currentSetting!.value = Int64(string)
				
			default:
				print("Unsupported config.xml data type: '\(currentSetting!.dataType)'")
				currentSetting!.value = nil
			}
		}
	}
	
	// End of an element, add the currentSetting to our settings dictionary:
	func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
		
		if (currentSetting != nil) {
			settings?[elementName] = currentSetting!
			currentSetting = nil
		}
	}
	
	// Something went wrong:
	func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
		print(parseError)
		currentSetting = nil
		settings = nil
	}
	
}
	
extension SettingsHelper {
	/// A class representing a single setting
	private class SettingEntry
	{
		static let DATATYPE_STRING = "string"
		static let DATATYPE_BOOL = "bool"
		static let DATATYPE_LONG = "long"
		
		static let PREF_PREFIX = "" //SETTING_"
		
		public var dataType: String
		public var value: Any?
		public var exposed: Bool // If an entry is exposed, it will be saved to UserDefaults, then loaded from there next time. Otherwise it will be read from config.xml.
		
		public init() {
			exposed = false;
			dataType = SettingEntry.DATATYPE_STRING;
		}
		
		func getStringValue() -> String? {
			
			if (value == nil) {
				return nil
			}
			
			if let stringValue = value as? String {
				return stringValue
			}
			else if (dataType == SettingEntry.DATATYPE_BOOL) {
				return (value as? Bool) == true ? "true" : "false"
			}
			else if (dataType == SettingEntry.DATATYPE_LONG) {
				return "\(value as? Int64 ?? -1)"
			}
			
			return ""
		}
		
		func setValuePreservingType(_ newValue: Any?) {
			if (newValue == nil) {
				value = nil
				return
			}
			
			switch dataType {
			case SettingEntry.DATATYPE_BOOL:
				setBoolValue(newValue!)
			case SettingEntry.DATATYPE_LONG:
				setLongValue(newValue!)
			default:
				setStringValue(newValue!)
			}
		}
		
		private func setBoolValue(_ newValue: Any) {
			
			if let boolValue = newValue as? Bool {
				value = boolValue
			}
			else if let intValue = newValue as? Int64 {
				value = intValue > 0
			}
			else if (newValue is String) {
				let stringVal = (newValue as! String).lowercased()
				value = stringVal.starts(with: "1") || stringVal.starts(with: "t")
			}
			else {
				value = false
				print("setBoolValue FAILED")
			}
		}
		
		private func setStringValue(_ newValue: Any) {
			value = newValue as? String ?? ""
		}
		
		private func setLongValue(_ newValue: Any) {
			
			if let intValue = newValue as? Int64 {
				value = intValue
			}
			// Start jmg0982
			else if let intValue = newValue as? Int {
				value = Int64(exactly: intValue)
			}
				// End jmg0982
			else if let stringValue = newValue as? String {
				value = Int64(stringValue)
			}
			else {
				value = 0
				print("setLongValue FAILED")
			}
		}
		
		func save(key: String!)
		{
			UserDefaults.standard.set(value, forKey: SettingEntry.PREF_PREFIX + key)
		}
		
		public static func loadFromPrefs(key: String!) -> SettingEntry?
		{
			let value = UserDefaults.standard.object(forKey: key)
			let setting = SettingEntry()
			setting.exposed = true // Any setting which was saved to prefs must be 'exposed' (that is its meaning).
			
			if let stringValue = value as? String {
				setting.dataType = SettingEntry.DATATYPE_STRING
				setting.value = stringValue
			}
			else if let boolValue = value as? Bool {
				setting.dataType = SettingEntry.DATATYPE_BOOL
				setting.value = boolValue
			}
			else if let longValue = value as? Int64 {
				setting.dataType = SettingEntry.DATATYPE_LONG
				setting.value = longValue
			}
			
			return setting
		}
		
		public static func settingTypeFromValue(_ value: Any?) -> String {
			
			if (value is Bool) {
				return SettingEntry.DATATYPE_BOOL
			}
			else if (value is Int64 || value is Int) { // jmg0982
				return SettingEntry.DATATYPE_LONG
			}
			
			return SettingEntry.DATATYPE_STRING
		}
	}
	
}

// Static strings for the built-in setting names:
extension SettingsHelper
{
	public static let SETTING_OMNISWEBURL = "WebServerURL"
	public static let SETTING_ONLINEFORMNAME = "OnlineForm"
	
	public static let SETTING_STARTOFFLINE = "StartInOfflineMode"
	public static let SETTING_OMNISSERVER = "OmnisServer"
	public static let SETTING_OMNISPLUGIN = "OmnisPlugin"
	public static let SETTING_OFFLINEFORMNAME = "OfflineFormName"
	public static let SETTING_APPSCAFNAME = "AppSCAFName"
	
	public static let SETTING_LOCALDBNAME = "LocalDBName"
	
	public static let SETTING_PUSHNOTIFICATIONSERVER = "PushNotificationServer"
	public static let SETTING_PUSHNOTIFICATIONGROUPS = "PushNotificationGroupMask"
	
	public static let SETTING_MENUINCLUDESETTINGS = "MenuIncludeSettings"
	public static let SETTING_MENUINCLUDEOFFLINE = "MenuIncludeOffline"
	public static let SETTING_MENUINCLUDEUPDATE = "MenuIncludeUpdate"
	public static let SETTING_MENUINCLUDEABOUT = "MenuIncludeAbout"
	public static let SETTING_MENUINCLUDECREDITS = "MenuIncludeCredits" // jmg0889
	
	public static let SETTING_USELOCALTIME = "UseLocalTime"
	public static let SETTING_BACKGROUND_COLOR = "BackgroundColor"
	public static let SETTING_APP_TITLE = "AppTitle"
	public static let SETTING_LIGHT_STATUSBAR = "LightStatusBar"
	
	public static let SETTING_KEYBOARD_WITHOUT_USER_ACTION = "KeyboardWithoutUserInteraction" // jmg1143
}
