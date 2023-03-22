/********  Changes **********
 Date       Edit        Fault       Description
 05-Jun-17	jmg0598									Added Push Notification Server setting.
 05-Jun-17	jmg0597			WR/WR/271		Did not respect Firebase 'default' sound in push notifications when running in foreground.
 01-Jun-17	jmg0592									Show custom Toast when running in foreground on iOS < 10 when a push notification is received.
 31-May-17	jmg0591			WR/WR/269		Notification sounds did not play while the app was in the foreground.
 30-May-17	jmg0589			WR/WR/268		Notifications did not update badge number if received while app was open.
 
 ***************************/

//
//  TLPushNotificationManager
//  TLDevice
//
//  Created by Jason Gissing on 11/01/2017.
//  Copyright © 2017 TigerLogic. All rights reserved.
//
#ifdef PUSH_NOTIFICATIONS

#import "Firebase.h"
#import "TLTools.h"
#import "AppDelegate.h"
#import "CRToast.h" // jmg0592
#import <AudioToolbox/AudioToolbox.h> // jmg0591
#import <UserNotifications/UserNotifications.h>

// Implement UNUserNotificationCenterDelegate to receive display notification via APNS for devices
// running iOS 10 and above. Implement FIRMessagingDelegate to receive data message via FCM for
// devices running iOS 10 and above.
@interface TLPushNotificationManager () <UNUserNotificationCenterDelegate, FIRMessagingDelegate>
- (void) handleBadgeAndSound: (NSDictionary*) notificationData; // jmg0591
@end


@implementation TLPushNotificationManager

NSString* const PREF_PUSH_TOKEN_PENDING = @"pushnotifications_token_send_pending";
NSString* const PREF_PUSH_NOTIFICATIONS_ENABLED = @"pushnotifications_enabled"; // Used on startup to set up notifications if previously enabled.
NSString *const kGCMMessageIDKey = @"gcm.message_id";
BOOL mNotificationsEnabled = NO;

-(instancetype) initWithDelegate: (id<TLPushNotificationsDelegate>) delegate
{
	self = [super init];
	
	if (self != nil) {
		self.delegate = delegate;
		[self initialise];
	}
	
	return self;
}

-(void) initialise
{
	
	NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
	BOOL alreadyEnabled = [ud boolForKey:PREF_PUSH_NOTIFICATIONS_ENABLED];
	
	// Use Firebase library to configure APIs
	[FIRApp configure];
	
	
	// If the app had previously enabled notifications, enable notifications now.
	if (alreadyEnabled)
		[self enablePushNotifications:YES];
	
	
	// Check to see if we failed to send the token to the Omnis server previously. If so, try again now:
	if ([self getTokenSendPending])
		[self sendToken];
}


- (void) enablePushNotifications: (BOOL) enable
{
	NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
	[ud setBool:enable forKey:PREF_PUSH_NOTIFICATIONS_ENABLED];
	
	if (enable)
	{
		if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_7_1)
			[self registerForNotificationsIOS7];
		else
			[self registerForNotifications];
		
		if (!mNotificationsEnabled)
			//	 Add observer for InstanceID token refresh callback.
			[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tokenRefreshNotification:)
																								 name:kFIRInstanceIDTokenRefreshNotification object:nil];
		
		[self connectToFcm]; // Connect to Firebase Cloud Messaging to receive data notifications
	}
	else
	{
		[[NSNotificationCenter defaultCenter] removeObserver:self name:kFIRInstanceIDTokenRefreshNotification object:nil];
		[[UIApplication sharedApplication] unregisterForRemoteNotifications];
		[self disconnectFromFcm];
		[self setTokenSendPending:NO]; // Cancel any pending sending of token to Omnis server.
	}
	
	mNotificationsEnabled = enable;
}


/**
 Register for notifications (iOS 8+)
 */
