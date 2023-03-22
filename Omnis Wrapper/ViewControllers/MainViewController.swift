/*  Changes:
Date			Edit			Fault				Description
23-Nov-21	jmg1179		WR/JS/2809	We weren't setting the app background colour correctly.
04-May21	jmg1143	  WR/PF/1266	Added optionaly support to enable software keyboard on input focus without requiring user interaction.
12-Apr-21	jmg1141								We weren't setting the app background colour correctly.
09-Jun-20	jmg1006								Child view controllers' viewWillTransition method wasn't called.
30-Apr-20	jmg0993		AF/PF/1193	Fixed crash if web server URL or online form name contained a space.
03-Dec-19	jmg0954		WR/WR/338		Wait until user has clicked OK on SCAF Update message before attempting to load it.
03-Dec-19	jmg0953		WR/HE/1659	Migrated to using LaunchScreen storyboard rather than old-style Launch Images.
21-Oct-19	jmg0939		WR/PF/1161	Web Server Plugin was not passed through to Omnis Interface.
21-May-19	jmg0889		WR/WR/326		Use config settings to control which pull-down menu options are shown.
21-May-19	jmg0888		WR/WR/326		Wrapper now passes useLocalTime through to Omnisinterface.
18-Mar-19	jmg0873								Online form name in config.xml did not include the .htm extension.
17-Jul-18	jmg0785								Crash when opening pull-down menu on iPad.
*/

//
//  ViewController.swift
//  Omnis Wrapper
//
//  Created by Jason Gissing on 12/12/2017.
//  Copyright © 2017 Omnis Software. All rights reserved.
//

import UIKit
import WebKit
import OmnisAppInterface


class MainViewController: BaseViewController, OMScafHandlerDelegate, UIScrollViewDelegate {
	
	var omnisInterface: OmnisInterface!
	var omnisCommsDelegate = OmnisCommsDelegate()
	var backgroundImage: UIView? // jmg0953
	var currentOrientation = UIDevice.current.orientation
	var showingBackgroundImage = true
	var alert: UIAlertController? // jmg0785
	
	var omnisServer = ""
	let offlineForm = ""
	let appSCAF = ""
	
	
	var loadFormOnceVisible = true
	var offlineMode = false
	var offlineDir = ""
	
