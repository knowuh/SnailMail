#import "AddressManager.h"
#import "NSAttributedStringAdditions.h"


@implementation AddressManager

static AddressManager *sharedAddressManager = nil;

- (void)dealloc
{
    [sharedAddressManager release];
	
    [super dealloc];
}

+ (AddressManager *)sharedAddressManager
{
    if ( sharedAddressManager == nil )
    {
        sharedAddressManager = [[AddressManager alloc] init];
    }
	
    return sharedAddressManager;
}

+ (NSArray *)personSortDescriptors
{
	return [NSArray arrayWithObjects:
		[[[NSSortDescriptor alloc] initWithKey:kABLastNameProperty ascending:YES] autorelease],
		[[[NSSortDescriptor alloc] initWithKey:kABFirstNameProperty ascending:YES] autorelease],
		nil];
}

- (NSString *)alphaName:(NSDictionary *)addrDict
{
	NSString *theName = @"";
	
	if ( [addrDict objectForKey:kABLastNameProperty] != NULL )
		theName = [theName stringByAppendingString:[addrDict objectForKey:kABLastNameProperty]];
	
	if ( [addrDict objectForKey:kABFirstNameProperty] != NULL )
	{
		if ( [theName isEqualToString:@""] )
			theName = [addrDict objectForKey:kABFirstNameProperty];
		else
			theName = [theName stringByAppendingString:[NSString stringWithFormat:
				@", %@", [addrDict objectForKey:kABFirstNameProperty]
				]];
	}
	if ( [addrDict objectForKey:kABTitleProperty] != NULL )
	{
		if ( [theName isEqualToString:@""] )
			theName = [addrDict objectForKey:kABTitleProperty];
		else
			theName = [theName stringByAppendingString:[NSString stringWithFormat:
				@" (%@)", [addrDict objectForKey:kABTitleProperty]
				]];
	}
	
	if ( [addrDict objectForKey:kABOrganizationProperty] != NULL )
	{
		if ([theName isEqualToString:@""] )
			theName = [addrDict objectForKey:kABOrganizationProperty];
		else
			theName = [NSString stringWithFormat:@"%@, %@",
				theName,
				[addrDict objectForKey:kABOrganizationProperty]
				];
	}
	
	return theName;
}

- (NSString *)linearAddress:(NSDictionary *)addrDict;
{
	NSMutableString *addrString = [[@"" mutableCopy] autorelease];
	
	if ( [addrDict valueForKey:@"sequence"] && [addrDict valueForKey:@"label"] )
	{
		[addrString appendString:[NSString stringWithFormat:@"%@-%@: ", [addrDict valueForKey:@"sequence"], [addrDict valueForKey:@"label"]]];
	}
	else
	{
		if ( [addrDict valueForKey:@"sequence"] )
			[addrString appendString:[NSString stringWithFormat:@"%@: ", [addrDict valueForKey:@"sequence"]]];
		
		if ( [addrDict valueForKey:@"label"] )
			[addrString appendString:[NSString stringWithFormat:@"%@: ", [addrDict valueForKey:@"label"]]];
	}
	
	[addrString appendString:
		[[[ABAddressBook sharedAddressBook] formattedAddressFromDictionary:addrDict] string]
		];
	
	[addrString replaceOccurrencesOfString:@"\n" withString:@", " options:NSLiteralSearch range:NSMakeRange(0, [addrString length])];
		
	return [[addrString copy] autorelease];
}