-(void) registerForNotifications
{
	if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_9_x_Max)
	{
		UIUserNotificationType allNotificationTypes = (UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge);
		UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:allNotificationTypes categories:nil];
		[[UIApplication sharedApplication] registerUserNotificationSettings:settings];
	}
	else
	{
  // iOS 10 or later
		UNAuthorizationOptions authOptions = UNAuthorizationOptionAlert | UNAuthorizationOptionSound | UNAuthorizationOptionBadge;
		[[UNUserNotificationCenter currentNotificationCenter] requestAuthorizationWithOptions:authOptions completionHandler:^(BOOL granted, NSError * _Nullable error) {
		}];
		
		// For iOS 10 display notification (sent via APNS)
		[UNUserNotificationCenter currentNotificationCenter].delegate = self;
		// For iOS 10 data message (sent via FCM)
		[FIRMessaging messaging].remoteMessageDelegate = self;
	}
	
	[[UIApplication sharedApplication] registerForRemoteNotifications];
}


/**
 Register for notifications on old (pre-iOS 8) devices
 */
-(void) registerForNotificationsIOS7
{
	// iOS 7.1 or earlier. Disable the deprecation warnings.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
	UIRemoteNotificationType allNotificationTypes =
	(UIRemoteNotificationTypeSound |
	 UIRemoteNotificationTypeAlert |
	 UIRemoteNotificationTypeBadge);
	[[UIApplication sharedApplication] registerForRemoteNotificationTypes:allNotificationTypes];
#pragma clang diagnostic pop
}



/**
 Connect to Firebase Cloud Messaging to receive notifications whie the app is open.
 */
- (void)connectToFcm {
	// Won't connect since there is no token
	if (![[FIRInstanceID instanceID] token]) {
		return;
	}
	
	// Disconnect previous FCM connection if it exists.
	[[FIRMessaging messaging] disconnect];
	
	[[FIRMessaging messaging] connectWithCompletion:^(NSError * _Nullable error) {
		if (error != nil) {
			NSLog(@"Unable to connect to FCM. %@", error);
		} else {
			NSLog(@"Connected to FCM.");
			NSLog(@"Token: %@", [[FIRInstanceID instanceID] token]);
		}
	}];
}


/**
 Disconnect from Firebase Cloud Messaging.
 */
-(void) disconnectFromFcm
{
	[[FIRMessaging messaging] disconnect];
	NSLog(@"Disconnected from FCM");
}

- (void) didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
	
	// Use 'unkown' type, to automatically detect whether using a dev or production build.
	[[FIRInstanceID instanceID] setAPNSToken:deviceToken type:FIRInstanceIDAPNSTokenTypeUnknown];
}

/**
 Sets the badge number, and plays any sound provided in the passed notifictionData payload.
 */ // jmg0591
- (void) handleBadgeAndSound: (NSDictionary*) notificationData
{
	if (notificationData && notificationData[@"aps"]) {
		
		// Start jmg0589 If a badge number was provided, set that:
		if (notificationData[@"aps"][@"badge"]) // If the notification includes a badge number, set that
		{
			NSString *badgeNumber = notificationData[@"aps"][@"badge"];
			[[UIApplication sharedApplication] setApplicationIconBadgeNumber:[badgeNumber integerValue]];
		}
		// End jmg0589
		
		// SOUND
		if (notificationData[@"aps"][@"sound"]) {
			
			NSArray<NSString*> *fileParts = [notificationData[@"aps"][@"sound"] componentsSeparatedByString:@"."];
			NSString *fileName = fileParts[0];
			NSString *fileType = @"wav"; // default filetype to wav.
			
			
			if (fileParts.count > 1)
				fileType = fileParts[1];
			// Start jmg0597
			else if ([fileParts[0] isEqualToString:@"default"]) // If we receive "default", we should play the default notification sound.
				fileName = @"notify"; // We don't have access to iOS' notification sound, so just play notify.wav.
			// End jmg0597
			
			NSString *soundPath = [[NSBundle mainBundle] pathForResource:fileName ofType:fileType];
			
			if ( soundPath != nil) { // jmg0168
				SystemSoundID sound;
				AudioServicesCreateSystemSoundID((__bridge CFURLRef)[NSURL fileURLWithPath:soundPath],&sound);
				AudioServicesPlaySystemSound(sound);
			}
		}
	}
}

/**
 Called by devices running iOS < 10 when a notification is received while the app is in the foreground, 
 or is clicked while the app is in the background/stopped.

 @param application The application.
 @param data The data payload of the notification.
 @param localNotification Whether this is a local (true) or remote (false) notification.
 */
