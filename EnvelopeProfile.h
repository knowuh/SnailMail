#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import "AddressManager.h"


@interface EnvelopeProfile : NSObject
{
    NSPrintInfo *printInfo;
    
    int marginFromLeft, marginFromRight, marginFromTop, marginFromBottom;
    int marginToLeft, marginToRight, marginToTop, marginToBottom;

	NSMutableDictionary *prefs;
}

- (id)init;
- (id)initWithPrintInfo:(NSPrintInfo *)info;
- (void)dealloc;
- (id)initWithCoder:(NSCoder *)coder;
- (void)encodeWithCoder:(NSCoder *)coder;
- (id)copyWithZone:(NSZone *)zone;

- (NSPrintInfo *)printInfo;
- (void)setPrintInfo:(NSPrintInfo *)info;
- (int)marginFromLeft;
- (void)setMarginFromLeft:(int)points;
- (int)marginFromRight;
- (void)setMarginFromRight:(int)points;
- (int)marginFromTop;
- (void)setMarginFromTop:(int)points;
- (int)marginFromBottom;
- (void)setMarginFromBottom:(int)points;
- (int)marginToLeft;
- (void)setMarginToLeft:(int)points;
- (int)marginToRight;
- (void)setMarginToRight:(int)points;
- (int)marginToTop;
- (void)setMarginToTop:(int)points;
- (int)marginToBottom;
- (void)setMarginToBottom:(int)points;
- (NSMutableDictionary *)prefs;
- (void)setPrefs:(NSMutableDictionary *)aDict;

@end