- (NSAttributedString *)addressStringForAddressDict:(NSDictionary *)addrDict
{
	int i;
	NSMutableAttributedString *addrString = [[[NSMutableAttributedString alloc] initWithString:@""] autorelease];
	
	if ( [addrDict objectForKey:@"AddressPrefix"] )
	{			
		[addrString appendAttributedString:
			[[[NSAttributedString alloc] initWithString:[addrDict objectForKey:@"AddressPrefix"]
											 attributes:[NSDictionary dictionaryWithObject:@"AddressPrefix" forKey:@"AddressPrefix"]] autorelease]
			];
	}
	
	if ( [addrDict objectForKey:kABTitleProperty] )
	{
		[addrString appendString:@"\n"];
		[addrString appendAttributedString:
			[[[NSAttributedString alloc] initWithString:[addrDict objectForKey:kABTitleProperty]
											 attributes:[NSDictionary dictionaryWithObject:kABTitleProperty forKey:kABTitleProperty]] autorelease]
			];
	}
	
	if ( [[addrDict objectForKey:@"swapNames"] intValue] )
	{
		if ( [addrDict objectForKey:kABLastNameProperty] )
		{
			if ( [addrDict objectForKey:kABTitleProperty] )
			{
				[addrString appendString:@" "];
			}
			
			[addrString appendAttributedString:
				[[[NSAttributedString alloc] initWithString:[addrDict objectForKey:kABLastNameProperty]
												 attributes:[NSDictionary dictionaryWithObject:kABLastNameProperty forKey:kABLastNameProperty]] autorelease]
				];
		}
	}
	else
	{
		if ( [addrDict objectForKey:kABFirstNameProperty] )
		{
			if ( [addrDict objectForKey:kABTitleProperty] )
			{
				[addrString appendString:@" "];
			}
			
			[addrString appendAttributedString:
				[[[NSAttributedString alloc] initWithString:[addrDict objectForKey:kABFirstNameProperty]
												 attributes:[NSDictionary dictionaryWithObject:kABFirstNameProperty forKey:kABFirstNameProperty]] autorelease]
				];
		}
	}
	
	if ( [addrDict objectForKey:kABMiddleNameProperty] )
	{
		if ( [addrDict objectForKey:kABTitleProperty]
			 || [addrDict objectForKey:kABFirstNameProperty] )
		{
			[addrString appendString:@" "];
		}
		
		[addrString appendAttributedString:
			[[[NSAttributedString alloc] initWithString:[addrDict objectForKey:kABMiddleNameProperty]
											 attributes:[NSDictionary dictionaryWithObject:kABMiddleNameProperty forKey:kABMiddleNameProperty]] autorelease]
			];
	}
	
	if ( [[addrDict objectForKey:@"swapNames"] intValue] )
	{
		if ( [addrDict objectForKey:kABFirstNameProperty] )
		{
			if ( [addrDict objectForKey:kABTitleProperty]
				 || [addrDict objectForKey:kABLastNameProperty]
				 || [addrDict objectForKey:kABMiddleNameProperty] )
			{
				[addrString appendString:@" "];
			}
			
			[addrString appendAttributedString:
				[[[NSAttributedString alloc] initWithString:[addrDict objectForKey:kABFirstNameProperty]
												 attributes:[NSDictionary dictionaryWithObject:kABFirstNameProperty forKey:kABFirstNameProperty]] autorelease]
				];
		}
	}
	else
	{
		if ( [addrDict objectForKey:kABLastNameProperty] )
		{
			if ( [addrDict objectForKey:kABTitleProperty]
				 || [addrDict objectForKey:kABFirstNameProperty]
				 || [addrDict objectForKey:kABMiddleNameProperty] )
			{
				[addrString appendString:@" "];
			}
			
			[addrString appendAttributedString:
				[[[NSAttributedString alloc] initWithString:[addrDict objectForKey:kABLastNameProperty]
												 attributes:[NSDictionary dictionaryWithObject:kABLastNameProperty forKey:kABLastNameProperty]] autorelease]
				];
		}
	}
	if ( [addrDict objectForKey:kABSuffixProperty] )
	{
		if ( [addrDict objectForKey:kABTitleProperty]
			 || [addrDict objectForKey:kABFirstNameProperty]
			 || [addrDict objectForKey:kABMiddleNameProperty]
			|| [addrDict objectForKey:kABLastNameProperty] )
		{
			[addrString appendString:@" "];
		}
		
		[addrString appendAttributedString:
			[[[NSAttributedString alloc] initWithString:[addrDict objectForKey:kABSuffixProperty]
											 attributes:[NSDictionary dictionaryWithObject:kABSuffixProperty forKey:kABSuffixProperty]] autorelease]
			];
	}
	
	if ( [addrDict objectForKey:kABJobTitleProperty] )
	{
		[addrString appendString:@"\n"];
		[addrString appendAttributedString:
			[[[NSAttributedString alloc] initWithString:[addrDict objectForKey:kABJobTitleProperty]
											 attributes:[NSDictionary dictionaryWithObject:kABJobTitleProperty forKey:kABJobTitleProperty]] autorelease]
			];
	}
	
	if ( [addrDict objectForKey:kABOrganizationProperty] )
	{
		[addrString appendString:@"\n"];
		[addrString appendAttributedString:
			[[[NSAttributedString alloc] initWithString:[addrDict objectForKey:kABOrganizationProperty]
											 attributes:[NSDictionary dictionaryWithObject:kABOrganizationProperty forKey:kABOrganizationProperty]] autorelease]
			];
	}
	
	[addrString appendString:@"\n"];
	[addrString appendAttributedString:
		[[[ABAddressBook sharedAddressBook] formattedAddressFromDictionary:addrDict] reattributedWhitespaceString]
		];
	
	if ( [addrDict objectForKey:@"AddressSuffix"] )
	{
		[addrString appendString:@"\n"];
		[addrString appendAttributedString:
			[[[NSAttributedString alloc] initWithString:[addrDict objectForKey:@"AddressSuffix"]
											 attributes:[NSDictionary dictionaryWithObject:@"AddressSuffix" forKey:@"AddressSuffix"]] autorelease]
			];
	}
	
	//  Remove any blank lines
	
	//  Remove any leading "\n"s
	while ( [addrString length] > 0
		  && [[[addrString attributedSubstringFromRange:NSMakeRange(0, 1)] string] isEqualToString:@"\n"] )
	{
		[addrString deleteCharactersInRange:NSMakeRange(0, 1)];
	}

	//  Replace any multiples of "\n" by single "\n"
	for ( i = 0; i < [addrString length]; i++ )
	{
		if ( [[[addrString attributedSubstringFromRange:NSMakeRange(i, 1)] string] isEqualToString:@"\n"] )
		{
			while ( [addrString length] - 1 > i && [[[addrString attributedSubstringFromRange:NSMakeRange(i+1, 1)] string] isEqualToString:@"\n"] )
				[addrString deleteCharactersInRange:NSMakeRange(i+1, 1)];
		}
	}
	
	//  Remove any trailing "\n"s
	while ( [addrString length] > 0
			&& [[[addrString attributedSubstringFromRange:NSMakeRange([addrString length]-1, 1)] string] isEqualToString:@"\n"] )
	{
		[addrString deleteCharactersInRange:NSMakeRange([addrString length]-1, 1)];
	}
	
	return [[addrString copy] autorelease];
}

