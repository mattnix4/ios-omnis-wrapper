//
//  TLPushNotificationManager.h
//  TLDevice
//
//  Created by Jason Gissing on 11/01/2017.
//  Copyright © 2017 TigerLogic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TLPushNotificationsDelegate.h"

@interface TLPushNotificationManager : NSObject

@property (nonatomic, weak) id <TLPushNotificationsDelegate> delegate;

- (instancetype)init NS_UNAVAILABLE; // Use initWithDelegate to create an instance.
- (instancetype) initWithDelegate: (id<TLPushNotificationsDelegate>) delegate;

- (void) connectToFcm;
- (void) disconnectFromFcm;
- (void) enablePushNotifications: (BOOL) enable;
- (void) didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken;
- (void) application: (UIApplication*) application receivedLegacyNotificationData: (NSDictionary*) data fromLocalNotification: (BOOL) localNotification;
@end