- (void) application: (UIApplication*) application receivedLegacyNotificationData: (NSDictionary*) data fromLocalNotification: (BOOL) localNotification
{
	// If the application was in the foreground when it received a remote notification, we need to manually create a local notification to show the user:
	if ( application.applicationState == UIApplicationStateActive )
	{
		// Start jmg0592
		NSDictionary *notificationPayload;
		if (data && data[@"aps"])
			notificationPayload = data[@"aps"];
		
		if (!localNotification)
		{
			// If the app was already in the foreground when it received the notification, create a new 'Toast' (3rd party notification banner approximation) notification to display it:
			// This is necessary as the standard notification will not appear as a banner/alert as iOS (< 10) prevents notifications being shown in this way if the app is in the foreground (it will just be sent to the notification centre).
			
			[self handleBadgeAndSound:notificationPayload]; // jmg0591: Handle the badge & sound, regardless of whether it contains a visual component.
			
			if (notificationPayload && notificationPayload[@"alert"])
			{
				__block BOOL notificationDismissed = NO;
			
				
				NSDictionary *options = @{
																	kCRToastTextKey : notificationPayload[@"alert"][@"title"],
																	kCRToastSubtitleTextKey: notificationPayload[@"alert"][@"body"],
																	kCRToastTextAlignmentKey : @(NSTextAlignmentLeft),
																	kCRToastSubtitleTextAlignmentKey : @(NSTextAlignmentLeft),
																	kCRToastBackgroundColorKey : [[UIColor blackColor] colorWithAlphaComponent:0.7],
																	kCRToastSubtitleTextColorKey: [UIColor whiteColor],
																	kCRToastAnimationInTypeKey : @(CRToastAnimationTypeLinear),
																	kCRToastAnimationOutTypeKey : @(CRToastAnimationTypeLinear),
																	kCRToastAnimationInDirectionKey : @(CRToastAnimationDirectionTop),
																	kCRToastAnimationOutDirectionKey : @(CRToastAnimationDirectionTop),
																	kCRToastTimeIntervalKey : @5.0, // Show for 5s
																	kCRToastNotificationTypeKey: @(CRToastTypeNavigationBar),
																	kCRToastNotificationPresentationTypeKey: @(CRToastPresentationTypeCover),
																	kCRToastImageKey: [TLTools imageWithRoundedCorners:5 usingImage:[UIImage imageNamed:@"AppIcon29x29"]],
																	kCRToastInteractionRespondersKey: @[[CRToastInteractionResponder
																																			 interactionResponderWithInteractionType: CRToastInteractionTypeTap
																																			 automaticallyDismiss:YES
																																			 block:^(CRToastInteractionType interactionType)
				{
					notificationDismissed = YES; // Set a flag to indicate we don't want to send the notification to notification centre (we are consuming it now).
					[self.delegate pushNotifications:self notificationClickedWithPayload:data];
				}]]
																	};
				
				[CRToastManager showNotificationWithOptions:options
																		completionBlock: ^{
																			// Send the notification to the Notification Centre, if the Toast/Banner message wasn't clicked
																			if (!notificationDismissed) {
																				UILocalNotification* notification = [[UILocalNotification alloc] init];
																				
																				NSDictionary* alert = notificationPayload[@"alert"];
																				NSString* body = alert[@"body"];
																				NSString* title = alert[@"title"];
																				
																				[notification setAlertBody:body];
																				[notification setAlertTitle:title];
																				[notification setUserInfo:data];
																				
																				[application presentLocalNotificationNow:notification];
																				
																				NSLog(@"Local Notification Created. UserInfo: %@", data);
																			}
																		}];
				
			}
		}
		// End jmg0592
		
		else {
			// If the application is active and we're being notified of a local notification, assume that is the one we just created, and ignore it.
			
		}
	}
	else // The user clicked on the notification (which it received while it was in the background/stopped, or was recreated as a local notification):
	{
		[self.delegate pushNotifications:self notificationClickedWithPayload:data]; // Tell the delegate that a notification was clicked
	}

}

// [END receive_message]


