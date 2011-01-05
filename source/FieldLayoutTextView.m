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
