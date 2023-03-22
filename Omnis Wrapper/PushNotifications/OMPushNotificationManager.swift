//
//  OMPushNotificationManager.swift
//  OmnisJSWrapper_PushNotifications
//
//  Created by Jason Gissing on 27/06/2018.
//  Copyright © 2018 Omnis Software. All rights reserved.
//
// Certified for use with Firebase v 5.18.2 (later versions _may_ also be OK)

import UIKit
import FirebaseCore
import UserNotifications
import AudioToolbox


/// This delegate's methods will be called when notifications are clicked, or when data-only notifications arrive.
public protocol OMPushNotificationDelegate {
	
	/// A visual notification has been clicked.
	///
	/// - Parameter dataPayload: A dictionary of the data payload sent with the notification.
	func pushNotificationClickedWithPayload(dataPayload: [AnyHashable: Any]?)
	
	/// A data-only notification has been received.
	///
	/// - Parameter dataPayload: A dictionary of the data payload sent with the notification.
	func pushNotificationDataOnlyNotificationReceived(dataPayload: [AnyHashable: Any]?)
}


/// Options to be passed to OMPushNotificationManager's init()
public struct OMPushNotificationOptions {
	public var omnisPushNotificationServer: String // The Omnis Push Notification server. E.g: "http://192.168.1.123:9816"
	public var omnisPushNotificationGroups: Int
	public var deviceID: String // The unique identifier for this device. Should remain constant between launches.
	public var allowDataOnlyMessages = false
	
	/// Create an options object to pass to the OMPushNotificationManager.
	///
	/// - Parameters:
	///   - omnisServer: The Omnis Push Notification server. E.g: "http://192.168.1.123:9816"
	///   - deviceID: The unique identifier for this device. (OmnisInterface.DEVICE_ID for example)
	///   - omnisGroups: A bitmask of the notification groups this device is part of.
	public init(omnisServer: String, deviceID: String, omnisGroups: Int = 0) {
		self.deviceID = deviceID
		self.omnisPushNotificationServer = omnisServer
		self.omnisPushNotificationGroups = omnisGroups
	}
}


/// A helper class to manage the Firebase lifecycle, and report messages to its delegate at the appropriate points.
public class OMPushNotificationManager: NSObject {
	
	let PREF_PUSH_TOKEN_PENDING = "pushnotifications_token_send_pending"
	let PREF_PUSH_NOTIFICATIONS_ENABLED = "pushnotifications_enabled"
	let kGCMMessageIDKey = "gcm.message_id"
	
	let omnisPushNotificationOptions: OMPushNotificationOptions
	var mNotificationsEnabled = false
	let delegate: OMPushNotificationDelegate
	var mEnablingNotifications = false
	var mQueuedDisable = false // If true, we have tried to disable notifications while in the process of enabling, and need to disable once the enabling process has finished.
	var creatingLocalNotification = false
	
	
	public init(withDelegate: OMPushNotificationDelegate, options: OMPushNotificationOptions)
	{
		self.omnisPushNotificationOptions = options
		self.delegate = withDelegate
		
		super.init()
		
		let alreadyEnabled = UserDefaults.standard.bool(forKey: PREF_PUSH_NOTIFICATIONS_ENABLED)
		
		// Use Firebase library to configure APIs
		FirebaseApp.configure()
		
		// If the app had previously enabled notifications, enable notifications now.
		if alreadyEnabled {
			enablePushNotifications(true, force: true)
		}
		
	}
	