	@IBOutlet weak var webviewContainer: OMWebContainer!
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		
	}
	
	@IBAction func unwindToMainScreen(segue: UIStoryboardSegue) {
		// And we are back
		//		let svc = segue.sourceViewController as! TheViewControllerClassYouAreReturningFrom
		// use svc to get mood, action, and place
	}
	
	
	func initOmnisInterface() {
		let helper = SettingsHelper.shared
		
		offlineMode = helper.getSettingBool(name: SettingsHelper.SETTING_STARTOFFLINE, defaultValue: false)!
		omnisServer = helper.getSettingString(name: SettingsHelper.SETTING_OMNISWEBURL, defaultValue: omnisServer)!
		
		// Start jmg0888
		let settings = Settings()
		settings.setSettings(dict: [
			SettingNames.EXPECT_SCAFS: false,
			SettingNames.USE_LOCAL_TIME: helper.getSettingBool(name: SettingsHelper.SETTING_USELOCALTIME, defaultValue: false)!
			])
		
		omnisInterface = OmnisInterface(webviewContainer: webviewContainer, viewController: self, settings: settings)
		// End jmg0888
		
		#if KEYBOARD_WITHOUT_USER_INTERACTION // Start jmg1143
		if (helper.getSettingBool(name: SettingsHelper.SETTING_KEYBOARD_WITHOUT_USER_ACTION, defaultValue: false)!) {
			webviewContainer.getWebview()?.keyboardDisplayRequiresUserAction = false
		}
		#endif // End jmg1143
		
		#if PUSH_NOTIFICATIONS
		omnisInterface.features.addFeature(featureID: FeatureTypes.PUSH_NOTIFICATIONS)
		#endif
		
		omnisInterface.commsDelegate = omnisCommsDelegate
		omnisInterface.scafHandler.delegate = self
		omnisInterface.database.initLocalDatabase(dbName: helper.getSettingString(name: SettingsHelper.SETTING_LOCALDBNAME, defaultValue: "local.db")!)
		omnisInterface.scafHandler.initScafController(inSubfolder: "offline",
																									formName: helper.getSettingString(name: SettingsHelper.SETTING_OFFLINEFORMNAME, defaultValue: ""),
																									scafName: helper.getSettingString(name: SettingsHelper.SETTING_APPSCAFNAME, defaultValue: ""),
																									omnisWebUrl: helper.getSettingString(name: SettingsHelper.SETTING_OMNISWEBURL, defaultValue: ""),
																									omnisServer: helper.getSettingString(name: SettingsHelper.SETTING_OMNISSERVER, defaultValue: "")!,
																									omnisPlugin: helper.getSettingString(name: SettingsHelper.SETTING_OMNISPLUGIN, defaultValue: "")!) // jmg0939
		
		attachPullDownMenu()
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		#if PUSH_NOTIFICATIONS
		// The AppDelegate broadcasts a message which we catch here when a notification is clicked
		NotificationCenter.default.addObserver(self, selector: #selector(self.notificationClicked(_:)), name: Notification.Name(rawValue: "OmnisNotificationClicked"), object: nil)
		#endif
		
		let bgColor = SettingsHelper.shared.getSettingString(name: SettingsHelper.SETTING_BACKGROUND_COLOR, defaultValue: "#FFFFFF")! // jmg1179
		self.view.backgroundColor = Tools.hexStringToUIColor(hex: bgColor) // jmg1179
		
		addBackgroundImage() // Show the launch image as a background image, while we set up the webview etc.
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		if (loadFormOnceVisible) { // Use this for initialisation, rather than viewDidLoad, to allow us to show dialogs when errors occur on init.
			loadFormOnceVisible = false
			initOmnisInterface()
			webviewContainer.isHidden = false // We can now show the webview, avoiding any white flicker.
			hideBackgroundImage()
			
			// Check if we were launched by clicking a notification with a Data payload:
			var queryParams: [String: String]?
			if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
				if (appDelegate.launchNotificationData != nil) {
					queryParams = getQueryParamsFromPayload(appDelegate.launchNotificationData!)
					appDelegate.launchNotificationData = nil // So we don't pass the same queryParams through on next refresh
				}
			}
			
			reloadForm(queryParams: queryParams)
		}
	}
	
	override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
		super.viewWillTransition(to: size, with: coordinator) // jmg1006
		self.currentOrientation = UIDevice.current.orientation
		
		// jmg0785: If we have a popup menu showing, reposition it, so it stays in the center:
		alert?.popoverPresentationController?.sourceRect = CGRect(x: size.width/2,y: size.height/2, width: 0, height: 0) // jmg0785
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	// MARK: Private methods
	
	private func getQueryParamsFromPayload(_ payload: [AnyHashable: Any]) -> [String: String] {
		
		var queryParams = [String: String]()
		
		var dataPayload = payload
		
		// Remove unwanted keys:
		dataPayload.removeValue(forKey: "aps") // jmg0592: The Apple Push Service object, conatining notification data
		dataPayload.removeValue(forKey: "from")
		dataPayload.removeValue(forKey: "notification")
		dataPayload.removeValue(forKey: "collapse_key")
		dataPayload.removeValue(forKey: "_OMNIS_NOTIFICATION_") // jmg0592: Identifier indicating that the notification was sent from Omnis.
		
		// Parse dataPayload into a series of String keys & values, suitable for use as URL query params:
		queryParams = [String: String]()
		
		for (name, value) in dataPayload
		{
			guard let name = name as? String else { continue }
			if (name.starts(with: "gcm.") || name.starts(with: "google.")) { // Ignore any keys beginning with "google." or "gcm."
				continue
			}
			let value = String(describing: value)
			
			queryParams[name] = value
		}
		
		return queryParams
	}
	
	#if PUSH_NOTIFICATIONS
	
	@objc
	private func notificationClicked(_ notification: Notification)
	{
		if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
			if (appDelegate.launchNotificationData == nil) {
				
				let queryParams = getQueryParamsFromPayload(notification.userInfo ?? [:])
				reloadForm(queryParams: queryParams)
			}
			else {
				// The app was launched from the notification click - the form loading (and sending of appDelegate.launchNotificationData as queryParams) will happen in viewDidAppear()
			}
		}
	}
	
	#endif
	
	private func addBackgroundImage()
	{
	// Start jmg0953
		let storyboard = UIStoryboard(name: "LaunchScreen", bundle: nil)
		let vc = storyboard.instantiateViewController(withIdentifier: "LaunchScreen")
		backgroundImage = vc.view
	// End jmg0953
		self.view.insertSubview(backgroundImage!, at: 0)
		
		webviewContainer.isHidden = true // On initial start-up, keep the webview hidden while we set things up - we display the LaunchScreen's view during this time (beyond the default display time for it)
	}
	
	private func hideBackgroundImage()
	{
		backgroundImage?.removeFromSuperview() // jmg0953
		showingBackgroundImage = false
	}
	
	private func attachPullDownMenu() {
		if let wksubviews = webviewContainer.getWebview()?.subviews {
			
			for subview in wksubviews {
				if let scrollview = subview as? UIScrollView
				{
					scrollview.delegate = self
					let pull = PullToRefreshView(scrollView: scrollview)!
					pull.delegate = self
					scrollview.addSubview(pull)
					return
				}
			}
			
		}
		else {
			print("Unable to attach pulldown menu - webview not ready")
		}
	}
	
	private func openActionsMenu() {
		
		let settings = SettingsHelper.shared // jmg0889
		
		// Start jmg0785
		alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
		
		alert?.addAction(UIAlertAction(title: NSLocalizedString("Reload", comment: ""), style: .default) { _ in
			self.reloadForm()
		})
		
		if (offlineMode && settings.getSettingBool(name: SettingsHelper.SETTING_MENUINCLUDEUPDATE, defaultValue: true)!) { // jmg0889
			alert?.addAction(UIAlertAction(title: NSLocalizedString("Update SCAFs", comment: ""), style: .default) { _ in
				self.updateSCAFs()
			})
		}
		
		if (!offlineMode &&
			settings.getSettingBool(name: SettingsHelper.SETTING_MENUINCLUDEOFFLINE, defaultValue: true)! && // jmg0889
			!settings.getSettingString(name: SettingsHelper.SETTING_OFFLINEFORMNAME, defaultValue: "")!.isEmpty)
		{
			alert?.addAction(UIAlertAction(title: NSLocalizedString("Go Offline", comment: ""), style: .default) { _ in
				self.offlineMode = true
				if (self.offlineDir.count > 0) { // offlineURL will be an empty string until offline mode is ready
					self.reloadForm()
				}
				else {
					self.updateSCAFs()
				}
				
			})
		}
		else if (offlineMode && settings.getSettingBool(name: SettingsHelper.SETTING_MENUINCLUDEOFFLINE, defaultValue: true)!) { // jmg0889
			alert?.addAction(UIAlertAction(title: NSLocalizedString("Go Online", comment: ""), style: .default) { _ in
				self.offlineMode = false
				self.reloadForm()
			})
		}
		
		if (settings.getSettingBool(name: SettingsHelper.SETTING_MENUINCLUDEABOUT, defaultValue: true)!) { // jmg0889
			alert?.addAction(UIAlertAction(title: NSLocalizedString("nav_title_about", comment: ""), style: .default) { _ in
				self.performSegue(withIdentifier: "showAboutSegue", sender: nil)
			})
		}
		
		if (settings.getSettingBool(name: SettingsHelper.SETTING_MENUINCLUDECREDITS, defaultValue: false)!) { // jmg0889
			alert?.addAction(UIAlertAction(title: NSLocalizedString("nav_title_credits", comment: ""), style: .default) { _ in
				self.performSegue(withIdentifier: "showCreditsSegue", sender: nil)
			})
		}
		
		if (settings.getSettingBool(name: SettingsHelper.SETTING_MENUINCLUDESETTINGS, defaultValue: false)!) {
			alert?.addAction(UIAlertAction(title: NSLocalizedString("Settings", comment: ""), style: .default) { _ in
				if let appSettings = NSURL(string: UIApplicationOpenSettingsURLString) {
					UIApplication.shared.openURL(appSettings as URL)
				}
			})
		}
		
		alert?.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
		
		alert?.modalPresentationStyle = .popover
		alert?.popoverPresentationController?.sourceView = view
		alert?.popoverPresentationController?.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
		alert?.popoverPresentationController?.permittedArrowDirections = UIPopoverArrowDirection(rawValue: 0)
		
		self.present(alert!, animated: true, completion: nil)
		// End jmg0785
	}
	
	
	private func reloadForm(queryParams: [String: String]? = nil) {
		OMDialogs.showLoadingOverlay(onView: webviewContainer!.getWebview()!, text: "", cancelAppearsAfter: 2000) // This will be replaced by the OMWebController's default handling when the page begins to load. We add this here to avoid a white flicker before this point (and don't require to implement the OMWebNavigationDelegate just for this)
		do {
			if (!offlineMode) {
				let settings = SettingsHelper.shared
				let host = settings.getSettingString(name: SettingsHelper.SETTING_OMNISWEBURL, defaultValue: "")!
				let formName = settings.getSettingString(name: SettingsHelper.SETTING_ONLINEFORMNAME, defaultValue: "")!
				// Start jmg0993
				if let url = URL(string: "\(host)\(formName)") {
					try omnisInterface.loadURL(url, withParams: queryParams) // jmg0873
				}
				else {
					OMDialogs.showOKMessage(message: "Invalid URL: \"\(host)\(formName)\"", title: NSLocalizedString("Error", comment: ""))
				}
				// End jmg0993
			}
			else {
				omnisInterface.scafHandler.loadOfflineForm(queryParams: queryParams)
			}
		}
		catch (let error) {
			OMDialogs.showOKMessage(message: error.localizedDescription, title: NSLocalizedString("Error", comment: ""))
			OMDialogs.removeLoadingOverlay(onView: webviewContainer!.getWebview()!)
		}
	}
	
	private func updateSCAFs()
	{
		OMDialogs.showLoadingOverlay(onView: webviewContainer, text: NSLocalizedString("Updating SCAFs....", comment: ""))
		omnisInterface.scafHandler.updateScafs()
	}
	
	
	//MARK: SCAF handler delegate
	func onScafHandlerError(errorText: String!, action: ScafAction!) -> Bool {
		OMDialogs.removeLoadingOverlay(onView: webviewContainer)
		OMDialogs.removeLoadingOverlay(onView: webviewContainer.getWebview()!) // Also remove any loading overlay from the webview (for loading the form)
		return false // Let default handling occur (show error message)
	}
	
	
	func onScafUpdateCompleted(didUpdate: Bool!, withErrors: [String]?, newHtmlPath: String!) -> Bool {
		self.offlineDir = newHtmlPath;
		OMDialogs.removeLoadingOverlay(onView: webviewContainer)
		if (didUpdate) {
			// Start jmg0954: We show an OK message with a handler, so we can chain the loading of the offline form off the button press.
				OMDialogs.showOKMessage(message: NSLocalizedString("Update successful", comment: ""),
																title: NSLocalizedString("SCAF Update", comment: ""),
																handler: { (parameters) -> Void in
																	self.omnisInterface.scafHandler.loadOfflineForm()
																})
			return true
		// End jmg0954
		}
		
		return false;
	}
	
	func onOfflineModeConfigured(htmlPath: String!) {
		offlineDir = htmlPath
	}
	
}

// MARK: PullToRefreshViewDelegate
extension MainViewController: PullToRefreshViewDelegate
{
	func pull(toRefreshViewShouldRefresh view: PullToRefreshView!) {
		view.finishedLoading()
		openActionsMenu()
	}
}


