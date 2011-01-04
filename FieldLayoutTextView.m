#import "FieldLayoutTextView.h"


@implementation FieldLayoutTextView

#pragma mark Override Methods

- (NSRange)selectionRangeForProposedRange:(NSRange)proposedRange granularity:(NSSelectionGranularity)granularity
{
	NSAttributedString *theString;
	NSRange propFirstEffectiveRange, propLastEffectiveRange;
	int propFirst, propLast, newFirst, newLast;
	
	proposedRange = [super selectionRangeForProposedRange:proposedRange granularity:granularity];
	
	theString = [self textStorage];
		
	// If proposedRange is after last character
	if ( proposedRange.location == [theString length] )
		propFirst = proposedRange.location - 1;
	else
		propFirst = proposedRange.location;
	
	[theString attributesAtIndex:propFirst effectiveRange:&propFirstEffectiveRange];
	newFirst = propFirstEffectiveRange.location;
	
	if ( proposedRange.length == 0 )
	{
		return propFirstEffectiveRange;
	}
	else
	{
		propLast = propFirst + proposedRange.length - 1;
		[theString attributesAtIndex:propLast effectiveRange:&propLastEffectiveRange];
		newLast = propLastEffectiveRange.location + propLastEffectiveRange.length - 1;
		
		return NSMakeRange(newFirst, newLast - newFirst + 1);
	}
}

- (BOOL)shouldChangeTextInRange:(NSRange)affectedCharRange replacementString:(NSString *)replacementString
{
	//  Allow changes if attribute change only, disallow changing the actual string
	//  NB:  This needs modification, as it also allows removal of essential field attributes (eg, on some ruler changes)

	if ( ! replacementString )
	{
		return YES;
	}

	return NO;
}

@end
