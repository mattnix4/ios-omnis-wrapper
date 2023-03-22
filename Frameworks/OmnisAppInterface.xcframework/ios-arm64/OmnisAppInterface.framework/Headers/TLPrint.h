/* $Header: $ */

/******* Changes **********
 
 Date       Edit        Fault       Description
 04-Mar-16	jmg0393			ST/WR/238		Printing PDF didn't work from iPad running iOS 8.
 09-Dec-15	jmg0363			ST/JS/1261	Created. Implemented PDF printing. yes
 
************************/

//
//  TLPrint.h
//  TLDevice
//
//  Created by Jason Gissing on 08/12/15.
//  Copyright © 2015 TigerLogic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface TLPrint : NSObject

+ (TLPrint *) getInstance;

- (void) printPDFWithURL: (NSURL *)pdfUrl FromView: (UIView *)view WithFileName: (NSString *)fileName; // jmg0393

@end
