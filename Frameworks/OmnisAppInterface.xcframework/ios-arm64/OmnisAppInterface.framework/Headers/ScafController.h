
/*************  Changes:
 Date       Edit        Fault       Description
05-Sep-19	jmg0929			AM/WR/334		Added support for pre- and post-10.1 offline form templates.
 02-Mar-15  jmg0198     ST/WR/198   Changes to prevent caching of offline resources after an update.
 17-Feb-15  jmg0189     ST/WR/074   Support for custom $fieldstyles in offline mode.
 
**************/

//
//  ScarController.h
//  OmnisJSWrapper
//
//  Created by Paul Davis on 4/09/12.
//  Copyright TigerLogic 2012. All rights reserved.
//


#import <UIKit/UIKit.h>

typedef enum {
    AHDR_LIB = 0,
    AHDR_STYLES,
    AHDR_VERSION,
    AHDR_ICONSMODDATE,
    AHDR_ICONSETNAME,
    AHDR_STRINGTABLE,
    AHDR_SCREENSIZES,
    AHDR_BINARY
} APPHEADERFIELDS;

typedef enum {
    OHDR_VERSION = 0,
} OMNISHEADERFIELDS;

typedef enum {
    FILE_PATH = 0,
    FILE_BINARY,
    FILE_MODDATE,
} SCAFJSFILESFIELDS;

typedef enum {
    FORM_LIB = 0,
    FORM_NAME,
    FORM_JSON,
    FORM_SCRIPTS,
    FORM_MODDATE,
} SCAFJSFORMSFIELDS;

typedef enum {
    SCAFTYPEAPP = 0,
    SCAFTYPEOMNIS,
} SCAFDBASETYPE;

typedef enum
{
	CHECK_LOCAL_HTML,
	CHECK_AND_CREATE_SCAF,
	EXTRACT_SCAF,
	READ_SCAF
} ScafControllerAction;

@protocol ScafControllerDelegate <NSObject>
-(void) scafControllerErrorForAction:(ScafControllerAction) action withErrorText:(NSString*) errorText;
-(void) scafControllerUpdateComplete:(BOOL) didUpdate withErrors:(NSMutableArray *) errors;
-(void) offlineModeConfigured:(NSString*) htmlPath;
@optional
-(NSString*) getOfflineTemplateName; // jmg0929
@end

@protocol ScafControllerDelegate;

@interface ScafController : NSObject {
    
    NSString *indexName;

    NSString *scafDatabaseName[2]; 
    NSString *scafDatabasePath[2]; 
    NSString *scafDatabaseFile[2]; 

    NSString *mFormName;
    NSString *mLibName;
    NSString *mOmnisWebUrl;
    NSString *mOmnisServer;
    NSString *mOmnisPlugin;
    NSInteger mCurrentScafSync;
    NSString *mScafConnectStrings[ 2 ];
    
    NSMutableData *receivedData;
    NSMutableArray *mScafUpdateErrors;

    bool    mForceScafUpdate;

    NSString *mDocumentsPath;

}

@property(nonatomic,retain) NSMutableData *receivedData;
@property(nonatomic, weak) id delegate;


-(void) initialiseScafControllerWithForm:(NSString*)formName
                             WithAppScaf:(NSString*)appScafName
                             ForceUpdate:(bool)forceUpdate
                         WithOmnisServer:(NSString*)omnisServer
                         WithOmnisPlugin:(NSString*)omnisPlugin
                         WithOmnisWebUrl:(NSString*)omnisWebUrl // jmg0197 // jmg0198
														 InSubfolder:(NSString*)subfolder; // jmg0717

-(BOOL) checkForLocalMainHtml;
-(void) checkForLocalScafDatabases;
-(NSString*) getFormJsonFromScaf:(NSString*)formName;
-(NSString*) getStringTableFromScaf;
-(NSString*)getStyleDataFromScaf; // jmg0189
-(void) checkStyles;
-(NSString*) getDbasePathAndName;
-(void) checkForScafSync:(bool)checkConfig;
-(bool) evaluateScafIntegrity;
-(void) setExpectLocalSCAFs:(BOOL) expected;
-(NSString *) getHtmlDirectory;

+(BOOL) deleteOfflineFilesAtSubfolder: (NSString*) subfolder; // jmg0717
+(BOOL) moveOfflineFilesFromSubfolder: (NSString*) fromFolder ToSubfolder: (NSString*) toFolder Error: (NSError * __autoreleasing *) outError; // jmg0717

@end
