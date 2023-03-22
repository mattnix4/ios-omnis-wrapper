/* $Header: svn://svn.omnis.net/trunk/Studio/JSCLIENT/wrappers/iOS/iOSlibs/TLDevice/TLDevice/TLDevice.h 11407 2015-03-04 17:31:33Z jgissing $ */

/* Changes
 Date       Edit        Fault       Description
 01-Mar-18	jmg0706			WR/WR/304		Failed to load subform in offline mode if an instance variable was also changed to a value containing a apostrophe, quote, or backslash.
 04-Mar-15  jmg unmarked            Removed unfinished Reachability code.
 10-Feb-15  jmg0183                 Modularisation & simplification of device functionality (Contacts) 
 10-Feb-15  jmg0181                 Modularisation & simplification of device functionality (location)
 09-Feb-15  jmg0180                 Modularisation & simplification of device functionality (barcode & images)
 06-Feb-15  jmg0174                 Fixed data type ambiguity when calling device functionality from JS.
 22-Jan-15  jmg0158     ST/WR/104   Implemented native handling of dialogs.
 12-Jan-15  jmg0143     ST/WR/023   Fixed issues when changing orientation with barcode scanner open.
 07-Jul-14	rmm8397									Send email wrapper action did not work.
 10-Jun-14  jmg0116                 Added functionality to send Hardware ID to sync server 

 */

//
//  TLDevice.h
//  TLDevice
//
//  Created by Paul Davis on 06/11/2012.
//  Copyright (c) 2012 TigerLogic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import <MessageUI/MessageUI.h>	// rmm8397
#import "TLDevFeature.h" // jmg0180

@protocol TLDeviceDelegate <NSObject> // jmg0180

@required
- (void) TLDeviceResultReturned:(NSObject *)result ForFunction:(HWDeviceFunction)function WithCallback:(NSString *)callback;

@end


@interface TLDevice : UIViewController<MFMailComposeViewControllerDelegate, MFMessageComposeViewControllerDelegate, TLDevFeatureDelegate> { // rmm8397 // jmg0180
	
    SEL         mCallback;
    SEL         mCallbackProgress;
    UIActivityIndicatorView   *indicator;
    bool        hasNetworkActivity;

    bool        mHostConnection;
    bool        mWnternetConnection;
    bool        mWifiConnection;
}

@property (nonatomic, assign) id  delegate; // jmg0180
@property (readonly) NSString *deviceID; //jmg0116

-(id) initWithDeviceID:(NSString*) deviceID;
-(bool) initializeWithCallbackSelector:(SEL)sel WithCallbackProgressSelector:(SEL)progSel WithViewController: (UIViewController*) viewController; // jmg0143 // jmgFramework2
-(void)sendRequestForFunction:(HWDeviceFunction)func WithData:(NSDictionary*)data WithCallbackFunc:(NSString*)callbackFunc; // jmg0174 / jmg0180

+ (NSString*) escapeJSONString: (NSString*) jsonString; // jmg0706

@end