	/// Should be called by devices running iOS < 10 when a notification is received while the app is in the foreground,
	/// or is clicked while the app is in the background/stopped.
	/// Call this in response to application(_:didReceiveRemoteNotification:)
	///
	/// - Parameters:
	///   - data: The data payload of the notification.
	///   - localNotification: Whether this is a local (true) or remote (false) notification.
	public func handleLegacyNotification(data: [AnyHashable: Any]?, localNotification: Bool)
	{
		if (localNotification && creatingLocalNotification) { // Ignore any call to this method resulting from adding a local notification (as opposed to clicking it)
			creatingLocalNotification = false
			return
		}
		
		// If the application was in the foreground when it received a remote notification, we need to manually create a local notification to show the user:
		if UIApplication.shared.applicationState == .active
		{
			// Start jmg0592
			let notificationPayload: [AnyHashable: Any] = data?["aps"] as? [AnyHashable: Any] ?? [:]
			
			if (!localNotification)
			{
				// If the app was already in the foreground when it received the notification, create a new 'Toast' (3rd party notification banner approximation) notification to display it:
				// This is necessary as the standard notification will not appear as a banner/alert as iOS (< 10) prevents notifications being shown in this way if the app is in the foreground (it will just be sent to the notification centre).
				
				handleBadgeAndSound(notificationData: notificationPayload) // jmg0591: Handle the badge & sound, regardless of whether it contains a visual component.
				
				if let alert = notificationPayload["alert"]
				{
					let alertTitle = (alert as? [AnyHashable: Any])?["title"] ?? ""
					let alertBody = (alert as? [AnyHashable: Any])?["body"] ?? (alert as? String ?? "") // alert may just be a String if just a body was sent.
					
					let notification = sendLocalNotification(message: alertBody as? String, title: alertTitle as? String, data: data)
					
					let options: [String: Any] = [
						kCRToastTextKey: alertTitle,
						kCRToastSubtitleTextKey: alertBody,
						kCRToastTextAlignmentKey: NSNumber(value: NSTextAlignment.left.rawValue),
						kCRToastSubtitleTextAlignmentKey: NSNumber(value: NSTextAlignment.left.rawValue),
						kCRToastBackgroundColorKey: UIColor.black.withAlphaComponent(0.7),
						kCRToastSubtitleTextColorKey: UIColor.white,
						kCRToastAnimationInTypeKey: NSNumber(value: CRToastAnimationType.linear.rawValue),
						kCRToastAnimationOutTypeKey: NSNumber(value: CRToastAnimationType.linear.rawValue),
						kCRToastAnimationInDirectionKey: NSNumber(value: CRToastAnimationDirection.top.rawValue),
						kCRToastAnimationOutDirectionKey: NSNumber(value: CRToastAnimationDirection.top.rawValue),
						kCRToastTimeIntervalKey: 5.0,  // Show for 5s
						kCRToastNotificationTypeKey: NSNumber(value: CRToastType.navigationBar.rawValue),
						kCRToastNotificationPresentationTypeKey: NSNumber(value: CRToastPresentationType.cover.rawValue),
						kCRToastImageKey: imageWithRoundedCorners(cornerRadius: 5.0, usingImage: UIImage.init(named: "AppIcon29x29")) ?? NSNull(),
						kCRToastInteractionRespondersKey: [
							CRToastInteractionResponder(interactionType: .tap, automaticallyDismiss: true, block: {(type) in
								UIApplication.shared.cancelLocalNotification(notification) // Cancel the local notification we sent to the Notification Centre
								self.delegate.pushNotificationClickedWithPayload(dataPayload: data)
							})
						]
					]
				
					CRToastManager.showNotification(options: options, completionBlock: nil)
				}
			}
				// End jmg0592
			else {
				// If the application is active and we're being notified of a local notification, assume that is the one we just created, and ignore it.
				
			}
		}
		else // The user clicked on the notification (which it received while it was in the background/stopped, or was recreated as a local notification):
		{
			self.delegate.pushNotificationClickedWithPayload(dataPayload: data) // Tell the delegate that a notification was clicked
		}
	}
	
	func sendLocalNotification(message: String?, title: String?, data: [AnyHashable: Any]? = nil) -> UILocalNotification {
		let notification = UILocalNotification()
		
		notification.alertBody = message
		notification.alertTitle = title
		notification.userInfo = data
		
		self.creatingLocalNotification = true
		
		UIApplication.shared.presentLocalNotificationNow(notification)
		print("Local Notification Created. UserInfo: \(data ?? [:])")
		
		return notification
	}
	
