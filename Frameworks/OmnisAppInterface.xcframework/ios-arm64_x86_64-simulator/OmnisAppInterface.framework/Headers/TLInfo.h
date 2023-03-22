/******* Changes **********
 
 Date       Edit        Fault       Description
 22-Nov-17  jmg0656     WR/HE/1562	Initial support for iPhone X.
 04-Mar-16	jmg0393			ST/WR/238		Created as hlper class for pulling device information out.
 
 ************************/

//
//  TLInfo.h
//  TLDevice
//
//  Created by Jason Gissing on 04/03/16.
//  Copyright © 2016 TigerLogic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface TLInfo : NSObject

typedef NS_ENUM(NSInteger, TLDeviceType) { // jmg0332
	TLDeviceTypeUnknown,
	TLDeviceTypeiPhone4,
	TlDeviceTypeiPhone5,
	TLDeviceTypeiPhone6,
	TLDeviceTypeiPhone6Plus,
    TLDeviceTypeiPhoneX // jmg0656
};

+(BOOL) isDeviceRetina;
+(float) getDeviceScale;
+(BOOL) isDeviceiPhone;
+(BOOL) isDeviceiPhone4;
+(BOOL) isDeviceiPhone5;
+(BOOL) isDeviceiPhone6;
+(BOOL) isDeviceiPhone6Plus;
+(BOOL) isDeviceiPhoneX; // jmg0656

@end
