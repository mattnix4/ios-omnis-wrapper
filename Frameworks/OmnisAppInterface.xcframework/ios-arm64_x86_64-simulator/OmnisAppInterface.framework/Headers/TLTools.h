/* $Header: $ */

/************************ Changes
 Date       Edit        Fault       Description
 09-Jul-20		jmg1014	AF/WR/351		Barcode scanner did not open full-screen on iPads running iOS 13+.
 01-Jun-17	jmg0592									Added imageWithRoundedCorners: UsingImage: method.
 14-Feb-17	jmgPushNotifications			Support for Push Notifications.
 08-Jun-16	jmg0429			ST/WR/243		Removed dependency on SBJson.
 02-Mar-15  jmg0198     ST/WR/198   Changes to prevent caching of offline resources after an update.
 26-Feb-15  jmg0193     ST/WR/102   Support for wrapper handling of save/load pref client command.
 06-Feb-15  jmg0179                 Added ShowErrorMessage
 05-Feb-15  jmg0173     ST/JS/726   Created.
 
 **************************/

//
//  TLTools.h
//  TLDevice
//
//  Created by Jason Gissing on 05/02/2015.
//  Copyright (c) 2015 TigerLogic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface TLTools : NSObject

+ (void) ShowPDF:(NSURL*) pdfUrl WithView: (UIView *)view;
+ (void) ShowErrorMessage:(NSString*)errorMessage; // jmg0179
+ (void) presentModalViewController: (UIViewController *) controller FromRootController: (UIViewController *) root WithAnimation: (BOOL) animated; // jmg0180
+ (void) presentModalViewController: (UIViewController *) controller FromRootController: (UIViewController *) root WithAnimation: (BOOL) animated WithPresentationStyle: (UIModalPresentationStyle) presentationStyle; // jmg1014
+ (void) dismissModalViewController: (UIViewController *) controller WithAnimation: (BOOL) animated; // jmg0180
+ (void) savePrefWithKey:(NSString*) key WithValue:(NSString*) value; // jmg0193
+ (NSString*) loadPrefWithKey:(NSString*) key; // jmg0193
+ (NSString*) getDocumentsPath; // jmg0198

+ (void) sendJSONPostTo: (NSString*) urlString
							WithData: (NSDictionary*) postData
		 completionHandler: (void ( ^ )(NSData * data, NSURLResponse * response, NSError * error)) completionHandler; // jmgPushNotifications

+ (NSString*) jsonStringFromDictionary: (NSDictionary*) dictionary; // jmg0429
+ (NSDictionary*) dictionaryFromJsonString: (NSString*) jsonString; // jmg0429
+ (UIImage *)imageWithRoundedCorners:(float)cornerRadius usingImage:(UIImage *)original; // jmg0592
+ (NSMutableArray*) getDateFormatStrings;
+ (void) setError: (NSError * __autoreleasing *) outError WithText: (NSString*) errorText WithCode: (NSInteger) errorCode WithUnderlyingError: (NSError*) underlyingError;
@end
