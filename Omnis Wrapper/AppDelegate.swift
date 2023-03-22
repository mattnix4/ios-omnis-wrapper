//
//  AppDelegate.swift
//  Omnis Wrapper
//
//  Created by Jason Gissing on 12/12/2017.
//  Copyright © 2017 Omnis Software. All rights reserved.
//

import UIKit
import OmnisAppInterface

extension Notification.Name
{
	public static let OmnisNotificationClicked = Notification.Name("OmnisNotificationClicked")
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

	public var launchNotificationData: [String: Any]?
	
	var window: UIWindow?
	#if PUSH_NOTIFICATIONS
	var pushNotificationsManager: OMPushNotificationManager?
	var mNotificationRegisterCallback: ((_ success: Bool, _ error: Error?) -> Void)?
	#endif
	

	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
		
		// Check if we were launched from a click on a notification:
		launchNotificationData = launchOptions?[UIApplicationLaunchOptionsKey.remoteNotification] as? [String: Any]
		
		// Before iOS 10, we may have simulated a Remote Notification with a Local Notification - check for that case if the above came up empty:
		if #available(iOS 10.0, *) {} else {
			if (launchNotificationData == nil) {
				launchNotificationData = launchOptions?[UIApplicationLaunchOptionsKey.localNotification] as? [String: Any]
			}
		}

		// Override point for customization after application launch.
		#if PUSH_NOTIFICATIONS
		pushNotificationsManager = OMPushNotificationManager(withDelegate: self, options: OMPushNotificationOptions(omnisServer: SettingsHelper.shared.getSettingString(name: SettingsHelper.SETTING_PUSHNOTIFICATIONSERVER, defaultValue: "")!, deviceID: OmnisInterface.DEVICE_ID))
		
		// The OmnisInterface Comms Delegate broadcasts a message which we catch here when notifications are enabled
		NotificationCenter.default.addObserver(self, selector: #selector(self.notificationsEnabledChanged), name: .OmnisNotificationsEnabledChanged, object: nil)
		#endif
		return true
	}

	func applicationWillResignActive(_ application: UIApplication) {
		// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
		// Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
	}

	func applicationDidEnterBackground(_ application: UIApplication) {
		// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
		// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
	}

	func applicationWillEnterForeground(_ application: UIApplication) {
		// Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
	}

	func applicationDidBecomeActive(_ application: UIApplication) {
		// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
	}

	func applicationWillTerminate(_ application: UIApplication) {
		// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
	}
	
	
	

}

#if PUSH_NOTIFICATIONS
// MARK: Push Notification Handling
extension AppDelegate
{
	
	func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any]) {
		// If you are receiving a notification message while your app is in the background,
		// this callback will not be fired till the user taps on the notification launching the application.
		pushNotificationsManager?.handleLegacyNotification(data: userInfo, localNotification: false)
		
		// With swizzling disabled you must let Messaging know about the message, for Analytics
		// Messaging.messaging().appDidReceiveMessage(userInfo)
	}
	
	func application(_ application: UIApplication, didReceive notification: UILocalNotification) {
		// Called when a local notification (added for iOS < 10) is created or clicked
		pushNotificationsManager?.handleLegacyNotification(data: notification.userInfo, localNotification: true)
	}
	
	func application(_ application: UIApplication, didRegister notificationSettings: UIUserNotificationSettings) {
		mNotificationRegisterCallback?(notificationSettings.types.rawValue > 0, nil)
	}
	
	@objc
	func notificationsEnabledChanged(notification: Notification)
	{
		let enable = notification.userInfo?["enable"] as? Bool ?? false
		pushNotificationsManager?.enablePushNotifications(enable)
	}
}

extension AppDelegate: OMPushNotificationDelegate
{
	func pushNotificationClickedWithPayload(dataPayload: [AnyHashable : Any]?) {
		NotificationCenter.default.post(name: .OmnisNotificationClicked, object: nil, userInfo: dataPayload) // Broadcast a message, which is handled in MainViewController
	}
	
	func pushNotificationDataOnlyNotificationReceived(dataPayload: [AnyHashable : Any]?) {
		/* Do nothing for now in this situation. (Data-only, or 'silent' notifications are not supported by default)
		
		As an Omnis developer, you could implement this method, e.g. to call a particular method in your form perhaps, if you know it is going to exist.
		
		You would also need to set the 'allowDataOnlyMessages' option when creating the OMPushNotificationManager
		*/
		print("Data-only notification received, but not handled: \(dataPayload ?? [:])")
	}
	
}


#endif

