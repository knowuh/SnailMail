#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>


// These are the NSAttributedString equivalent of the NSText
// method, setString, and NSTextView method string.

@interface NSTextView (NixanzAdditions)

- (void)setAttributedString:(NSAttributedString *)string;
- (NSAttributedString *)attributedString;

@end