// [START ios_10_message_handling]
// Receive displayed notifications for iOS 10 devices.

// Handle incoming notification messages while app is in the foreground.
- (void)userNotificationCenter:(UNUserNotificationCenter *)center
			 willPresentNotification:(UNNotification *)notification
				 withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler
{
	NSDictionary *userInfo = notification.request.content.userInfo; // jmg0591
	[self handleBadgeAndSound:userInfo]; // jmg0591
	
	// Display the notification to the user:
	completionHandler(UNNotificationPresentationOptionAlert);
	
}

// Handle notification messages after display notification is tapped by the user.
- (void)userNotificationCenter:(UNUserNotificationCenter *)center
didReceiveNotificationResponse:(UNNotificationResponse *)response
				 withCompletionHandler:(void (^)())completionHandler
{
	NSDictionary *userInfo = response.notification.request.content.userInfo;

	[self.delegate pushNotifications:self notificationClickedWithPayload:userInfo];
	
	completionHandler();
}
// [END ios_10_message_handling]


// [START ios_10_data_message_handling]
// Receive data message on iOS 10 devices while app is in the foreground.
- (void)applicationReceivedRemoteMessage:(FIRMessagingRemoteMessage *)remoteMessage {
	// Print full message
	NSLog(@"%@", remoteMessage.appData);
//	[self notificationClickedWithDataPayload:remoteMessage.appData];
	[self.delegate pushNotifications:self dataOnlyNotificationReceived:remoteMessage.appData];
}
// [END ios_10_data_message_handling]



// [START refresh_token]
- (void)tokenRefreshNotification:(NSNotification *)notification {
	// Note that this callback will be fired everytime a new token is generated, including the first
	// time. So if you need to retrieve the token as soon as it is available this is where that
	// should be done.
	
	
	// Connect to FCM since connection may have failed when attempted before having a token.
	[self connectToFcm];
	
	[self sendToken]; // Send the token to Omnis
}
// [END refresh_token]



/**
 Sends the Firebase token for this app to the Omnis Server.
 */
-(void) sendToken
{
	NSString* newToken = [[FIRInstanceID instanceID] token];
	if (newToken == nil) {
		NSLog(@"Firebase token is null");
		return;
	}
	
	[self setTokenSendPending:YES];
	
	AppDelegate* appDelegate = (AppDelegate *) [[UIApplication sharedApplication] delegate];

	NSString* pushNotificationServer = [appDelegate getPushNotificationServer]; // jmg0598
	NSString* requestUrl = [pushNotificationServer stringByAppendingString:@"/api/pushnotifications/pushnotifications/register"];
	
	// Don't seem to be able to get the Project ID directly. This seems to be the first part of storageBucket though, so get it via that:
	NSString* storageBucket = [[FIROptions defaultOptions] storageBucket];
	NSString* projectName = [storageBucket substringToIndex: [storageBucket rangeOfString:@"."].location];
	
	NSDictionary* postData = [NSDictionary dictionaryWithObjectsAndKeys:
														newToken, @"TOKEN",
														[appDelegate tlDevice].deviceID, @"HWID",
														[NSNumber numberWithInt:2], @"OSType",
														projectName, @"AppGroup",
														[NSNumber numberWithLong:[appDelegate getPushNotificationsGroups]], @"Groups",
														nil];
	
	[TLTools sendJSONPostTo:requestUrl
							WithData:postData
		 completionHandler: ^(NSData *responseData, NSURLResponse *response, NSError *error) {
		
			 if (error != nil) {
				 NSLog(@"Push Notification Send Token Error: %@", error);
				 return;
			 }
			 if (responseData)
			 {
				 NSString* responseString = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
				 if ([responseString isEqualToString:@"OK"]) // Successfully registered the token with the server. Remove the pending status of the token:
					 [self setTokenSendPending:NO];
			 }

	}];
}


-(void) setTokenSendPending: (bool) pending
{
	NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
	[ud setBool:pending forKey:PREF_PUSH_TOKEN_PENDING];
}

-(bool) getTokenSendPending
{
	NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
	return [ud boolForKey:PREF_PUSH_TOKEN_PENDING];
}

@end

#endif
