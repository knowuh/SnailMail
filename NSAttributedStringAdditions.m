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

