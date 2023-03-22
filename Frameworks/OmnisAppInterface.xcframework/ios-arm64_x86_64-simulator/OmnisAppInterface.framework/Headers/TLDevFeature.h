/************* Changes
 Date       Edit        Fault       Description
 04-Mar-15  jmg unmarked            Removed unfinished Reachability code.
 09-Feb-15  jmg0180                 Created.
 ***********/

//
//  TLDevFeature.h
//  TLDevice
//
//  This is the super class for device feature classes.
//
//  Created by Jason Gissing on 08/02/2015.
//  Copyright (c) 2015 TigerLogic. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef enum {
    HWDeviceVibrate,
    HWDeviceTakePhoto,
    HWDeviceGetImage,
    HWDeviceBeep,
    HWDeviceGetLocation,
    HWDeviceMakeCall,
    HWDeviceSendSms,
    HWDeviceSendEmail,
    HWDeviceGetContacts,
    HWDeviceGetBarcode,
    HWDeviceGetUniqueID, // jmg0087
    HWDeviceShowDialog // jmg0158
} HWDeviceFunction;

static NSString *HWResultFailure = @"FAIL"; // jmg0180


/**
 * TLDevFeatureDelegate is the delegate interface used by all device feature classes. They will call back into this delegate with their results.
 */
@protocol TLDevFeatureDelegate <NSObject>

@required
- (void) TLDevResultReturned:(NSObject *)result ForFunction:(HWDeviceFunction)function WithCallback:(NSString *)callback;

@end



@interface TLDevFeature : NSObject

@property (nonatomic, assign) id  delegate;


/**
 * Initialise an instance of the class, setting its callback string.
 */
-(id) initWithCallback:(NSString *) callback;

/**
 *  Return the result of the device function to the delegate.
 */
-(void) sendDelegateResult:(NSObject *)result ForDeviceFunction:(HWDeviceFunction)function;

@end
