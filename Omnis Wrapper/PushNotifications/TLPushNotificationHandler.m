/****** Changes ********
 Date       Edit        Fault       Description
 01-Jun-17	jmg0592									Show custom Toast when running in foreground on iOS < 10 when a push notification is received.
 
************************/

//
//  TLPushNotifications.m
//  OmnisJSWrapperDev
//
//  Created by Jason Gissing on 26/01/2017.
//  Copyright © 2017 TigerLogic. All rights reserved.
//

#import "TLPushNotificationHandler.h"
#import "AppDelegate.h"

@implementation TLPushNotificationHandler


/**
 We receive more than just the Firebase 'data' payload.
 This method strips out specific named Firebase keys, and any starting with 'google.' or 'gcm.',
 so that the Omnis developer is not swamped with unnecessary data.

 @param data The data payload of the notification.
 @return A new NSDictionary with unnecessary values stripped out.
 */
- (NSMutableDictionary*) removeExtraDataFromMessageData: (NSDictionary*) data
{
	NSMutableDictionary* newData = [NSMutableDictionary dictionaryWithDictionary:data];
	
	[newData removeObjectForKey:@"aps"]; // jmg0592: The Apple Push Service object, conataining notification data
	[newData removeObjectForKey:@"from"];
	[newData removeObjectForKey:@"notification"];
	[newData removeObjectForKey:@"collapse_key"];
	[newData removeObjectForKey:@"_OMNIS_NOTIFICATION_"]; // jmg0592: Identifier indicating that the notification was sent from Omnis.
	
	// jmg0592: Remove keys beginning 'google.' and 'gcm.'
	for (NSString* key in [newData allKeys]) {
		if ([key hasPrefix:@"google."] || [key hasPrefix:@"gcm."])
			[newData removeObjectForKey:key];
	}
	
	return newData;
}


-(void)pushNotifications:(id)pushNotificationsHandler notificationClickedWithPayload:(NSDictionary *)dataPayload
{
	// Remove unnecessary values from the dictionary, then re-load the main form, with the dictionary values set as URLParams:
	[(AppDelegate *) [[UIApplication sharedApplication] delegate] loadURL:0
																														 WithParams:[self removeExtraDataFromMessageData:dataPayload]];
}


-(void)pushNotifications:(id)pushNotificationsHandler dataOnlyNotificationReceived:(NSDictionary *)dataPayload
{
	/* Do nothing for now in this situation. (Data-only, or 'silent' notifications are not supported by default)
	
	 As an Omnis developer, you could implement this method, e.g. to call a particular method in your form, if you know it is going to exist.
	 */
	NSLog(@"Data-only notification received, but not handled:");
	NSLog(@"%@", dataPayload);
}



@end
