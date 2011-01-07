#import <Cocoa/Cocoa.h>
#import <AddressBook/ABPeoplePickerView.h>
#import "AddressManager.h"
#import "EnvelopeProfile.h"
#import "NSTextAdditions.h"
#import "NSAttributedStringAdditions.h"
#import "PostalBarcodeGenerator.h"
#import "FieldLayoutTextView.h"


@interface SnailMailController : NSObject <NSToolbarDelegate>
{
	IBOutlet NSMenuItem *addressBookPluginMenuItem;
    IBOutlet NSView *printableView;
    IBOutlet NSTextView *fromView;
    IBOutlet NSTextView *toView;
	IBOutlet NSTextView *backgroundView;
    IBOutlet NSPopUpButton *fromTypePopup;
    IBOutlet NSPopUpButton *fromPopup;
    IBOutlet NSPopUpButton *envelopeProfilePopup;
    IBOutlet ABPeoplePickerView *peoplePicker;
    IBOutlet NSWindow *controlWindow;
    IBOutlet NSWindow *envelopeWindow;
    IBOutlet NSWindow *textAttributesWindow;
    IBOutlet NSWindow *marginsWindow;
    IBOutlet NSWindow *prefsWindow;
    IBOutlet NSWindow *envelopeProfilesWindow;
    IBOutlet NSTableView *envelopeProfilesTable;
    IBOutlet NSButton *envelopeProfilesNewButton;
    IBOutlet NSButton *envelopeProfilesDeleteButton;
    IBOutlet NSButton *envelopeProfilesCancelButton;
    IBOutlet NSButton *envelopeProfilesOKButton;
    IBOutlet NSMenuItem *marginGuidelinesMenuItem;
    IBOutlet NSTextField *marginFromLeftField;
    IBOutlet NSTextField *marginFromRightField;
    IBOutlet NSTextField *marginFromTopField;
    IBOutlet NSTextField *marginFromBottomField;
    IBOutlet NSTextField *marginToLeftField;
    IBOutlet NSTextField *marginToRightField;
    IBOutlet NSTextField *marginToTopField;
    IBOutlet NSTextField *marginToBottomField;
    IBOutlet NSButton *marginCancelButton;
    IBOutlet NSButton *marginDefaultButton;
    IBOutlet NSButton *marginApplyButton;
    IBOutlet NSButton *hideFromPrefixSwitch;
    IBOutlet NSButton *hideFromSuffixSwitch;
    IBOutlet NSButton *hideFromCountrySwitch;
    IBOutlet NSButton *hideFromSameCountrySwitch;
    IBOutlet NSButton *hideFromTitleSwitch;
    IBOutlet NSButton *hideFromNameSwitch;
    IBOutlet NSButton *hideFromJobSwitch;
    IBOutlet NSButton *hideFromCompanySwitch;
    IBOutlet NSButton *hideToPrefixSwitch;
    IBOutlet NSButton *hideToSuffixSwitch;
    IBOutlet NSButton *hideToCountrySwitch;
    IBOutlet NSButton *hideToTitleSwitch;
    IBOutlet NSButton *hideToNameSwitch;
    IBOutlet NSButton *hideToJobSwitch;
    IBOutlet NSButton *hideToCompanySwitch;
    IBOutlet NSButton *hideToSameCountrySwitch;
    IBOutlet NSButton *fromSwapNamesSwitch;
    IBOutlet NSButton *toSwapNamesSwitch;
	IBOutlet NSTextView *toAttributesView;
	IBOutlet NSTextView *fromAttributesView;
    IBOutlet NSTextField *toPrefixField;
    IBOutlet NSTextField *toSuffixField;
    IBOutlet NSTextField *fromPrefixField;
    IBOutlet NSTextField *fromSuffixField;
    IBOutlet NSPopUpButton *fromGroupPopup;
    IBOutlet NSPopUpButton *barcodePopup;
	IBOutlet NSButton *barcodePositionSwitch;
	IBOutlet NSTextView *localCountryNamesView;
	IBOutlet NSTextField *restrictLabelField;
	IBOutlet NSButton *overrideRestrictForNoMatchSwitch;

    NKDBarcodeOffscreenView *barcodeView;
    // Barcode must be maintained as barcodeView does not retain it's barcode!!!
    NKDBarcode *barcode;

    ABAddressBook *addressDB;

    NSMutableDictionary *envelopeProfiles;
    EnvelopeProfile *currentEnvelopeProfile;
    NSMutableArray *profileNames;
    NSMutableDictionary *newProfiles;
    NSMutableDictionary *cePrefs;
    
    NSMutableArray *fromAddresses;
    NSDictionary *fromAddress;
    NSDictionary *toAddress;
}

#pragma mark Initialisation and Deallocation

- (id)init;
- (void)dealloc;
- (void)awakeFromNib;

#pragma mark Accessor Methods

