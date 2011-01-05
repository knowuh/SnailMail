/*
 Copyright (c) 2011 Nik Sanz
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 */

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
