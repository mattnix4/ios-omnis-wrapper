//
//  TLPushNotificationsDelegate.h
//  OmnisJSWrapperDev
//
//  Created by Jason Gissing on 26/01/2017.
//  Copyright © 2017 TigerLogic. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol TLPushNotificationsDelegate <NSObject>

@required

-(void) pushNotifications: (id) pushNotificationsHandler notificationClickedWithPayload: (NSDictionary*) dataPayload;

-(void) pushNotifications: (id) pushNotificationsHandler dataOnlyNotificationReceived: (NSDictionary*) dataPayload;

@end