- (NSDictionary *)addressDictForPerson:(ABPerson *)pers sequence:(NSNumber *)sequence label:(NSString *)label address:(NSDictionary *)addr prefix:(NSString *)prefix suffix:(NSString *)suffix swapNames:(BOOL)swap
{
	int i;
	NSMutableDictionary *personAddress = [[addr mutableCopy] autorelease];
	NSArray *addrKeys = [personAddress allKeys];
	
	//  Remove any non-string objects from the dictionary (one user has been shown to get an NSNull object for an empty country???)
	for ( i = 0; i < [addrKeys count]; i++ )
	{
		if ( ! [[personAddress objectForKey:[addrKeys objectAtIndex:i]] isKindOfClass:[NSString class]] )
			[personAddress removeObjectForKey:[addrKeys objectAtIndex:i]];
	}

	//  Sequence (number to keep each address unique within person, eg, if two identical "other" addresses")
	[personAddress setValue:sequence forKey:@"sequence"];
	//  Label (eg, "Home", "Work")
	[personAddress setValue:[ABLocalizedPropertyOrLabel(label) capitalizedString] forKey:@"label"];
	
	if ( [pers valueForProperty:kABPersonFlags] && [[pers valueForProperty:kABPersonFlags] intValue] % 10 == 1 )
		[personAddress setObject:@"COMPANY" forKey:@"type"];
	else
		[personAddress setObject:@"PERSON" forKey:@"type"];
	
	if ( [prefix length] )
		[personAddress setValue:prefix forKey:@"AddressPrefix"];

	[personAddress setValue:[pers valueForKey:kABTitleProperty] forKey:kABTitleProperty];
	[personAddress setValue:[pers valueForKey:kABFirstNameProperty] forKey:kABFirstNameProperty];
	[personAddress setValue:[pers valueForKey:kABMiddleNameProperty] forKey:kABMiddleNameProperty];
	[personAddress setValue:[pers valueForKey:kABLastNameProperty] forKey:kABLastNameProperty];
	[personAddress setValue:[pers valueForKey:kABSuffixProperty] forKey:kABSuffixProperty];
	[personAddress setValue:[pers valueForKey:kABJobTitleProperty] forKey:kABJobTitleProperty];
	[personAddress setValue:[pers valueForKey:kABOrganizationProperty] forKey:kABOrganizationProperty];

	if ( [suffix length] )
		[personAddress setValue:suffix forKey:@"AddressSuffix"];
	
	[personAddress setValue:[NSNumber numberWithBool:swap] forKey:@"swapNames"];
	
	return [[personAddress copy] autorelease];
}

/*
- (NSAttributedString *)addressStringForPerson:(ABPerson *)pers address:(NSDictionary *)addr prefix:(NSString *)prefix suffix:(NSString *)suffix
{
	return [self addressStringForAddressDict:[self addressDictForPerson:pers
															   sequence:nil
																  label:nil
																address:addr
																 prefix:prefix
																 suffix:suffix
		]];
}
*/