- (NSMutableDictionary *)cePrefs;
- (void)setCePrefs:(NSDictionary *)aDict;
- (NSAttributedString *)fromAttributes;
- (void)setFromAttributes:(NSAttributedString *)attString;
- (NSAttributedString *)toAttributes;
- (void)setToAttributes:(NSAttributedString *)attString;
- (NSDictionary *)fromAddress;
- (void)setFromAddress:(NSDictionary *)addr;
- (NSDictionary *)toAddress;
- (void)setToAddress:(NSDictionary *)addr forPerson:(ABPerson *)pers;
- (NKDBarcodeOffscreenView *)barcodeView;
- (void)setBarcodeView:(NKDBarcodeOffscreenView *)view;
- (NKDBarcode *)barcode;
- (void)setBarcode:(NKDBarcode *)aBarcode;
- (NSArray *)fromAddresses;
- (void)setFromAddresses:(NSArray *)addressList;
- (void)setEnvelopeProfiles:(NSMutableDictionary *)profileList;
- (NSMutableDictionary *)envelopeProfiles;
- (void)setCurrentEnvelopeProfile:(EnvelopeProfile *)aProfile;
- (EnvelopeProfile *)currentEnvelopeProfile;
- (void)setProfileNames:(NSMutableArray *)names;
- (NSMutableArray *)profileNames;
- (void)setNewProfiles:(NSMutableDictionary *)profileList;
- (NSMutableDictionary *)newProfiles;

#pragma mark Other Methods

- (void)populateEnvelopeProfilePopup;
- (NSDictionary *)addressDictForPerson:(ABPerson *)pers address:(NSDictionary *)addr afterToFromPrefs:(NSString *)toFrom;
- (NSDictionary *)addressDict:(NSDictionary *)addr afterToFromPrefs:(NSString *)toFrom;
- (BOOL)sameToFromCountries;
- (void)selectFromType;
- (void)selectFromAddress;
- (void)selectToAddressUpdatingFromAddress;
- (void)addressEnvelope;
- (void)positionBarcodeViewForType:(int)type;
- (void)printEnvelopesToPersonalisedAddresses:(NSArray *)personalisedAddressList;

- (void)refreshFromAddresses;
- (NSArray *)personalisedFromAddresses;

- (void)changeNewProfilesItem:(int)index toName:(NSString *)name;
- (BOOL)profileNameExists:(NSString *)str;

- (void)alignViewsToMargins;
- (void)setEnvelopeWindowFrame;
- (void)selectEnvelopeProfile;
- (void)invokeEnvelopeProfilesWindow;
- (oneway void)pluginPrintEnvelopeForPerson:pers address:addr;

- (BOOL)applyMarginsChange;
- (void)showMargins;
- (void)hideMargins;

- (NSString *)toPrefix;
- (NSString *)toSuffix;
- (NSString *)fromPrefix;
- (NSString *)fromSuffix;

#pragma mark IBActions

- (IBAction)installAddressBookPlugin:(id)sender;
- (IBAction)removeAddressBookPlugin:(id)sender;

- (IBAction)invokeTextAttributesWindow:(id)sender;
- (IBAction)textAttributesOkay:(id)sender;
- (IBAction)textAttributesCancel:(id)sender;

- (IBAction)invokeMarginsWindow:(id)sender;
- (IBAction)marginsOkay:(id)sender;
- (IBAction)marginsApply:(id)sender;
- (IBAction)marginsCancel:(id)sender;
- (IBAction)marginsDefault:(id)sender;

- (IBAction)envelopeProfilesOkay:(id)sender;
- (IBAction)envelopeProfilesCancel:(id)sender;
- (IBAction)envelopeProfilesNew:(id)sender;
- (IBAction)envelopeProfilesDelete:(id)sender;

- (IBAction)invokePrefsWindow:(id)sender;
- (IBAction)prefsOkay:(id)sender;
- (IBAction)prefsCancel:(id)sender;
- (IBAction)hideToCountryClicked:(id)sender;
- (IBAction)hideFromCountryClicked:(id)sender;

- (IBAction)toggleMarginGuidelines:(id)sender;
- (IBAction)invokeAddressBook:(id)sender;
- (IBAction)runPageLayout:(id)sender;

- (IBAction)printEnvelope:(id)sender;
- (IBAction)printImmediately:(id)sender;
- (IBAction)printSelected:(id)sender;

#pragma mark Services and Copy/Paste

- (void)printWithText:(NSPasteboard *)pboard userData:(NSString *)userData error:(NSString **)error;
- (void)textFromEnvelope:(NSPasteboard *)pboard userData:(NSString *)userData error:(NSString **)error;
- (void)textToEnvelope:(NSPasteboard *)pboard userData:(NSString *)userData error:(NSString **)error;

// Copy & Paste equivalents for non-system-services-compliant contexts
- (void)copyFromAddressee:(id)sender;
- (void)pasteToAddressee:(id)sender;

#pragma mark Toolbar

- (void)toolbarWillAddItem:(NSNotification *)notification;
- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag;
- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar;
- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar;

#pragma mark Delegations and Notifications

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification;
- (void)applicationWillBecomeActive:(NSNotification *)aNotification;
- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender;

@end
