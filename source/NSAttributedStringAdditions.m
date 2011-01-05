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

#import "NSAttributedStringAdditions.h"


@implementation NSAttributedString (NixanzAdditions)

- (NSAttributedString *)addMatchingAttributesFromString:(NSAttributedString *)attributesString
{
	int i, j;
	NSArray *attributeKeys;
	NSString *attributeKey;
	NSRange attrRange;
	NSDictionary *attributes;
	NSMutableAttributedString *theString;
	
	if ( ! attributesString )
		return self;
	
	theString = [[self mutableCopy] autorelease];
	
	for ( i = 0; i < [self length]; i += attrRange.length )
	{
		attributeKeys = [[self attributesAtIndex:i effectiveRange:&attrRange] allKeys];
		if ( [attributeKeys count] == 1 )
		{
			attributeKey = [attributeKeys objectAtIndex:0];
			
			for ( j = 0; j < [attributesString length]; j++ )
			{
				attributes = [attributesString attributesAtIndex:j effectiveRange:NULL];
				
				if ( [attributes objectForKey:attributeKey] )
					[theString addAttributes:attributes range:attrRange];
			}
		}
	}
	
	return [[theString copy] autorelease];
}

- (NSAttributedString *)reattributedWhitespaceString
{
	int i;
	NSAttributedString *attrChar;
	int length = [self length];
	NSMutableAttributedString *newString = [[self mutableCopy] autorelease];
	
	if ( length < 2 )
		return newString;
	
	for ( i = 0; i < length; i++ )
	{
		attrChar = [newString attributedSubstringFromRange:NSMakeRange(i, 1)];
		if ( [[[attrChar attributesAtIndex:0 effectiveRange:NULL] allKeys] count] == 0 )
		{
			if ( i == 0 )
				[newString setAttributes:[newString attributesAtIndex:i+1 effectiveRange:NULL]
								   range:NSMakeRange(i, 1)];
			else
				[newString setAttributes:[newString attributesAtIndex:i-1 effectiveRange:NULL]
								   range:NSMakeRange(i, 1)];
		}
	}

	return [[newString copy] autorelease];
}

@end


@implementation NSMutableAttributedString (NixanzAdditions)

- (void)appendString:(NSString *)aString
{
	NSDictionary *attr;
	
	if ( [self length] == 0 )
		attr = nil;
	else
		attr = [self attributesAtIndex:([self length] - 1) effectiveRange:NULL];

	[self appendAttributedString:
		[[[NSAttributedString alloc] initWithString:aString attributes:attr] autorelease]
		];
}

@end