- (NSAttributedString *)defaultAddressAttributesString
{
	NSMutableAttributedString *attrString = [[[NSMutableAttributedString alloc] initWithString:@""] autorelease];
	
	[attrString appendAttributedString:
		[[[NSAttributedString alloc] initWithString:[[NSBundle mainBundle] localizedStringForKey:@"AddressPrefix"
																						   value:@"Address Prefix"
																						   table:@"Localizable"]
										 attributes:[NSDictionary dictionaryWithObject:@"AddressPrefix" forKey:@"AddressPrefix"]] autorelease]
		];
	[attrString appendAttributedString:[[[NSAttributedString alloc] initWithString:@"\n"] autorelease]];
	
	[attrString appendAttributedString:
		[[[NSAttributedString alloc] initWithString:ABLocalizedPropertyOrLabel(kABTitleProperty)
										 attributes:[NSDictionary dictionaryWithObject:kABTitleProperty forKey:kABTitleProperty]] autorelease]
		];
	[attrString appendAttributedString:[[[NSAttributedString alloc] initWithString:@" "] autorelease]];
	[attrString appendAttributedString:
		[[[NSAttributedString alloc] initWithString:ABLocalizedPropertyOrLabel(kABFirstNameProperty)
										 attributes:[NSDictionary dictionaryWithObject:kABFirstNameProperty forKey:kABFirstNameProperty]] autorelease]
		];
	[attrString appendAttributedString:[[[NSAttributedString alloc] initWithString:@" "] autorelease]];
	[attrString appendAttributedString:
		[[[NSAttributedString alloc] initWithString:ABLocalizedPropertyOrLabel(kABMiddleNameProperty)
										 attributes:[NSDictionary dictionaryWithObject:kABMiddleNameProperty forKey:kABMiddleNameProperty]] autorelease]
		];
	[attrString appendAttributedString:[[[NSAttributedString alloc] initWithString:@" "] autorelease]];
	[attrString appendAttributedString:
		[[[NSAttributedString alloc] initWithString:ABLocalizedPropertyOrLabel(kABLastNameProperty)
										 attributes:[NSDictionary dictionaryWithObject:kABLastNameProperty forKey:kABLastNameProperty]] autorelease]
		];
	[attrString appendAttributedString:[[[NSAttributedString alloc] initWithString:@" "] autorelease]];
	[attrString appendAttributedString:
		[[[NSAttributedString alloc] initWithString:ABLocalizedPropertyOrLabel(kABSuffixProperty)
										 attributes:[NSDictionary dictionaryWithObject:kABSuffixProperty forKey:kABSuffixProperty]] autorelease]
		];
	[attrString appendAttributedString:[[[NSAttributedString alloc] initWithString:@"\n"] autorelease]];
	
	[attrString appendAttributedString:
		[[[NSAttributedString alloc] initWithString:ABLocalizedPropertyOrLabel(kABJobTitleProperty)
										 attributes:[NSDictionary dictionaryWithObject:kABJobTitleProperty forKey:kABJobTitleProperty]] autorelease]
		];
	[attrString appendAttributedString:[[[NSAttributedString alloc] initWithString:@"\n"] autorelease]];
	
	[attrString appendAttributedString:
		[[[NSAttributedString alloc] initWithString:ABLocalizedPropertyOrLabel(kABOrganizationProperty)
										 attributes:[NSDictionary dictionaryWithObject:kABOrganizationProperty forKey:kABOrganizationProperty]] autorelease]
		];
	[attrString appendAttributedString:[[[NSAttributedString alloc] initWithString:@"\n"] autorelease]];
	
	[attrString appendAttributedString:[[ABAddressBook sharedAddressBook] formattedAddressFromDictionary:
		[NSDictionary dictionaryWithObjectsAndKeys:
			ABLocalizedPropertyOrLabel(kABAddressStreetKey), kABAddressStreetKey,
			ABLocalizedPropertyOrLabel(kABAddressCityKey), kABAddressCityKey,
			ABLocalizedPropertyOrLabel(kABAddressStateKey), kABAddressStateKey,
			ABLocalizedPropertyOrLabel(kABAddressZIPKey), kABAddressZIPKey,
			ABLocalizedPropertyOrLabel(kABAddressCountryKey), kABAddressCountryKey,
			[[ABAddressBook sharedAddressBook] defaultCountryCode], kABAddressCountryCodeKey,
			nil
			]
		]];
	[attrString appendAttributedString:[[[NSAttributedString alloc] initWithString:@"\n"] autorelease]];
	
	[attrString appendAttributedString:
		[[[NSAttributedString alloc] initWithString:[[NSBundle mainBundle] localizedStringForKey:@"AddressSuffix"
																						   value:@"Address Suffix"
																						   table:@"Localizable"]
										 attributes:[NSDictionary dictionaryWithObject:@"AddressSuffix" forKey:@"AddressSuffix"]] autorelease]
		];
	
	return [[attrString copy] autorelease];
}

@end
