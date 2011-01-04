#import "NSTextAdditions.h"


@implementation NSTextView (NixanzAdditions)

- (void)setAttributedString:(NSAttributedString *)string
{
	[[self textStorage] setAttributedString:[[string copy] autorelease]];
}

- (NSAttributedString *)attributedString
{
    return [[[[self textStorage] attributedSubstringFromRange:NSMakeRange(0, [[self textStorage] length])] copy] autorelease];
}

@end