	public func enablePushNotifications(_ enable: Bool, force: Bool = false)
	{
		
		if (Thread.current != Thread.main) { // Enforce running on main thread to avoid race conditions
			DispatchQueue.main.async {
				self.enablePushNotifications(enable, force: force)
			}
			return
		}
		
		if (mEnablingNotifications) { // If we're currently in the process of enabling, just set the flag to say if we need to disable once finished.
			mQueuedDisable = !enable
			print("Queued notifications disable: \(mQueuedDisable)")
			return;
		}
		
		if (enable == mNotificationsEnabled && !force) {
			return // Value of enabled unchanged
		}
		
		
		if (enable)
		{
			mEnablingNotifications = true
			print("Enabling notifications...")
			
			let finishedEnabling: (_ success: Bool) -> Void = { (success) in
				DispatchQueue.main.async { // Run on main thread, to keep writes to mEnablingNotifications & mQueuedDisable to the same thread.
					self.mEnablingNotifications = false;
					self.mNotificationsEnabled = success
					print("Notifications enabled. Success: \(success)")
					
					if (self.mQueuedDisable) {
						print("Processing queued disable of notifications")
						self.mQueuedDisable = false;
						self.enablePushNotifications(false)
					}
				}
				
			}
			
			registerForNotifications(completionHandler: { (success, error) in
				if (success) {
					UserDefaults.standard.set(true, forKey: self.PREF_PUSH_NOTIFICATIONS_ENABLED)
					
					// Add observer for InstanceID token refresh callback.
					NotificationCenter.default.addObserver(self, selector: #selector(self.tokenRefreshNotification(notification:)), name: NSNotification.Name.InstanceIDTokenRefresh, object: nil)
					
					self.connectToFcm() { (success, error) in // Connect to Firebase Cloud Messaging to receive data notifications
						if (success) {
							self.sendToken( nil) { (success, error) in
								finishedEnabling(true)
							}
						}
						else {
							finishedEnabling(false)
						}
					}
				}
				else {
					// Unable to register for notifications.
					// Probably the user has declined permission.
					finishedEnabling(false)
				}
			})
			
		}
		else
		{
			UserDefaults.standard.set(false, forKey: PREF_PUSH_NOTIFICATIONS_ENABLED)
			NotificationCenter.default.removeObserver(self, name: NSNotification.Name.InstanceIDTokenRefresh, object: nil)
			DispatchQueue.main.async(execute: {
				UIApplication.shared.unregisterForRemoteNotifications() // Must run on main thread
			})
			disconnectFromFcm()
			setTokenSendPending(false) // Cancel any pending sending of token to Omnis server.
			mNotificationsEnabled = false;
			print("Notifications disabled")
		}
		
	}
	
	
	// MARK: Private methods
	
	private func handleBadgeAndSound(notificationData: [AnyHashable: Any]!)
	{
		if let aps = notificationData["aps"] as? [AnyHashable: Any]
		{
			// Start jmg0589 If a badge number was provided, set that:
			if let badgeNumber = aps["badge"] as? String { // If the notification includes a badge number, set that
				UIApplication.shared.applicationIconBadgeNumber = Int(badgeNumber)!
			}
			// End jmg0589
			
			// SOUND
			if let sound = aps["sound"] as? String{
				
				let fileParts = sound.components(separatedBy: ".")
				var fileName = fileParts[0]
				var fileType = "wav" // default filetype to wav.
				
				
				if (fileParts.count > 1) {
					fileType = fileParts[1];
				}
					// Start jmg0597
				else if (fileParts[0] == "default") { // If we receive "default", we should play the default notification sound.
					fileName = "notify" // We don't have access to iOS' notification sound, so just play notify.wav.
				}
				// End jmg0597
				
				if let soundPath = Bundle.main.path(forResource: fileName, ofType: fileType)
				{
					var sound = SystemSoundID()
					AudioServicesCreateSystemSoundID(URL(fileURLWithPath: soundPath) as CFURL, &sound)
					AudioServicesPlaySystemSound(sound);
				}
			}
		}
	}
	
	
	@objc
	private func tokenRefreshNotification(notification: NSNotification)
	{
		sendToken()
	}
	
	/**
	Sends the Firebase token for this app to the Omnis Server.
	*/
	private func sendToken(_ newToken: String? = nil, completionHandler: ((_ success: Bool, _ error: Error?) -> Void)? = nil)
	{
		if newToken == nil { // If no token was supplied, fetch it (asynchronously), then call this method again, providing the token.
			InstanceID.instanceID().instanceID(handler: { (result, error) in
				if let error = error {
					print("Error fetching remote instance ID: \(error)")
					completionHandler?(false, error)
				} else if let result = result {
					self.sendToken(result.token, completionHandler: completionHandler)
				}
			})
		}
		else // We have a token
		{
			print("Sending remote instance ID token: \(newToken!)")
			setTokenSendPending(true)
			
			guard let requestUrl = URL(string: omnisPushNotificationOptions.omnisPushNotificationServer + "/api/pushnotifications/pushnotifications/register") else {
				print("Invalid omnisPushNotificationServer URL: \(omnisPushNotificationOptions.omnisPushNotificationServer)"); return
			}
			
			guard let projectName = FirebaseOptions.defaultOptions()?.projectID else {
				print("Unable to get Firebase Project ID"); return
			}
			
			
			let postData: [String: Any] = [
				"TOKEN": newToken!,
				"HWID": omnisPushNotificationOptions.deviceID,
				"OSType": 2, // 2 Means iOS
				"AppGroup": projectName,
				"Groups": omnisPushNotificationOptions.omnisPushNotificationGroups
			]
			
			sendJSONPost(toURL: requestUrl, postData: postData, completionHandler: { (responseData, response, error) in
				if let error = error {
					print("Push Notification Send Token Error: \(error)")
				}
				else if let responseData = responseData {
					let responseString = String(data: responseData, encoding: .utf8)
					if (responseString == "OK") { // Successfully registered the token with the server. Remove the pending status of the token:
						self.setTokenSendPending(false)
					}
				}
				completionHandler?(error != nil, error)
			})
			
		}
		
	}
	
	private func setTokenSendPending(_ pending: Bool)
	{
		UserDefaults.standard.set(pending, forKey: PREF_PUSH_TOKEN_PENDING)
	}
	
	private func getTokenSendPending() -> Bool
	{
		return UserDefaults.standard.bool(forKey: PREF_PUSH_TOKEN_PENDING)
	}
	
	/**
	Register for notifications (iOS 8+)
	*/
	private func registerForNotifications(completionHandler: @escaping (Bool, Error?) -> Void)
	{
		// iOS 10 or later
		if #available(iOS 10.0, *) {

			let notificationCenter = UNUserNotificationCenter.current()
			notificationCenter.requestAuthorization(options: [.alert, .sound, .badge], completionHandler: {(success, error) in
				if (success) {
					// For iOS 10 display notification (sent via APNS)
					notificationCenter.delegate = self;
					// For iOS 10 data message (sent via FCM)
					Messaging.messaging().delegate = self

					DispatchQueue.main.async(execute: {
						UIApplication.shared.registerForRemoteNotifications() // Must run on main thread
					})
					
				}
				completionHandler(success, error)
			})
		}
		else { // Fallback on earlier versions
		
			// AppDelegate is called with result of requesting permission for notifications. Register a callback with that:
			if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
				appDelegate.mNotificationRegisterCallback = {(success, error) in
					
					UIApplication.shared.registerForRemoteNotifications()
					completionHandler(success, error)
					appDelegate.mNotificationRegisterCallback = nil
				}
			}
			
			let settings = UIUserNotificationSettings(types: [.sound, .alert, .badge], categories: nil)
			UIApplication.shared.registerUserNotificationSettings(settings) // AppDelegate will be called with result, we then continue in the callback above
		}
	}
	
	
	/**
	Connect to Firebase Cloud Messaging to receive notifications while the app is open.
	*/
	private func connectToFcm(completionHandler: @escaping (_ success: Bool, _ error: Error?) -> Void)
	{
		if (!self.omnisPushNotificationOptions.allowDataOnlyMessages) { // Direct socket connection only required for data-only messages, while app is open.
			completionHandler(true, nil)
			return
		}
		
		InstanceID.instanceID().instanceID(handler: { (result, error) in //  TODO: Is this necessary? Could just set shouldEstablishDirectChannel?
			if let error = error {
				// Won't connect since there is no token
				print("Error fetching remote instange ID: \(error)")
				completionHandler(false, error)
			}
			else if let result = result {
				print("Remote instance ID token: \(result.token)")
				// Disconnect previous FCM connection if it exists.
				Messaging.messaging().shouldEstablishDirectChannel = false // TODO: Necessary now?
				
				Messaging.messaging().shouldEstablishDirectChannel = true
				completionHandler(true, nil)
			}
		})
		
	}
	
	
	/**
	Disconnect from Firebase Cloud Messaging.
	*/
	private func disconnectFromFcm()
	{
		if (self.omnisPushNotificationOptions.allowDataOnlyMessages) {
			Messaging.messaging().shouldEstablishDirectChannel = false
			print("Disconnected from FCM")
		}
	}
	
	
	private func imageWithRoundedCorners(cornerRadius: CGFloat, usingImage: UIImage?) -> UIImage?
	{
		if let usingImage = usingImage {
			let frame = CGRect(x: 0, y: 0, width: usingImage.size.width, height: usingImage.size.height)
			
			// Begin a new image that will be the new image with the rounded corners
			// (here with the size of an UIImageView)
			UIGraphicsBeginImageContextWithOptions(usingImage.size, false, usingImage.scale);
			
			// Add a clip before drawing anything, in the shape of an rounded rect
			UIBezierPath.init(roundedRect: frame, cornerRadius: cornerRadius).addClip()
			// Draw your image
			usingImage.draw(in: frame)
			
			// Get the image, here setting the UIImageView image
			let image = UIGraphicsGetImageFromCurrentImageContext();
			
			// Lets forget about that we were drawing
			UIGraphicsEndImageContext();
			
			return image;
		}
		else {
			return nil
		}
	}
	
	
	/**
	Sends a HTTP POST message with JSON data as the content.
	
	@param toURL URL to send the POST to
	@param postData Dictionary of data to convert to JSON
	@param completionHandler Function to call on completion of the request.
	*/
	private func sendJSONPost(toURL: URL, postData: [AnyHashable: Any], completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void)
	{
		do {
			let jsonData = try JSONSerialization.data(withJSONObject: postData, options: .prettyPrinted)
			
			let theRequest = NSMutableURLRequest(url: toURL, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 30)
			theRequest.httpMethod = "POST"
			theRequest.setValue("\(jsonData.count)", forHTTPHeaderField: "Content-Length")
			theRequest.setValue("application/json", forHTTPHeaderField: "Content-Type") // We're sending the body as JSON text
			theRequest.httpBody = jsonData
			
			let configuration = URLSessionConfiguration.ephemeral
			configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
			
			URLSession(configuration: configuration).dataTask(with: theRequest as URLRequest, completionHandler: completionHandler).resume()
		}
		catch (let error) {
			print("SendJSONPost error: \(error)")
		}
	
	}
}

// MARK: Firebase messaging delegate
extension OMPushNotificationManager: MessagingDelegate
{
	public func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
		// Note: This callback is fired at each app startup and whenever a new token is generated.
		sendToken(fcmToken)
	}
	
	public func messaging(_ messaging: Messaging, didReceive remoteMessage: MessagingRemoteMessage) {
		// This is called when the app receives a data-only message while it's in the foreground.
		delegate.pushNotificationDataOnlyNotificationReceived(dataPayload: remoteMessage.appData)
	}
}

// MARK: Native Notification delegate
// Used for iOS 10+
@available(iOS 10.0, *)
extension OMPushNotificationManager: UNUserNotificationCenterDelegate
{
	// Handle notification messages after display notification is tapped by the user.
	public func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
		delegate.pushNotificationClickedWithPayload(dataPayload: response.notification.request.content.userInfo)
		completionHandler();
	}
	
	// Handle incoming notification messages while app is in the foreground.
	public func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
		
		handleBadgeAndSound(notificationData: notification.request.content.userInfo) // jmg0591
		// Display the notification to the user:
		completionHandler(.alert);
	}
}


