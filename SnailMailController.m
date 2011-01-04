#import "SnailMailController.h"

#define SOURCE_PLUGIN   ([[NSBundle mainBundle] pathForResource:@"SnailMailPlugin" ofType:@"bundle"])
#define GLOBAL_PLUGIN  (@"/Library/Address Book Plug-Ins/SnailMailPlugin.bundle")
#define USER_PLUGIN  (@"~/Library/Address Book Plug-Ins/SnailMailPlugin.bundle")


@implementation SnailMailController

#pragma mark Initialisation and Deallocation

- (id)init
{
	[super init];
	
	addressDB = [ABAddressBook sharedAddressBook];
	
	//  Establish self as a connection server for the AB SnailMailPlugin to communicate with
	[[NSConnection defaultConnection] setRootObject:self];
	if ( ! [[NSConnection defaultConnection] registerName:@"com_nixanz_snailmail"] )
	{
		NSLog(@"Failed to register connection name for plugin communication");
	}
	
	//  Set envelope profiles list and current profile
	
	if ( [[NSUserDefaults standardUserDefaults] objectForKey:@"envelope_profiles"] == NULL )
    {
		[self setEnvelopeProfiles:[[NSMutableDictionary alloc] init]];
    }
    else
    {
		[self setEnvelopeProfiles:[NSUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] objectForKey:@"envelope_profiles"]]];
    }
	
    if ( [[NSUserDefaults standardUserDefaults] objectForKey:@"current_envelope_profile_name"] == NULL
		 ||
		 [[envelopeProfiles allKeys] count] == 0
		 )
    {
		[self setCurrentEnvelopeProfile:[[EnvelopeProfile alloc] init]];
		
        [[currentEnvelopeProfile printInfo] setPaperSize:NSMakeSize(684.0,297.0)];
		[[currentEnvelopeProfile printInfo] setVerticallyCentered:NO];
		[[currentEnvelopeProfile printInfo] setHorizontallyCentered:NO];
		[envelopeProfiles setObject:currentEnvelopeProfile forKey:
			[[NSBundle mainBundle] localizedStringForKey:@"Default" value:@"Default" table:@"Localizable"]
			];
    }
    else
    {
		[self setCurrentEnvelopeProfile:[envelopeProfiles objectForKey:[[NSUserDefaults standardUserDefaults] objectForKey:@"current_envelope_profile_name"]]];
    }
	
    [self setProfileNames:[[[envelopeProfiles allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)] mutableCopy]];
	
	fromAddresses = [[NSMutableArray alloc] init];
    [self setFromAddress:nil];
    [self setBarcode:nil];
    [self setBarcodeView:nil];

    return self;
}

- (void)dealloc
{
	[fromAddresses release];
    [toAddress release];
    [fromAddress release];
	
    [super dealloc];
}

- (void)awakeFromNib
{
    int i;
    NSToolbar *toolbar;
	
    toolbar = [[NSToolbar alloc] initWithIdentifier:@"mainToolbar"];
    [toolbar setDelegate:self];
	[toolbar setAllowsUserCustomization:YES];
	[toolbar setAutosavesConfiguration:YES];
    [controlWindow setToolbar:[toolbar autorelease]];
	
	//  Configure AB Plug-In menu item according to whether plug-in is installed or not
	if ( [[NSFileManager defaultManager] fileExistsAtPath:USER_PLUGIN]
		 || [[NSFileManager defaultManager] fileExistsAtPath:GLOBAL_PLUGIN]
		 )
	{
		[addressBookPluginMenuItem setTitle:
			[[NSBundle mainBundle] localizedStringForKey:@"RemovePlugin"
												   value:@"Remove Address Book Plug-In"
												   table:@"Localizable"
				]];
		[addressBookPluginMenuItem setAction:@selector(removeAddressBookPlugin:)];
		
		//  FOR NEXT UPDATE OF PLUG-IN
		//  INSERT CODE HERE TO
		//  check plug-in version and re-install/update it if necessary
	}
		
	//  These properties cannot be added in IB, and without them search will not work for person names where the record is for a company
	[peoplePicker addProperty:kABFirstNameProperty];
	[peoplePicker addProperty:kABLastNameProperty];
	
	//  Configure the People Picker actions and notifications
	[peoplePicker setTarget:peoplePicker];
    [peoplePicker setNameDoubleAction:@selector(editInAddressBook:)];
	[peoplePicker setAllowsGroupSelection:YES];
	
    [[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(selectToAddressUpdatingFromAddress)
												 name:ABPeoplePickerNameSelectionDidChangeNotification
											   object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(selectToAddressUpdatingFromAddress)
												 name:ABPeoplePickerValueSelectionDidChangeNotification
											   object:nil];
	
	//  Place the backgroundView in the background (doesn't seem to work from IB)
	
	[[backgroundView enclosingScrollView] retain];
	[[backgroundView enclosingScrollView] removeFromSuperview];
	[printableView addSubview:[backgroundView enclosingScrollView] positioned:NSWindowBelow relativeTo:toView];
	[[backgroundView enclosingScrollView] release];
	
	//  Make the addressViews' backgrounds invisible so backgroundView is visible through them
	//  and backgrounView invisible so it doesn't hide other views when edited
	
	[fromView setDrawsBackground:NO];
	[[fromView enclosingScrollView] setDrawsBackground:NO];
	[toView setDrawsBackground:NO];
	[[toView enclosingScrollView] setDrawsBackground:NO];
	[backgroundView setDrawsBackground:NO];
	[[backgroundView enclosingScrollView] setDrawsBackground:NO];
	
	// NB:  Top left point specified in prefs because auto saving window
    // doesn't work correctly
    if ( [[NSUserDefaults standardUserDefaults] integerForKey:@"envelope_top"] != 0 )
    {
        [envelopeWindow setFrameTopLeftPoint:NSMakePoint([[NSUserDefaults standardUserDefaults] integerForKey:@"envelope_left"], [[NSUserDefaults standardUserDefaults] integerForKey:@"envelope_top"])];
    }
	
    [envelopeWindow setBackgroundColor:[NSColor whiteColor]];
	
    [self populateEnvelopeProfilePopup];
	
    [self setEnvelopeWindowFrame];
	
    if ( [[NSUserDefaults standardUserDefaults] boolForKey:@"hide_margin_guides"] == YES )
    {
		[marginGuidelinesMenuItem setState:NSOffState];
		[self hideMargins];
    }
    else
    {
		[marginGuidelinesMenuItem setState:NSOnState];
		[self showMargins];
    }
    	
    [envelopeProfilePopup setTarget:self];
    [envelopeProfilePopup setAction:@selector(selectEnvelopeProfile)];
	
	if ( [cePrefs valueForKey:@"from_type"] )
		[fromTypePopup selectItemAtIndex:[[cePrefs valueForKey:@"from_type"] intValue]];
	else
		[fromTypePopup selectItemAtIndex:[[cePrefs valueForKey:@"manual_from"] intValue]];  // for older versions (remove after next release?)
	[fromTypePopup setTarget:self];
    [fromTypePopup setAction:@selector(selectFromType)];
	
    [fromPopup setTarget:self];
    [fromPopup setAction:@selector(selectFromAddress)];
	
    for ( i = 0; i < [[addressDB groups] count]; i++ )
    {
		if ( [[[addressDB groups] objectAtIndex:i] valueForProperty:kABGroupNameProperty] == nil || [[[[addressDB groups] objectAtIndex:i] valueForProperty:kABGroupNameProperty] isEqualToString:@""] )
		{
			[fromGroupPopup addItemWithTitle:@"?"];
		}
		else
		{
			[fromGroupPopup addItemWithTitle:[[[addressDB groups] objectAtIndex:i] valueForProperty:kABGroupNameProperty]];
		}
    }
	
    if ( [cePrefs objectForKey:@"barcodeType"] == NULL )
    {
        [barcodePopup selectItemAtIndex:0];
    }
    else
    {
        [barcodePopup selectItemWithTitle:
            [cePrefs objectForKey:@"barcodeType"]
            ];
    }
	
    if ( [cePrefs objectForKey:@"fromGroup"] == NULL
         ||
         [fromGroupPopup indexOfItemWithTitle:[cePrefs objectForKey:@"fromGroup"]] == -1 )
    {
        [fromGroupPopup selectItemAtIndex:0];
    }
    else
    {
        [fromGroupPopup selectItemWithTitle:[cePrefs objectForKey:@"fromGroup"]];
    }
	
    [self refreshFromAddresses];
	
    if ( [cePrefs objectForKey:@"from_address_content"] )
    {
        [fromView setAttributedString:[NSUnarchiver unarchiveObjectWithData:[cePrefs objectForKey:@"from_address_content"]]];
    }
	
    if ( [fromTypePopup indexOfSelectedItem] != 1)
    {
		if ( [fromPopup numberOfItems] > [[cePrefs valueForKey:@"from_address_menu_index"] intValue] )
		{
			[fromPopup selectItemAtIndex:[[cePrefs valueForKey:@"from_address_menu_index"] intValue]];
		}
		else
		{		
			NSLog(@"from_address_menu_index greater than fromPopup item count (different from group?)");
			[fromPopup selectItemAtIndex:0];
		}
		
		[self selectFromType];
    }
	
	if ( [[NSUserDefaults standardUserDefaults] objectForKey:@"to_address"] )
	{
		[self setToAddress:[[NSUserDefaults standardUserDefaults] objectForKey:@"to_address"] forPerson:nil];
	}
	
    if ( [cePrefs objectForKey:@"to_address_content"] == NULL )
    {
		[toView setAttributedString:[[NSAttributedString alloc] initWithString:@""]];
    }
    else
    {
        [toView setAttributedString:[NSUnarchiver unarchiveObjectWithData:[cePrefs objectForKey:@"to_address_content"]]];
    }
	
    if ( [cePrefs objectForKey:@"background_content"] != NULL )
    {
		[backgroundView setAttributedString:[cePrefs objectForKey:@"background_content"]];
    }
	
    if ( [[NSUserDefaults standardUserDefaults] objectForKey:@"barcode"] != NULL )
    {
		[[self barcodeView] removeFromSuperview];
        [self setBarcode:[NSUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] objectForKey:@"barcode"]] ];
        [self setBarcodeView:[[NKDBarcodeOffscreenView alloc]
            initWithBarcode:[self barcode]
            ]];
        [printableView addSubview:barcodeView];
        [self positionBarcodeViewForType:[barcodePopup indexOfSelectedItem]];
        [printableView display];
    }
}

#pragma mark Accessor Methods

- (NSMutableDictionary *)cePrefs
{
	return cePrefs;
}

- (void)setCePrefs:(NSDictionary *)aDict
{
	[cePrefs autorelease];
	cePrefs = [aDict mutableCopy];
}

- (NSAttributedString *)fromAttributes
{
	if ( ! [cePrefs objectForKey:@"from_attributes"] )
		[cePrefs setObject:[[AddressManager sharedAddressManager] defaultAddressAttributesString]
										   forKey:@"from_attributes"];

	return [cePrefs objectForKey:@"from_attributes"];
}

- (void)setFromAttributes:(NSAttributedString *)attString
{
	NSAttributedString *fixedString = [[[AddressManager sharedAddressManager] defaultAddressAttributesString] addMatchingAttributesFromString:attString];
	
	[cePrefs setObject:fixedString forKey:@"from_attributes"];
}

- (NSAttributedString *)toAttributes
{
	if ( ! [cePrefs objectForKey:@"to_attributes"] )
		[cePrefs setObject:[[AddressManager sharedAddressManager] defaultAddressAttributesString]
										   forKey:@"to_attributes"];
		
	return [cePrefs objectForKey:@"to_attributes"];
}

- (void)setToAttributes:(NSAttributedString *)attString
{
	NSAttributedString *fixedString = [[[AddressManager sharedAddressManager] defaultAddressAttributesString] addMatchingAttributesFromString:attString];

	[cePrefs setObject:fixedString forKey:@"to_attributes"];
}

- (NSDictionary *)fromAddress
{
    return fromAddress;
}

- (void)setFromAddress:(NSDictionary *)addr
{
    [fromAddress autorelease];
    fromAddress = [addr retain];
}

- (NSDictionary *)toAddress
{
    return toAddress;
}

- (void)setToAddress:(NSDictionary *)addr forPerson:(ABPerson *)pers
{
    [toAddress autorelease];
	
	if ( ! addr )
	{	
		toAddress = nil;
	}
	else
	{
		toAddress = [[[AddressManager sharedAddressManager] addressDictForPerson:pers
																		sequence:nil
																		   label:nil
																		 address:addr
																		  prefix:[self toPrefix]
																		  suffix:[self toSuffix]
																	   swapNames:[[cePrefs objectForKey:@"to_swap_names"] intValue]
			] retain];
	}
}

- (NKDBarcodeOffscreenView *)barcodeView
{
    return barcodeView;
}

- (void)setBarcodeView:(NKDBarcodeOffscreenView *)view
{
    [barcodeView autorelease];
    barcodeView = [view retain];
}


- (NKDBarcode *)barcode
{
    return barcode;
}

- (void)setBarcode:(NKDBarcode *)aBarcode
{
    [barcode autorelease];
    barcode = [aBarcode retain];
}

- (NSArray *)fromAddresses
{
    return fromAddresses;
}

- (void)setFromAddresses: (NSArray *)addressList
{
    [fromAddresses autorelease];
    fromAddresses = [addressList retain];
}

- (void)setEnvelopeProfiles:(NSMutableDictionary *)profileList
{
    [envelopeProfiles autorelease];
    envelopeProfiles = [profileList retain];
}

- (NSMutableDictionary *)envelopeProfiles
{
    return envelopeProfiles;
}

- (void)setCurrentEnvelopeProfile:(EnvelopeProfile *)aProfile
{
	[currentEnvelopeProfile setPrefs:cePrefs];

    [currentEnvelopeProfile autorelease];
    currentEnvelopeProfile = [aProfile retain];
	
	[self setCePrefs:[currentEnvelopeProfile prefs]];
}

- (EnvelopeProfile *)currentEnvelopeProfile
{
    return currentEnvelopeProfile;
}

- (void)setProfileNames:(NSMutableArray *)names
{
    [profileNames autorelease];
    profileNames = [names retain];
}

- (NSMutableArray *)profileNames
{
    return profileNames;
}

- (void)setNewProfiles:(NSMutableDictionary *)profileList
{
    [newProfiles autorelease];
    newProfiles = [profileList retain];
}

- (NSMutableDictionary *)newProfiles
{
    return newProfiles;
}

#pragma mark Other Methods

- (void)populateEnvelopeProfilePopup
{
    int i;
    NSMenuItem *editProfilesItem = [[envelopeProfilePopup itemAtIndex:
		([envelopeProfilePopup numberOfItems] -1)] retain];
	
    [envelopeProfilePopup removeAllItems];
	
    for ( i = 0; i < [profileNames count]; i++ )
    {
		[envelopeProfilePopup addItemWithTitle:[profileNames objectAtIndex:i]];
    }
	
    [envelopeProfilePopup addItemWithTitle:[editProfilesItem title]];
    [[envelopeProfilePopup lastItem] setTarget:[editProfilesItem target]];
    [[envelopeProfilePopup lastItem] setAction:[editProfilesItem action]];
    [editProfilesItem release];
	
    [envelopeProfilePopup selectItemWithTitle:[[envelopeProfiles allKeysForObject:currentEnvelopeProfile] objectAtIndex:0]];
}

- (NSDictionary *)addressDictForPerson:(ABPerson *)pers address:(NSDictionary *)addr afterToFromPrefs:(NSString *)toFrom
{
	NSDictionary *addrDict;
	
	if ( [toFrom isEqualToString:@"TO"] )
	{
		addrDict = [[AddressManager sharedAddressManager] addressDictForPerson:pers
																	  sequence:nil
																		 label:nil
																	   address:addr
																		prefix:[self toPrefix]
																		suffix:[self toSuffix]
																	 swapNames:[[cePrefs objectForKey:@"to_swap_names"] intValue]];
	}
	else if ( [toFrom isEqualToString:@"FROM"] )
	{
		addrDict = [[AddressManager sharedAddressManager] addressDictForPerson:pers
																	  sequence:nil
																		 label:nil
																	   address:addr
																		prefix:[self fromPrefix]
																		suffix:[self fromSuffix]
																	 swapNames:[[cePrefs objectForKey:@"from_swap_names"] intValue]];
	}
	else
	{
		return nil;
	}
	
	return [self addressDict:addrDict afterToFromPrefs:toFrom];
}

- (NSDictionary *)addressDict:(NSDictionary *)addr afterToFromPrefs:(NSString *)toFrom
{
	int hidePrefix;
    int hideSuffix;
	int hideTitle;
    int hideName;
    int hideJobTitle;
    int hideCompany = 0;
	BOOL hideCountry = NO;
	NSMutableDictionary *personAddress = [[addr mutableCopy] autorelease];
	
	if ( [toFrom isEqualToString:@"FROM"] )
    {
		hidePrefix = [[cePrefs objectForKey:@"hide_from_prefix"] intValue];
		hideSuffix = [[cePrefs objectForKey:@"hide_from_suffix"] intValue];
		hideTitle = [[cePrefs objectForKey:@"hide_from_title"] intValue];
        hideName = [[cePrefs objectForKey:@"hide_from_name"] intValue];
        hideJobTitle = [[cePrefs objectForKey:@"hide_from_job_title"] intValue];
		
		if ( ! [[personAddress objectForKey:@"type"] isEqualToString:@"COMPANY"] )
			hideCompany = [[cePrefs objectForKey:@"hide_from_company"] intValue];

        if ( [[cePrefs objectForKey:@"hide_from_country"] intValue] )
		{
			if ( [[cePrefs objectForKey:@"hide_from_same_country"] intValue] )
			{
				if ( [self sameToFromCountries]
					 || ! [toAddress objectForKey:kABAddressCountryKey]
					 || [[toAddress objectForKey:kABAddressCountryKey] isEqualToString:@""]
					 )
				{
					hideCountry = YES;
				}
			}
			else
			{
				hideCountry = YES;
			}
		}
    }
    else if ( [toFrom isEqualToString:@"TO"] )
    {
		hidePrefix = [[cePrefs objectForKey:@"hide_to_prefix"] intValue];
		hideSuffix = [[cePrefs objectForKey:@"hide_to_suffix"] intValue];
		hideTitle = [[cePrefs objectForKey:@"hide_to_title"] intValue];
        hideName = [[cePrefs objectForKey:@"hide_to_name"] intValue];
        hideJobTitle = [[cePrefs objectForKey:@"hide_to_job_title"] intValue];
        
		if ( ! [[personAddress objectForKey:@"type"] isEqualToString:@"COMPANY"] )
			hideCompany = [[cePrefs objectForKey:@"hide_to_company"] intValue];
		
		if ( [[cePrefs objectForKey:@"hide_to_country"] intValue] )
		{
			if ( [[cePrefs objectForKey:@"hide_to_same_country"] intValue] )
			{
				if ( [self sameToFromCountries]
					 || ! [fromAddress objectForKey:kABAddressCountryKey]
					 || [[fromAddress objectForKey:kABAddressCountryKey] isEqualToString:@""]
					 )
				{
					hideCountry = YES;
				}
			}
			else
			{
				hideCountry = YES;
			}
		}
    }
	else
	{
		return nil;
	}
	
	if ( hidePrefix )
		[personAddress removeObjectForKey:@"AddressPrefix"];
	if ( hideSuffix )
		[personAddress removeObjectForKey:@"AddressSuffix"];
	
	if ( hideName )
	{
		[personAddress removeObjectForKey:kABTitleProperty];
		[personAddress removeObjectForKey:kABFirstNameProperty];
		[personAddress removeObjectForKey:kABMiddleNameProperty];
		[personAddress removeObjectForKey:kABLastNameProperty];
		[personAddress removeObjectForKey:kABSuffixProperty];
	}
	else if ( hideTitle )
	{
		[personAddress removeObjectForKey:kABTitleProperty];
	}
	
	if ( hideJobTitle )
		[personAddress removeObjectForKey:kABJobTitleProperty];
	
	if ( hideCompany )
		[personAddress removeObjectForKey:kABOrganizationProperty];
	
	if ( hideCountry )
		[personAddress setObject:@"" forKey:kABAddressCountryKey];
	
	return [[personAddress copy] autorelease];
}

- (BOOL)sameToFromCountries
{
	int i;
	NSArray *localCountryNames;
	NSString *fromCountry;
	NSString *toCountry;
		
	if ( ! fromAddress || ! toAddress )
		return NO;
	
	fromCountry = [fromAddress objectForKey:kABAddressCountryKey];
	toCountry = [toAddress objectForKey:kABAddressCountryKey];
	
	if ( ! toCountry )
		return YES;
	
	if ( ! fromCountry )
		return NO;
	
	if ( [fromCountry isEqualToString:toCountry] )
		return YES;
	
	if ( [cePrefs objectForKey:@"local_country_names"] )
		localCountryNames = [cePrefs objectForKey:@"local_country_names"];
	else
		return NO;
	
	for ( i = 0; i < [localCountryNames count]; i++ )
	{
		if ( [toCountry isEqualToString:[localCountryNames objectAtIndex:i]] )
			return YES;
	}
	
	return NO;
}

- (void)selectFromType
{
    if ( [fromTypePopup indexOfSelectedItem] == 0 && [fromAddresses count] > 0 )
        [fromPopup setEnabled:YES];
    else
        [fromPopup setEnabled:NO];

	if ( [fromTypePopup indexOfSelectedItem] == 1 )
	{
        [fromPopup setHidden:YES];
		[self setFromAddress:nil];
	}
	else
	{
        [fromPopup setHidden:NO];
        [self selectFromAddress];
	}

	if ( [fromTypePopup indexOfSelectedItem] == 2 )
	{
		if ( [[fromView enclosingScrollView] superview] )
		{
			[[fromView enclosingScrollView] retain];
			[[fromView enclosingScrollView] removeFromSuperview];
		}
	}
	else
	{
		if ( [[fromView enclosingScrollView] superview] != printableView )
		{
			[printableView addSubview:[[fromView enclosingScrollView] autorelease]];
		}
	}
	
	[cePrefs setValue:[NSNumber numberWithInt:[fromTypePopup indexOfSelectedItem]] forKey:@"from_type"];
}

- (void)selectFromAddress
{
	NSAttributedString *fromFormatted;

	if ( [fromPopup indexOfSelectedItem] < 0 )
        [fromPopup selectItemAtIndex:0];

	if ( [fromTypePopup indexOfSelectedItem] == 1 || [fromAddresses count] < 1 )
	{
		[self setFromAddress:nil];
	}
	else
    {
        [self setFromAddress:[fromAddresses objectAtIndex:[fromPopup indexOfSelectedItem]]];
		
		fromFormatted = [[AddressManager sharedAddressManager] addressStringForAddressDict:
			[self addressDict:fromAddress afterToFromPrefs:@"FROM"]
			];
		
		[fromView setAttributedString:[fromFormatted addMatchingAttributesFromString:[self fromAttributes]]];
    }
	
	[cePrefs setValue:[NSNumber numberWithInt:[fromPopup indexOfSelectedItem]] forKey:@"from_address_menu_index"];

	//  Make sure any overlapped views (eg, barcode view, to view) are also redisplayed
	[printableView display];
}

- (void)selectToAddressUpdatingFromAddress
{
	NSDictionary *theAddress;
    ABPerson *thePerson;
	ABMultiValue *personAddressList;
	NSArray *selectedIdentifiers;
	
	if ( [[peoplePicker selectedRecords] count] <= 0 )
	{
		[self selectFromAddress];
		
		return;
	}
	
	thePerson = [[peoplePicker selectedRecords] objectAtIndex:0];
	personAddressList = [thePerson valueForProperty:kABAddressProperty];
	selectedIdentifiers = [peoplePicker selectedIdentifiersForPerson:thePerson];
	
	if ( [personAddressList count] > 0 )
		theAddress = [personAddressList valueAtIndex:[personAddressList indexForIdentifier:[selectedIdentifiers objectAtIndex:0]]];
	else
		theAddress = [NSDictionary dictionary];
	
	[self setToAddress:theAddress forPerson:thePerson];
	[self addressEnvelope];
	
	//  Update from address in case country needs to be hidden/shown
	//  This also re-displays the entire printableView to avoid leaving view (eg, barcode) artefacts on screen
	[self selectFromAddress];
}

- (void)addressEnvelope
{
	NSDictionary *toDict = [self addressDict:toAddress afterToFromPrefs:@"TO"];
	NSAttributedString *toFormatted = [[AddressManager sharedAddressManager] addressStringForAddressDict:toDict];
	
	[toView setAttributedString:[toFormatted addMatchingAttributesFromString:[self toAttributes]]];
	
	[[self barcodeView] removeFromSuperview];
    [self setBarcodeView:nil];
    [self setBarcode:nil];
	
    if ( [barcodePopup indexOfSelectedItem] > 1
         &&
         ( [toAddress objectForKey:kABAddressCountryKey] == nil
           || [[toAddress objectForKey:kABAddressCountryKey] isEqualToString:@""]
           || [self sameToFromCountries]
           //|| ( ( [fromTypePopup indexOfSelectedItem] != 1 )
           //     && [[toAddress objectForKey:kABAddressCountryKey] isEqualToString:[[self fromAddress] objectForKey:kABAddressCountryKey]]
           //     )
           )
         )
    {
        [self setBarcode:[PostalBarcodeGenerator barcodeOfType:[barcodePopup indexOfSelectedItem] forAddress:toAddress]];
		
        if ( [self barcode] == nil )
        {
            [self setBarcodeView:nil];
        }
        else
        {
            [self setBarcodeView:[[NKDBarcodeOffscreenView alloc] initWithBarcode:[self barcode]]];
            [printableView addSubview:barcodeView];
            [self positionBarcodeViewForType:[barcodePopup indexOfSelectedItem]];
        }
    }
}

- (void)positionBarcodeViewForType:(int)type
{
    NSRect frame;
	
    if ( type == 2 )
    {
		frame = [[toView enclosingScrollView] frame];
		frame.origin.x += 5;
		
		if ( [[cePrefs valueForKey:@"barcode_position"] intValue] == 1 )
			frame.origin.y += ( frame.size.height + 5 );
		
		[barcodeView setFrameOrigin:frame.origin];
	}
}

- (void)printEnvelopesToPersonalisedAddresses:(NSArray *)personalisedAddressList
{
    int i;
	NSAttributedString *formattedAddress;
    NSDictionary *personalisedAddress;
    NSView *multiPrintView = [[NSView alloc] init];
    NSTextView *addrTextView;
    NKDBarcode *addrBarcode;
    NSRect masterFrame;
    NSSize paperSize = [[currentEnvelopeProfile printInfo] paperSize];
    float paperWidth = paperSize.width - ([[currentEnvelopeProfile printInfo] leftMargin] + [[currentEnvelopeProfile printInfo] rightMargin]);
    float paperHeight = paperSize.height - ([[currentEnvelopeProfile printInfo] topMargin] + [[currentEnvelopeProfile printInfo] bottomMargin]);
    int addrCount = [personalisedAddressList count];
	NSPrintInfo *printInfo = [NSPrintInfo sharedPrintInfo];
	
	if ( [currentEnvelopeProfile printInfo] )
		printInfo = [currentEnvelopeProfile printInfo];

    [multiPrintView setFrameSize:NSMakeSize(paperWidth, paperHeight * addrCount)];
	
    for ( i = 0; i < addrCount; i++ )
    {
		personalisedAddress = [personalisedAddressList objectAtIndex:(addrCount - (i+1))];
		
        // Set up a "From" text view and make it a subview of the multiPrintView
		
		if ( [fromTypePopup indexOfSelectedItem] != 2 )
		{
			masterFrame = [[fromView enclosingScrollView] frame];
			masterFrame.origin.y += paperHeight * i;
			addrTextView = [[NSTextView alloc] initWithFrame:masterFrame];
			[multiPrintView addSubview:addrTextView];
			[addrTextView setAttributedString:[fromView attributedString]];
		}
		        
        // Set up a "To" text view and make it a subview of the multiPrintView
		
        masterFrame = [[toView enclosingScrollView] frame];
        masterFrame.origin.y += paperHeight * i;
        addrTextView = [[NSTextView alloc] initWithFrame:masterFrame];
        [multiPrintView addSubview:addrTextView];
		formattedAddress = [[AddressManager sharedAddressManager] addressStringForAddressDict:personalisedAddress];
		[addrTextView setAttributedString:[formattedAddress addMatchingAttributesFromString:[self toAttributes]]];
		
		// Set up a barcode view and make it a subview of the multiPrintView
		
		[[self barcodeView] removeFromSuperview];
		[self setBarcodeView:nil];
		addrBarcode = nil;
		
		if ( [barcodePopup indexOfSelectedItem] > 1
			 &&
			 ( [personalisedAddress objectForKey:kABAddressCountryKey] == nil
			   || [[personalisedAddress objectForKey:kABAddressCountryKey] isEqualToString:@""]
			   || [self sameToFromCountries]
			   || ( [fromPopup isEnabled]
					&& [[personalisedAddress objectForKey:kABAddressCountryKey] isEqualToString:[[self fromAddress] objectForKey:kABAddressCountryKey]]
					)
			   )
			 )
		{
			addrBarcode = [PostalBarcodeGenerator barcodeOfType:[barcodePopup indexOfSelectedItem] forAddress:personalisedAddress];
			
			if ( addrBarcode == nil )
			{
				[self setBarcodeView:nil];
			}
			else
			{
				[self setBarcodeView:[[NKDBarcodeOffscreenView alloc] initWithBarcode:addrBarcode]];
				[printableView addSubview:barcodeView];
				[self positionBarcodeViewForType:[barcodePopup indexOfSelectedItem]];
				
				masterFrame = [barcodeView frame];
				masterFrame.origin.y += paperHeight * i;
				
				[barcodeView removeFromSuperview];
				[multiPrintView addSubview:barcodeView];
				[barcodeView setFrame:masterFrame];
				[self setBarcodeView:nil];
			}
		}
		
    }
	
    //  Return the barcode view to it's former state
    [[self barcodeView] removeFromSuperview];
    [self setBarcode:barcode];
    if ( barcode != nil )
    {
		[self setBarcodeView:[[NKDBarcodeOffscreenView alloc] initWithBarcode:[self barcode]]];
		[printableView addSubview:barcodeView];
		[self positionBarcodeViewForType:[barcodePopup indexOfSelectedItem]];
    }
	
    // Print the assembled views in the "multiPrintView"
    [multiPrintView setNeedsDisplay:YES];

	NSPrintOperation *printOp = [NSPrintOperation printOperationWithView:multiPrintView printInfo:printInfo];
	[printOp runOperation];
	[currentEnvelopeProfile setPrintInfo:[printOp printInfo]];
    
	[multiPrintView release];
}

- (void)refreshFromAddresses
{
    int fromIndex;
    int i;

    [fromAddresses removeAllObjects];
    [fromAddresses addObjectsFromArray:[self personalisedFromAddresses]];
	
    [fromPopup removeAllItems];
	
	fromIndex = [[cePrefs valueForKey:@"from_address_menu_index"] intValue];

    if ( [fromAddresses count] > 0 )
    {
		if ( [[cePrefs valueForKey:@"fromGroupIndex"] intValue] > 0 )
		{
			for ( i = 0; i < [fromAddresses count]; i++ )
			{
				[fromPopup addItemWithTitle:[NSString stringWithFormat:@"%@ (%@)",
					[[AddressManager sharedAddressManager] alphaName:[fromAddresses objectAtIndex:i]],
					[[AddressManager sharedAddressManager] linearAddress:[fromAddresses objectAtIndex:i]]
					]];
			}
		}
		else
		{
			for ( i = 0; i < [fromAddresses count]; i++ )
			{
				[fromPopup addItemWithTitle:
					[[AddressManager sharedAddressManager] linearAddress:[fromAddresses objectAtIndex:i]]
					];
			}
		}
		
        if ( [fromPopup numberOfItems] > fromIndex )
            [fromPopup selectItemAtIndex:fromIndex];
        else
            [fromPopup selectItemAtIndex:0];
		
        if ( [fromTypePopup indexOfSelectedItem] == 0 )
        {
            [fromPopup setEnabled:YES];
        }
        else
        {
            [fromPopup setEnabled:NO];
            [self setFromAddress:nil];            
        }
    }
    else
    {
        [fromPopup insertItemWithTitle:@"(None)" atIndex:0];
        [fromPopup setEnabled:NO];
        [self setFromAddress:nil];
    }
}

- (NSArray *)personalisedFromAddresses
{
    ABMultiValue *addrList;
	NSMutableArray *personAddresses = [[[NSMutableArray alloc] init] autorelease];
    NSArray *people;
    int i, j;
	
    if ( [[cePrefs valueForKey:@"fromGroupIndex"] intValue] == 0 )
    {
		if ( [addressDB me] )
			people = [NSArray arrayWithObject:[addressDB me]];
		else
			people = [NSArray array];
    }
    else if ( [[cePrefs valueForKey:@"fromGroupIndex"] intValue] == 1 )
    {
		people = [addressDB people];
    }
    else if ( [[cePrefs valueForKey:@"fromGroupIndex"] intValue] > 1 )
    {
        people = [[[addressDB groups] objectAtIndex:([[cePrefs valueForKey:@"fromGroupIndex"] intValue] - 2)] members];
    }
    else
    {
        people = [NSArray array];
    }
	
	people = [people sortedArrayUsingSelector:@selector(compare:)];

    for ( i = 0; i < [people count]; i++ )
    {
		addrList = [[people objectAtIndex:i] valueForProperty:kABAddressProperty];
		
		for ( j = 0; j < [addrList count]; j++ )
		{
			[personAddresses addObject:
				[[AddressManager sharedAddressManager] addressDictForPerson:[people objectAtIndex:i]
																   sequence:[NSNumber numberWithInt:j]
																	  label:[addrList labelAtIndex:j]
																	address:[addrList valueAtIndex:j]
																	 prefix:[self fromPrefix]
																	 suffix:[self fromSuffix]
																  swapNames:[[cePrefs objectForKey:@"from_swap_names"] intValue]
					]];
		}
	}
	
    return [[personAddresses copy] autorelease];
}

- (void)changeNewProfilesItem:(int)index toName:(NSString *)name
{
    // Check for new name that hasn't actually been added yet
    // and for name change that's actually no different to what it was
    if ( index < [profileNames count] && ! [name isEqualToString:[profileNames objectAtIndex:index]] )
    {
		[newProfiles setObject:[newProfiles objectForKey:[profileNames objectAtIndex:index]] forKey:name];
		[newProfiles removeObjectForKey:[profileNames objectAtIndex:index]];
		
		[self setProfileNames:[[[newProfiles allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)] mutableCopy]];
		[envelopeProfilesTable reloadData];
		[envelopeProfilesTable selectRow:[profileNames indexOfObject:name] byExtendingSelection:NO];
    }
}

- (BOOL)profileNameExists:(NSString *)str
{
    int i;
    BOOL found = NO;
	
    for ( i = 0; i < [profileNames count] && !found; i++ )
    {
		if ( [[profileNames objectAtIndex:i] isEqualToString:str] )
			found = YES;
    }
	
    if ( found )
		return YES;
    else
		return NO;
}

- (void)alignViewsToMargins
{
    NSRect envelopeRect = [[envelopeWindow contentView] frame];
    NSRect printableRect, fromRect, toRect;
	
    // Set printable frame
	
    printableRect.origin.x = [[currentEnvelopeProfile printInfo] leftMargin];
    printableRect.origin.y = [[currentEnvelopeProfile printInfo] bottomMargin];
    printableRect.size.width = envelopeRect.size.width
        - [[currentEnvelopeProfile printInfo] leftMargin]
        - [[currentEnvelopeProfile printInfo] rightMargin];
    printableRect.size.height = envelopeRect.size.height
        - [[currentEnvelopeProfile printInfo] topMargin]
        - [[currentEnvelopeProfile printInfo] bottomMargin];
	
    [printableView setFrame:printableRect];
	
    // Set "From" frame
	
    fromRect.origin.x = [currentEnvelopeProfile marginFromLeft]
		- [[currentEnvelopeProfile printInfo] leftMargin];
    fromRect.origin.y = [currentEnvelopeProfile marginFromBottom]
		- [[currentEnvelopeProfile printInfo] bottomMargin];
    fromRect.size.width = envelopeRect.size.width
		- [currentEnvelopeProfile marginFromRight]
		- [currentEnvelopeProfile marginFromLeft];
    fromRect.size.height = envelopeRect.size.height
		- [currentEnvelopeProfile marginFromTop]
		- [currentEnvelopeProfile marginFromBottom] ;
	
    [[fromView enclosingScrollView] setFrame:fromRect];
	
    // Set "To" frame
	
    toRect.origin.x = [currentEnvelopeProfile marginToLeft]
		- [[currentEnvelopeProfile printInfo] leftMargin];
    toRect.origin.y = [currentEnvelopeProfile marginToBottom]
		- [[currentEnvelopeProfile printInfo] bottomMargin];
    toRect.size.width = envelopeRect.size.width
		- [currentEnvelopeProfile marginToRight]
		- [currentEnvelopeProfile marginToLeft];
    toRect.size.height = envelopeRect.size.height
		- [currentEnvelopeProfile marginToTop]
		- [currentEnvelopeProfile marginToBottom];
	
    [[toView enclosingScrollView] setFrame:toRect];
	
    // Set barcode frame (if present)
    if ( [[self barcodeView] superview] == printableView )
    {
        [self positionBarcodeViewForType:[barcodePopup indexOfSelectedItem]];
    }
	
	//  Set background view frame
	[[backgroundView enclosingScrollView] setFrame:[printableView frame]];
	[[backgroundView enclosingScrollView] setFrameOrigin:NSMakePoint(0,0)];
	
    // Redisplay contents of envelope window (including all subviews)
    [[envelopeWindow contentView] display];
}

- (void)setEnvelopeWindowFrame
{
    NSSize paperSize = [[currentEnvelopeProfile printInfo] paperSize];
    NSRect oldFrame = [envelopeWindow frame];
	
	//  Use 1 point less that actual size to avoid printing second blank page (requires testing)
    [envelopeWindow setContentSize:NSMakeSize(paperSize.width - 1.0, paperSize.height - 1.0)];
    [envelopeWindow setFrameTopLeftPoint:
        NSMakePoint(oldFrame.origin.x,
                    oldFrame.origin.y + oldFrame.size.height)];
    
    [self alignViewsToMargins];
}

- (void)selectEnvelopeProfile
{
	if ( [envelopeProfilePopup selectedItem] == [envelopeProfilePopup lastItem] )
    {
		[self invokeEnvelopeProfilesWindow];
    }
    else
    {
		[cePrefs setObject:[NSArchiver archivedDataWithRootObject:[fromView attributedString]] forKey:@"from_address_content"];
		[cePrefs setValue:[NSNumber numberWithInt:[fromTypePopup indexOfSelectedItem]] forKey:@"from_type"];

		[self setCurrentEnvelopeProfile:[envelopeProfiles objectForKey:[envelopeProfilePopup titleOfSelectedItem]]];

		[self setEnvelopeWindowFrame];
		[backgroundView setAttributedString:[cePrefs objectForKey:@"background_content"]];
		
		[fromTypePopup selectItemAtIndex:[[cePrefs valueForKey:@"from_type"] intValue]];
		[self selectFromType];
		
		[self refreshFromAddresses];
		if ( [fromPopup numberOfItems] > [[cePrefs valueForKey:@"from_address_menu_index"] intValue] )
			[fromPopup selectItemAtIndex:[[cePrefs valueForKey:@"from_address_menu_index"] intValue]];
		[self selectToAddressUpdatingFromAddress];
		if ( [fromTypePopup indexOfSelectedItem] == 1 )
		{
			if ( [cePrefs objectForKey:@"from_address_content"] )
				[fromView setAttributedString:[NSUnarchiver unarchiveObjectWithData:[cePrefs objectForKey:@"from_address_content"]]];
			else
				[fromView setString:@""];
		}
			
	}
}

- (void)invokeEnvelopeProfilesWindow
{
    int sessionResult;
    NSModalSession profilesSession;
	
    [self setNewProfiles:[envelopeProfiles mutableCopy]];
	
    [self setProfileNames:[[[envelopeProfiles allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)] mutableCopy]];
    [envelopeProfilesTable reloadData];
	
    [envelopeProfilesTable deselectAll:self];
    if ( [[self profileNames] count] > 1 )
		[envelopeProfilesDeleteButton setEnabled:YES];
    else
		[envelopeProfilesDeleteButton setEnabled:NO];
	
    [envelopeProfilesWindow center];
    profilesSession = [[NSApplication sharedApplication] beginModalSessionForWindow:envelopeProfilesWindow];
	
    for (;;)
    {
		sessionResult = [[NSApplication sharedApplication] runModalSession:profilesSession];
		
        if ( sessionResult == 1 )
		{
			// User clicked "New"
			[envelopeProfilesTable deselectAll:self];
			[newProfiles setObject:[currentEnvelopeProfile copy] forKey:@""];
			[profileNames addObject:@""];
			[envelopeProfilesTable reloadData];
			[envelopeProfilesTable selectRow:([profileNames count] - 1) byExtendingSelection:NO];
			[envelopeProfilesTable editColumn:0 row:([profileNames count] - 1) withEvent:nil select:YES];
			[envelopeProfilesOKButton setEnabled:NO];
			[envelopeProfilesNewButton setEnabled:NO];
			[envelopeProfilesDeleteButton setEnabled:YES];
			
			[[NSApplication sharedApplication] endModalSession:profilesSession];
			profilesSession = [[NSApplication sharedApplication] beginModalSessionForWindow:envelopeProfilesWindow];
		}
		else if ( sessionResult == -1 )
		{
			// User clicked "Delete"
			if ( [envelopeProfilesTable selectedRow] >= 0 )
			{
				[envelopeProfilesOKButton setEnabled:YES];
				[envelopeProfilesNewButton setEnabled:YES];
				[newProfiles removeObjectForKey:[profileNames objectAtIndex:[envelopeProfilesTable selectedRow]]];
				[profileNames removeObjectAtIndex:[envelopeProfilesTable selectedRow]];
				[envelopeProfilesTable reloadData];
				if ( [profileNames count] <= 1 )
					[envelopeProfilesDeleteButton setEnabled:NO];
			}
			
			[[NSApplication sharedApplication] endModalSession:profilesSession];
			profilesSession = [[NSApplication sharedApplication] beginModalSessionForWindow:envelopeProfilesWindow];
		}
		else if ( sessionResult == NSRunAbortedResponse )
		{
			// User clicked "Cancel"
			[self setProfileNames:[[[envelopeProfiles allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)] mutableCopy]];
			
			[envelopeProfilePopup selectItemWithTitle:[[envelopeProfiles allKeysForObject:currentEnvelopeProfile] objectAtIndex:0]];
			break;
		}
		else if ( sessionResult == NSRunStoppedResponse )
		{
			// User clicked "OK"
			[envelopeProfilesTable deselectAll:self];
			[self setEnvelopeProfiles:newProfiles];
			[self setProfileNames:[[[envelopeProfiles allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)] mutableCopy]];
			if ( [[envelopeProfiles allKeysForObject:currentEnvelopeProfile] count] == 0 )
			{
				[self setCurrentEnvelopeProfile:[envelopeProfiles objectForKey:[profileNames objectAtIndex:0]]];
			}
			[self populateEnvelopeProfilePopup];
			break;
		}
		// ELSE must be NSRunContinuesResponse, in which case do nothing
    }
    
    [[NSApplication sharedApplication] endModalSession:profilesSession];
    [envelopeProfilesWindow orderOut:self];
}

- (oneway void)pluginPrintEnvelopeForPerson:pers address:addr
{
	[peoplePicker deselectAll:self];
	[toView setString:@""];
	[barcodeView removeFromSuperview];
	
	//  If Snail Mail is not active bring the envelope window to front and activate Snail Mail
	if ( ! [NSApp isActive] )
	{
		[NSApp activateIgnoringOtherApps:YES];
		[envelopeWindow makeKeyAndOrderFront:self];
	}
	
	[self setToAddress:addr forPerson:pers];
	[self selectFromAddress];
	[self addressEnvelope];
	[self printEnvelope:self];
}

- (BOOL)applyMarginsChange
{
    NSSize paperSize = [[currentEnvelopeProfile printInfo] paperSize];
	
    if ( ( [marginFromLeftField intValue] + [marginFromRightField intValue] )
		 >= paperSize.width )
    {
        NSRunAlertPanel([[NSBundle mainBundle] localizedStringForKey:@"InvalidMargins"
															   value:@"Invalid Margins"
															   table:@"Localizable"],
                        [[NSBundle mainBundle] localizedStringForKey:@"FromLeftRightBad"
															   value:@"The Return Address left and right margins exceed the current paper width."
															   table:@"Localizable"],
                        [[NSBundle mainBundle] localizedStringForKey:@"Cancel"
															   value:@"Cancel"
															   table:@"Localizable"],
                        NULL,
                        NULL
                        );
		return NO;
    }
    else if ( ( [marginFromTopField intValue] + [marginFromBottomField intValue] )
              >= paperSize.height )
    {
        NSRunAlertPanel([[NSBundle mainBundle] localizedStringForKey:@"InvalidMargins"
															   value:@"Invalid Margins"
															   table:@"Localizable"],
                        [[NSBundle mainBundle] localizedStringForKey:@"FromTopBottomBad"
															   value:@"The Return Address top and bottom margins exceed the current paper height."
															   table:@"Localizable"],
                        [[NSBundle mainBundle] localizedStringForKey:@"Cancel"
															   value:@"Cancel"
															   table:@"Localizable"],
                        NULL,
                        NULL
                        );
		return NO;
    }
    else if ( ( [marginToLeftField intValue] + [marginToRightField intValue] )
              >= paperSize.width )
    {
        NSRunAlertPanel([[NSBundle mainBundle] localizedStringForKey:@"InvalidMargins"
															   value:@"Invalid Margins"
															   table:@"Localizable"],
                        [[NSBundle mainBundle] localizedStringForKey:@"ToLeftRightBad"
															   value:@"The Addressee left and right margins exceed the current paper width."
															   table:@"Localizable"],
                        [[NSBundle mainBundle] localizedStringForKey:@"Cancel"
															   value:@"Cancel"
															   table:@"Localizable"],
                        NULL,
                        NULL
                        );
		return NO;
    }
    else if ( ( [marginToTopField intValue] + [marginToBottomField intValue] )
              >= paperSize.height )
    {
        NSRunAlertPanel([[NSBundle mainBundle] localizedStringForKey:@"InvalidMargins"
															   value:@"Invalid Margins"
															   table:@"Localizable"],
                        [[NSBundle mainBundle] localizedStringForKey:@"ToTopBottomBad"
															   value:@"The Addressee top and bottom margins exceed the current paper height."
															   table:@"Localizable"],
                        [[NSBundle mainBundle] localizedStringForKey:@"Cancel"
															   value:@"Cancel"
															   table:@"Localizable"],
                        NULL,
                        NULL
                        );
		return NO;
    }
    else
    {
        [currentEnvelopeProfile setMarginFromLeft:[marginFromLeftField intValue]];
		[currentEnvelopeProfile setMarginFromRight:[marginFromRightField intValue]];
        [currentEnvelopeProfile setMarginFromTop:[marginFromTopField intValue]];
		[currentEnvelopeProfile setMarginFromBottom:[marginFromBottomField intValue]];
		[currentEnvelopeProfile setMarginToLeft:[marginToLeftField intValue]];
        [currentEnvelopeProfile setMarginToRight:[marginToRightField intValue]];
		[currentEnvelopeProfile setMarginToTop:[marginToTopField intValue]];
		[currentEnvelopeProfile setMarginToBottom:[marginToBottomField intValue]];
		
        [self alignViewsToMargins];
		
		return YES;
    }
}

- (void)showMargins
{
	[[fromView enclosingScrollView] setBorderType:NSBezelBorder];
	[[toView enclosingScrollView] setBorderType:NSBezelBorder];
}

- (void)hideMargins
{
	[[fromView enclosingScrollView] setBorderType:NSNoBorder];
	[[toView enclosingScrollView] setBorderType:NSNoBorder];
}

- (NSString *)toPrefix
{
	if ( [cePrefs objectForKey:@"to_prefix"] )
		return [cePrefs objectForKey:@"to_prefix"];
	else
		return @"";
}

- (NSString *)toSuffix
{
	if ( [cePrefs objectForKey:@"to_suffix"] )
		return [cePrefs objectForKey:@"to_suffix"];
	else
		return @"";
}

- (NSString *)fromPrefix
{
	if ( [cePrefs objectForKey:@"from_prefix"] )
		return [cePrefs objectForKey:@"from_prefix"];
	else
		return @"";
}

- (NSString *)fromSuffix
{
	if ( [cePrefs objectForKey:@"from_suffix"] )
		return [cePrefs objectForKey:@"from_suffix"];
	else
		return @"";
}

#pragma mark IBActions

- (IBAction)installAddressBookPlugin:(id)sender
{
	if ( ! [[NSFileManager defaultManager] copyPath:SOURCE_PLUGIN
											 toPath:GLOBAL_PLUGIN
											handler:nil] )
	{	
		NSLog(@"Failed to install Address Book plug-in for global use");
		
		if ( ! [[NSFileManager defaultManager] copyPath:SOURCE_PLUGIN
												 toPath:USER_PLUGIN
												handler:nil] )
		{	
			NSLog(@"Failed to install Address Book plug-in for current user");
			NSRunAlertPanel([[NSBundle mainBundle] localizedStringForKey:@"PluginInstallFailed"
																   value:@"Plug-In Install Failed"
																   table:@"Localizable"],
							[[NSBundle mainBundle] localizedStringForKey:@"PluginInstallFailedExp"
																   value:nil
																   table:@"Localizable"],
							[[NSBundle mainBundle] localizedStringForKey:@"Cancel"
																   value:@"Cancel"
																   table:@"Localizable"],
							nil,
							nil);
			
			return;
		}
	}
	
	[addressBookPluginMenuItem setTitle:
		[[NSBundle mainBundle] localizedStringForKey:@"RemovePlugin"
											   value:@"Remove Address Book Plug-In"
											   table:@"Localizable"]
		];
	[addressBookPluginMenuItem setAction:@selector(removeAddressBookPlugin:)];
	
	NSRunAlertPanel([[NSBundle mainBundle] localizedStringForKey:@"PluginInstalled"
														   value:@"Plug-In Installed"
														   table:@"Localizable"],
					[[NSBundle mainBundle] localizedStringForKey:@"PluginInstalledExp"
														   value:nil
														   table:@"Localizable"],
					[[NSBundle mainBundle] localizedStringForKey:@"OK"
														   value:@"OK"
														   table:@"Localizable"],
					nil,
					nil);
}

- (IBAction)removeAddressBookPlugin:(id)sender
{
	BOOL removed = NO;
	
	if ( ! [[NSFileManager defaultManager] fileExistsAtPath:USER_PLUGIN]
		 && ! [[NSFileManager defaultManager] fileExistsAtPath:GLOBAL_PLUGIN]
		 )
	{
		NSLog(@"Plug-in not installed.");
	}
	else
	{
		if ( [[NSFileManager defaultManager] removeFileAtPath:USER_PLUGIN handler:NULL] )
		{
			removed = YES;
		}
		if ( [[NSFileManager defaultManager] removeFileAtPath:GLOBAL_PLUGIN handler:NULL] )
		{
			removed = YES;
		}
		if ( removed )
		{
			NSRunAlertPanel([[NSBundle mainBundle] localizedStringForKey:@"PluginRemoved"
																   value:@"Plug-In Removed"
																   table:@"Localizable"],
							[[NSBundle mainBundle] localizedStringForKey:@"PluginRemovedExp"
																   value:nil
																   table:@"Localizable"],
							[[NSBundle mainBundle] localizedStringForKey:@"OK"
																   value:@"OK"
																   table:@"Localizable"],
							nil,
							nil);
		}
		else
		{
			NSLog(@"Failed to remove Address Book plug-in");
			return;
		}
	}
	
	[addressBookPluginMenuItem setTitle:
		[[NSBundle mainBundle] localizedStringForKey:@"InstallPlugin"
											   value:@"Install Address Book Plug-In"
											   table:@"Localizable"]
		];
	[addressBookPluginMenuItem setAction:@selector(installAddressBookPlugin:)];
}

- (IBAction)invokeTextAttributesWindow:(id)sender
{
	NSPoint origin;
	NSSize size;
	
	[[toAttributesView textStorage] endEditing];
	[[fromAttributesView textStorage] endEditing];

	[toAttributesView setAttributedString:[self toAttributes]];
	[fromAttributesView setAttributedString:[self fromAttributes]];
	
	[textAttributesWindow center];
	size = [textAttributesWindow frame].size;
	origin = [textAttributesWindow frame].origin;
	
	[[NSFontManager sharedFontManager] orderFrontFontPanel:self];
	[[NSFontPanel sharedFontPanel] setFrame:
		NSMakeRect(origin.x,
				   origin.y - [[NSFontPanel sharedFontPanel] frame].size.height,
				   size.width,
				   [[NSFontPanel sharedFontPanel] frame].size.height)
									display:YES
		];

	[[NSApplication sharedApplication] runModalForWindow:textAttributesWindow];
}

- (IBAction)textAttributesOkay:(id)sender
{
	[self setToAttributes:[toAttributesView attributedString]];
	[self setFromAttributes:[fromAttributesView attributedString]];
	
	[self selectToAddressUpdatingFromAddress];
	
	[[NSApplication sharedApplication] stopModal];
    [textAttributesWindow orderOut:sender];
    [[NSFontPanel sharedFontPanel] orderOut:sender];
}

- (IBAction)textAttributesCancel:(id)sender
{
	[[NSApplication sharedApplication] stopModal];
    [textAttributesWindow orderOut:sender];
    [[NSFontPanel sharedFontPanel] orderOut:sender];
}

- (IBAction)envelopeProfilesOkay:(id)sender
{
    [[NSApplication sharedApplication] stopModal];
}

- (IBAction)envelopeProfilesCancel:(id)sender
{
    [[NSApplication sharedApplication] abortModal];
}

- (IBAction)envelopeProfilesNew:(id)sender
{
    [[NSApplication sharedApplication] stopModalWithCode:1];
}

- (IBAction)envelopeProfilesDelete:(id)sender
{
    [[NSApplication sharedApplication] stopModalWithCode:-1];
}

- (IBAction)invokeMarginsWindow:(id)sender
{
    if ( [marginGuidelinesMenuItem state] == NSOffState )
    {
		[self showMargins];
    }
	
    [marginFromLeftField setIntValue:[currentEnvelopeProfile marginFromLeft]];
    [marginFromRightField setIntValue:[currentEnvelopeProfile marginFromRight]];
    [marginFromTopField setIntValue:[currentEnvelopeProfile marginFromTop]];
    [marginFromBottomField setIntValue:[currentEnvelopeProfile marginFromBottom]];
    [marginToLeftField setIntValue:[currentEnvelopeProfile marginToLeft]];
    [marginToRightField setIntValue:[currentEnvelopeProfile marginToRight]];
    [marginToTopField setIntValue:[currentEnvelopeProfile marginToTop]];
    [marginToBottomField setIntValue:[currentEnvelopeProfile marginToBottom]];
	
    [marginApplyButton setEnabled:NO];
    [marginDefaultButton setEnabled:YES];
    [marginCancelButton setEnabled:YES];
	
    [marginsWindow center];
    [[NSApplication sharedApplication] runModalForWindow:marginsWindow];
}

- (IBAction)marginsOkay:(id)sender
{
    if ( [self applyMarginsChange] )
    {
        [[NSApplication sharedApplication] stopModal];
        [marginsWindow orderOut:sender];
		
		if ( [marginGuidelinesMenuItem state] == NSOffState )
		{
			[self hideMargins];
		}
    }
}

- (IBAction)marginsApply:(id)sender
{
    [self applyMarginsChange];
	
    [marginApplyButton setEnabled:NO];
    [marginDefaultButton setEnabled:YES];
    [marginCancelButton setEnabled:NO];
}

- (IBAction)marginsCancel:(id)sender
{
    [[NSApplication sharedApplication] stopModal];
    [marginsWindow orderOut:sender];
	
    if ( [marginGuidelinesMenuItem state] == NSOffState )
    {
		[self hideMargins];
    }
}

- (IBAction)marginsDefault:(id)sender
{
    EnvelopeProfile *defaultProfile = [[[EnvelopeProfile alloc] init] autorelease];
	
    [marginsWindow endEditingFor:nil];
	
    [marginFromLeftField setIntValue:[defaultProfile marginFromLeft]];
    [marginFromRightField setIntValue:[defaultProfile marginFromRight]];
    [marginFromTopField setIntValue:[defaultProfile marginFromTop]];
    [marginFromBottomField setIntValue:[defaultProfile marginFromBottom]];
    [marginToLeftField setIntValue:[defaultProfile marginToLeft]];
    [marginToRightField setIntValue:[defaultProfile marginToRight]];
    [marginToTopField setIntValue:[defaultProfile marginToTop]];
    [marginToBottomField setIntValue:[defaultProfile marginToBottom]];
	
    [marginApplyButton setEnabled:YES];
    [marginDefaultButton setEnabled:NO];
    [marginCancelButton setEnabled:YES];
}

- (IBAction)invokePrefsWindow:(id)sender
{
    if ( [cePrefs objectForKey:@"from_swap_names"] )
		[fromSwapNamesSwitch setState:[[cePrefs objectForKey:@"from_swap_names"] intValue]];
    else
		[fromSwapNamesSwitch setState:NSOffState];
	if ( [cePrefs objectForKey:@"to_swap_names"] )
		[toSwapNamesSwitch setState:[[cePrefs objectForKey:@"to_swap_names"] intValue]];
    else
		[toSwapNamesSwitch setState:NSOffState];
	if ( [cePrefs objectForKey:@"hide_to_prefix"] )
			[hideToPrefixSwitch setState:[[cePrefs objectForKey:@"hide_to_prefix"] intValue]];
    else
		[hideToPrefixSwitch setState:NSOffState];
    if ( [cePrefs objectForKey:@"hide_to_suffix"] )
		[hideToSuffixSwitch setState:[[cePrefs objectForKey:@"hide_to_suffix"] intValue]];
    else
		[hideToSuffixSwitch setState:NSOffState];
    if ( [cePrefs objectForKey:@"hide_from_prefix"] )
		[hideFromPrefixSwitch setState:[[cePrefs objectForKey:@"hide_from_prefix"] intValue]];
    else
		[hideFromPrefixSwitch setState:NSOffState];
    if ( [cePrefs objectForKey:@"hide_from_suffix"] )
		[hideFromSuffixSwitch setState:[[cePrefs objectForKey:@"hide_from_suffix"] intValue]];
    else
		[hideFromSuffixSwitch setState:NSOffState];
    
	if ( [cePrefs objectForKey:@"hide_to_country"] )
		[hideToCountrySwitch setState:[[cePrefs objectForKey:@"hide_to_country"] intValue]];
    else
		[hideToCountrySwitch setState:NSOffState];
    if ( [cePrefs objectForKey:@"hide_to_same_country"] )
		[hideToSameCountrySwitch setState:[[cePrefs objectForKey:@"hide_to_same_country"] intValue]];
    else
		[hideToSameCountrySwitch setState:NSOffState];
	
	if ( [cePrefs objectForKey:@"hide_from_country"] )
		[hideFromCountrySwitch setState:[[cePrefs objectForKey:@"hide_from_country"] intValue]];
    else
		[hideFromCountrySwitch setState:NSOffState];
    if ( [cePrefs objectForKey:@"hide_from_same_country"] )
		[hideFromSameCountrySwitch setState:[[cePrefs objectForKey:@"hide_from_same_country"] intValue]];
    else
		[hideFromSameCountrySwitch setState:NSOffState];
	
	if ( [hideFromCountrySwitch state] == NSOnState )
		[hideFromSameCountrySwitch setEnabled:YES];
	else
		[hideFromSameCountrySwitch setEnabled:NO];
	
	[hideFromTitleSwitch setState:[[cePrefs objectForKey:@"hide_from_title"] intValue]];
    [hideFromNameSwitch setState:[[cePrefs objectForKey:@"hide_from_name"] intValue]];
    [hideFromJobSwitch setState:[[cePrefs objectForKey:@"hide_from_job_title"] intValue]];
    [hideFromCompanySwitch setState:[[cePrefs objectForKey:@"hide_from_company"] intValue]];
	
    [hideToTitleSwitch setState:[[cePrefs objectForKey:@"hide_to_title"] intValue]];
    [hideToNameSwitch setState:[[cePrefs objectForKey:@"hide_to_name"] intValue]];
    [hideToJobSwitch setState:[[cePrefs objectForKey:@"hide_to_job_title"] intValue]];
    [hideToCompanySwitch setState:[[cePrefs objectForKey:@"hide_to_company"] intValue]];
	
	[fromPrefixField setStringValue:[self fromPrefix]];
	[fromSuffixField setStringValue:[self fromSuffix]];
	[toPrefixField setStringValue:[self toPrefix]];
	[toSuffixField setStringValue:[self toSuffix]];
    
    if ( [cePrefs objectForKey:@"fromGroup"] == NULL
         ||
         [fromGroupPopup indexOfItemWithTitle:[cePrefs objectForKey:@"fromGroup"]] == -1 )
    {
        [fromGroupPopup selectItemAtIndex:0];
    }
    else
    {
        [fromGroupPopup selectItemWithTitle:[cePrefs objectForKey:@"fromGroup"]];
    }
    
    if ( [cePrefs objectForKey:@"barcodeType"] == NULL )
    {
        [barcodePopup selectItemAtIndex:0];
    }
    else
    {
        [barcodePopup selectItemWithTitle:
            [cePrefs objectForKey:@"barcodeType"]
            ];
    }
	
	[barcodePositionSwitch setState:[[cePrefs valueForKey:@"barcode_position"] intValue]];
	
	if ( [cePrefs objectForKey:@"local_country_names"] )
		[localCountryNamesView setString:[[cePrefs objectForKey:@"local_country_names"] componentsJoinedByString:@"\n"]];
	else
		[localCountryNamesView setString:@""];
	
	if ( [cePrefs valueForKey:@"labelToRestrictBy"] )
		[restrictLabelField setStringValue:[cePrefs valueForKey:@"labelToRestrictBy"]];
	else
		[restrictLabelField setStringValue:@""];
	
	if ( [[cePrefs valueForKey:@"overrideRestrictForNoMatch"] boolValue] )
		[overrideRestrictForNoMatchSwitch setState:NSOnState];
	else
		[overrideRestrictForNoMatchSwitch setState:NSOffState];

    [prefsWindow center];
    [[NSApplication sharedApplication] runModalForWindow:prefsWindow];
}

- (IBAction)prefsOkay:(id)sender
{
    if ( [barcodePopup indexOfSelectedItem] == 1 )
    {
        NSRunAlertPanel(@"Australia Post Barcode",
                        @"Snail Mail does not support Australia Post's barcodes, despite being developed in Australia, for Australians, because Australia Post charges tens of thousands of dollars for access to the necessary data, putting it beyond the reach of economical software such as this.",
                        @"Phooey!",
                        NULL,
                        NULL
                        );
        return;
    }
	
    [cePrefs setObject:[NSNumber numberWithInt:[toSwapNamesSwitch state]] forKey:@"to_swap_names"];
    [cePrefs setObject:[NSNumber numberWithInt:[fromSwapNamesSwitch state]] forKey:@"from_swap_names"];
	
    [cePrefs setObject:[NSNumber numberWithInt:[hideToPrefixSwitch state]] forKey:@"hide_to_prefix"];
    [cePrefs setObject:[NSNumber numberWithInt:[hideToSuffixSwitch state]] forKey:@"hide_to_suffix"];
    [cePrefs setObject:[NSNumber numberWithInt:[hideFromPrefixSwitch state]] forKey:@"hide_from_prefix"];
    [cePrefs setObject:[NSNumber numberWithInt:[hideFromSuffixSwitch state]] forKey:@"hide_from_suffix"];
	
	[cePrefs setObject:[NSNumber numberWithInt:[hideFromCountrySwitch state]] forKey:@"hide_from_country"];
	[cePrefs setObject:[NSNumber numberWithInt:[hideFromSameCountrySwitch state]] forKey:@"hide_from_same_country"];
    [cePrefs setObject:[NSNumber numberWithInt:[hideToCountrySwitch state]] forKey:@"hide_to_country"];
	[cePrefs setObject:[NSNumber numberWithInt:[hideToSameCountrySwitch state]] forKey:@"hide_to_same_country"];
	
    [cePrefs setObject:[NSNumber numberWithInt:[hideFromTitleSwitch state]] forKey:@"hide_from_title"];
    [cePrefs setObject:[NSNumber numberWithInt:[hideFromNameSwitch state]] forKey:@"hide_from_name"];
    [cePrefs setObject:[NSNumber numberWithInt:[hideFromJobSwitch state]] forKey:@"hide_from_job_title"];
    [cePrefs setObject:[NSNumber numberWithInt:[hideFromCompanySwitch state]] forKey:@"hide_from_company"];
	
    [cePrefs setObject:[NSNumber numberWithInt:[hideToTitleSwitch state]] forKey:@"hide_to_title"];
    [cePrefs setObject:[NSNumber numberWithInt:[hideToNameSwitch state]] forKey:@"hide_to_name"];
    [cePrefs setObject:[NSNumber numberWithInt:[hideToJobSwitch state]] forKey:@"hide_to_job_title"];
    [cePrefs setObject:[NSNumber numberWithInt:[hideToCompanySwitch state]] forKey:@"hide_to_company"];
	
    [cePrefs setObject:[fromPrefixField stringValue] forKey:@"from_prefix"];
    [cePrefs setObject:[fromSuffixField stringValue] forKey:@"from_suffix"];
    [cePrefs setObject:[toPrefixField stringValue] forKey:@"to_prefix"];
    [cePrefs setObject:[toSuffixField stringValue] forKey:@"to_suffix"];
	
    [cePrefs setObject:[fromGroupPopup titleOfSelectedItem] forKey:@"fromGroup"];
    [cePrefs setObject:[NSNumber numberWithInt:[fromGroupPopup indexOfSelectedItem]] forKey:@"fromGroupIndex"];
    [cePrefs setObject:[barcodePopup titleOfSelectedItem] forKey:@"barcodeType"];
	
	[cePrefs setValue:[NSNumber numberWithInt:[barcodePositionSwitch state]] forKey:@"barcode_position"];
	
	[cePrefs setObject:[[[localCountryNamesView string] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] componentsSeparatedByString:@"\n"]
			  forKey:@"local_country_names"];
	
	[cePrefs setObject:[restrictLabelField stringValue] forKey:@"labelToRestrictBy"];
	
	if ( [overrideRestrictForNoMatchSwitch state] == NSOnState )
		[cePrefs setObject:[NSNumber numberWithBool:YES] forKey:@"overrideRestrictForNoMatch"];
	else
		[cePrefs setObject:[NSNumber numberWithBool:NO] forKey:@"overrideRestrictForNoMatch"];
	
	[currentEnvelopeProfile setPrefs:cePrefs];
	[[NSUserDefaults standardUserDefaults] setObject:[NSArchiver archivedDataWithRootObject:envelopeProfiles] forKey:@"envelope_profiles"];
    [[NSUserDefaults standardUserDefaults] setObject:[[envelopeProfiles allKeysForObject:currentEnvelopeProfile] objectAtIndex:0] forKey:@"current_envelope_profile_name"];
	
    [self selectToAddressUpdatingFromAddress];
	
    [self refreshFromAddresses];
	
    [[NSApplication sharedApplication] stopModal];
    [prefsWindow orderOut:sender];
}

- (IBAction)prefsCancel:(id)sender
{
    [[NSApplication sharedApplication] stopModal];
    [prefsWindow orderOut:sender];
}

- (IBAction)hideToCountryClicked:(id)sender
{
	if ( [hideToCountrySwitch state] == NSOffState )
	{
		[hideToSameCountrySwitch setState:NSOffState];
		[hideToSameCountrySwitch setEnabled:NO];
	}
	else
	{
		[hideToSameCountrySwitch setEnabled:YES];
	}
}

- (IBAction)hideFromCountryClicked:(id)sender
{
	if ( [hideFromCountrySwitch state] == NSOffState )
	{
		[hideFromSameCountrySwitch setState:NSOffState];
		[hideFromSameCountrySwitch setEnabled:NO];
	}
	else
	{
		[hideFromSameCountrySwitch setEnabled:YES];
	}
}

- (IBAction)toggleMarginGuidelines:(id)sender
{
    if ( [marginGuidelinesMenuItem state] == NSOffState )
    {
		[self showMargins];
		[marginGuidelinesMenuItem setState:NSOnState];
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"hide_margin_guides"];
    }
    else if ( [marginGuidelinesMenuItem state] == NSOnState )
    {
        [self hideMargins];
		[marginGuidelinesMenuItem setState:NSOffState];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"hide_margin_guides"];
    }
	
    [envelopeWindow display];
}

- (IBAction)invokeAddressBook:(id)sender
{
    NSDictionary *error = [NSDictionary dictionary];
    NSAppleScript *script = [[NSAppleScript alloc] initWithSource:@"tell application \"Address Book\" to reopen"];
	
    // This is necessary in addition to line below when Address Book
    // is already open but its window is closed or minimised
    [script executeAndReturnError:&error];
	
    // Could use AppleScript "activate" command, but this should be better
    [[NSWorkspace sharedWorkspace] openURL:
		[NSURL URLWithString:@"addressbook://"]];
}

- (IBAction)runPageLayout:(id)sender
{
    [NSPrintInfo setSharedPrintInfo:[[self currentEnvelopeProfile] printInfo]];
    [[NSApplication sharedApplication] runPageLayout:sender];
    [currentEnvelopeProfile setPrintInfo:[NSPrintInfo sharedPrintInfo]];
	
    [self setEnvelopeWindowFrame];
}

- (IBAction)printEnvelope:(id)sender
{
	int i;
	NSMutableArray *visibleRulers = [NSMutableArray array];
	NSPrintInfo *printInfo = [NSPrintInfo sharedPrintInfo];
	
	if ( [currentEnvelopeProfile printInfo] )
		printInfo = [currentEnvelopeProfile printInfo];
	
	if ( [toView isRulerVisible] )
	{
		[visibleRulers addObject:toView];
		[toView setRulerVisible:NO];
	}
	if ( [fromView isRulerVisible] )
	{
		[visibleRulers addObject:fromView];
		[fromView setRulerVisible:NO];
	}
	if ( [backgroundView isRulerVisible] )
	{
		[visibleRulers addObject:backgroundView];
		[backgroundView setRulerVisible:NO];
	}
	
    if ( ! [[NSUserDefaults standardUserDefaults] boolForKey:@"hide_margin_guides"] )
		[self hideMargins];
	
	NSPrintOperation *printOp = [NSPrintOperation printOperationWithView:printableView printInfo:printInfo];
	[printOp runOperation];
	[currentEnvelopeProfile setPrintInfo:[printOp printInfo]];
	
	if ( ! [[NSUserDefaults standardUserDefaults] boolForKey:@"hide_margin_guides"] )
		[self showMargins];
	
	for ( i = 0; i < [visibleRulers count]; i++ )
	{
		[[visibleRulers objectAtIndex:i] setRulerVisible:YES];
	}
}

- (IBAction)printImmediately:(id)sender
{
    int i;
	NSMutableArray *visibleRulers = [NSMutableArray array];
	NSPrintInfo *printInfo = [NSPrintInfo sharedPrintInfo];
	
	if ( [currentEnvelopeProfile printInfo] )
		printInfo = [currentEnvelopeProfile printInfo];
	
	if ( [toView isRulerVisible] )
	{
		[visibleRulers addObject:toView];
		[toView setRulerVisible:NO];
	}
	if ( [fromView isRulerVisible] )
	{
		[visibleRulers addObject:fromView];
		[fromView setRulerVisible:NO];
	}
	if ( [backgroundView isRulerVisible] )
	{
		[visibleRulers addObject:backgroundView];
		[backgroundView setRulerVisible:NO];
	}
	
	if ( ! [[NSUserDefaults standardUserDefaults] boolForKey:@"hide_margin_guides"] )
		[self hideMargins];

    NSPrintOperation *printOp = [NSPrintOperation printOperationWithView:printableView printInfo:printInfo];
	[printOp setShowPanels:NO];
    [printOp runOperation];
	
	if ( ! [[NSUserDefaults standardUserDefaults] boolForKey:@"hide_margin_guides"] )
		[self showMargins];
	
	for ( i = 0; i < [visibleRulers count]; i++ )
	{
		[[visibleRulers objectAtIndex:i] setRulerVisible:YES];
	}
}

- (IBAction)printSelected:(id)sender
{
	ABPerson *thePerson;
	ABMultiValue *personAddressList;
	NSArray *selectedIdentifiers;
	int i, j;
	BOOL foundMatchingLabel;
	NSMutableArray *selectedAddrs = [[[NSMutableArray alloc] init] autorelease];
	NSString *restrictByLabelCaps = [[cePrefs valueForKey:@"labelToRestrictBy"] capitalizedString];
	BOOL overrideRestrictForNoMatch = [[cePrefs valueForKey:@"overrideRestrictForNoMatch"] boolValue];

	for ( i = 0; i < [[peoplePicker selectedRecords] count]; i++ )
	{
		thePerson = [[peoplePicker selectedRecords] objectAtIndex:i];
		personAddressList = [thePerson valueForProperty:kABAddressProperty];
		
		if ( [restrictByLabelCaps length] )
		{
			foundMatchingLabel = NO;
			
			for ( j = 0; j < [personAddressList count]; j++ )
			{
				if ( [[ABLocalizedPropertyOrLabel([personAddressList labelAtIndex:j]) capitalizedString] isEqualToString:restrictByLabelCaps] )
				{
					[self setToAddress:[personAddressList valueAtIndex:j] forPerson:thePerson];
					[selectedAddrs addObject:[self addressDict:toAddress afterToFromPrefs:@"TO"]];
					
					foundMatchingLabel = YES;
				}
			}
			
			if ( ! foundMatchingLabel && overrideRestrictForNoMatch && [personAddressList count] > 0 )
			{
				[self setToAddress:[personAddressList valueAtIndex:0] forPerson:thePerson];
				[selectedAddrs addObject:[self addressDict:toAddress afterToFromPrefs:@"TO"]];
			}
		}
		else
		{
			selectedIdentifiers = [peoplePicker selectedIdentifiersForPerson:thePerson];

			for ( j = 0; j < [selectedIdentifiers count]; j++ )
			{
				[self setToAddress:
					[personAddressList valueAtIndex:[personAddressList indexForIdentifier:[selectedIdentifiers objectAtIndex:j]]]
						 forPerson:thePerson];
				
				[selectedAddrs addObject:[self addressDict:toAddress afterToFromPrefs:@"TO"]];
			}
		}
	}
	
	[self printEnvelopesToPersonalisedAddresses:selectedAddrs];
}

#pragma mark Services and Copy/Paste

- (void)printWithText:(NSPasteboard *)pboard userData:(NSString *)userData error:(NSString **)error
{
    NSString *addressString;
    NSArray *types = [pboard types];
	
    if (![types containsObject:NSStringPboardType])
    {
		*error = NSLocalizedString(@"Error:  No string passed.",
								   @"pboard didn't have string");
		return;
    }
    addressString = [pboard stringForType:NSStringPboardType];
    if (!addressString)
    {
		*error = NSLocalizedString(@"Error:  No string passed.",
								   @"pboard didn't have string");
		return;
    }
	
    [peoplePicker deselectAll:self];
    [[self barcodeView] removeFromSuperview];
    [self setBarcode:nil];
	
    [toView setString:addressString];
    [toView display];
	
    [envelopeWindow makeKeyAndOrderFront:self];
	
    [self printImmediately:self];
    
    return;
}

- (void)textFromEnvelope:(NSPasteboard *)pboard userData:(NSString *)userData error:(NSString **)error
{
    NSArray *types = [NSArray arrayWithObject:NSStringPboardType];
	
    if ( [[toView string] isEqualToString:@""] )
    {
		*error = NSLocalizedString(@"Error:  No addressee address on envelope.",
								   @"envelope not addressed");
		return;
    }
	
    [pboard declareTypes:types owner:nil];
    [pboard setString:[toView string] forType:NSStringPboardType];
	
    return;
}

- (void)textToEnvelope:(NSPasteboard *)pboard userData:(NSString *)userData error:(NSString **)error
{
    NSString *addressString;
    NSArray *types = [pboard types];
	
    if (![types containsObject:NSStringPboardType])
    {
		*error = NSLocalizedString(@"Error:  No string passed.",
								   @"pboard didn't have string");
		return;
    }
    addressString = [pboard stringForType:NSStringPboardType];
    if (!addressString)
    {
		*error = NSLocalizedString(@"Error:  No string passed.",
								   @"pboard didn't have string");
		return;
    }
	
    [peoplePicker deselectAll:self];
    [[self barcodeView] removeFromSuperview];
    [self setBarcode:nil];
	
    [toView setString:addressString];
	
    [envelopeWindow makeKeyAndOrderFront:self];
	
    return;
}

- (void)copyFromAddressee:(id)sender
{
    NSPasteboard *pboard = [NSPasteboard pasteboardWithName:NSGeneralPboard];
	
    [pboard declareTypes:[NSArray arrayWithObject:NSStringPboardType]
				   owner:nil];
    [pboard setString:[toView string] forType:NSStringPboardType];
}

- (void)pasteToAddressee:(id)sender
{
    NSPasteboard *pboard = [NSPasteboard pasteboardWithName:NSGeneralPboard];
    NSString *addressString;
	
    if ( [[pboard types] containsObject:NSStringPboardType] )
    {
		addressString = [pboard stringForType:NSStringPboardType];
		if ( addressString )
		{
			[peoplePicker deselectAll:self];
			[[self barcodeView] removeFromSuperview];
			[self setBarcode:nil];
			
			[toView setString:addressString];
		}
    }
}

#pragma mark Toolbar

- (void)toolbarWillAddItem:(NSNotification *)notification
{
    NSToolbarItem *itemToAdd = [[notification userInfo] objectForKey:@"item"];
    
    if ( [[itemToAdd itemIdentifier] isEqualToString:NSToolbarPrintItemIdentifier] )
    {
        [itemToAdd setTarget:self];
        [itemToAdd setAction:@selector(printImmediately:)];
    }
}

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
{
    NSToolbarItem *item = [[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
	
    if ( [itemIdentifier isEqualToString:@"AddressBookItem"] )
    {
        [item setLabel:[[NSBundle mainBundle] localizedStringForKey:@"AddressBook"  value:nil table:nil]];
        [item setPaletteLabel:[item label]];
        [item setImage:[NSImage imageNamed:@"AddressBook"]];
        [item setTarget:self];
        [item setAction:@selector(invokeAddressBook:)];
    }
    else if ( [itemIdentifier isEqualToString:@"CopyItem"] )
    {
        [item setLabel:[[NSBundle mainBundle] localizedStringForKey:@"CopyAddress" value:nil table:nil]];
        [item setPaletteLabel:[item label]];
        [item setImage:[NSImage imageNamed:@"copy"]];
        [item setTarget:self];
        [item setAction:@selector(copyFromAddressee:)];
    }
    else if ( [itemIdentifier isEqualToString:@"PasteItem"] )
    {
        [item setLabel:[[NSBundle mainBundle] localizedStringForKey:@"PasteAddress" value:nil table:nil]];
        [item setPaletteLabel:[item label]];
        [item setImage:[NSImage imageNamed:@"paste"]];
        [item setTarget:self];
        [item setAction:@selector(pasteToAddressee:)];
    }
    else if ( [itemIdentifier isEqualToString:@"TextItem"] )
    {
        [item setLabel:[[NSBundle mainBundle] localizedStringForKey:@"TextAttributes" value:nil table:nil]];
        [item setPaletteLabel:[item label]];
        [item setImage:[NSImage imageNamed:@"text"]];
        [item setTarget:self];
        [item setAction:@selector(invokeTextAttributesWindow:)];
    }
	
    return [item autorelease];
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar
{
	return [self toolbarAllowedItemIdentifiers:toolbar];
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar
{
    NSMutableArray *toolbarIdentifiers = [NSMutableArray arrayWithObjects:
        NSToolbarPrintItemIdentifier,
        @"AddressBookItem",
        @"CopyItem",
        @"PasteItem",
		@"TextItem",
        nil];
	
    return toolbarIdentifiers;
}

#pragma mark Table Data Source

- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
    if ( aTableView == envelopeProfilesTable )
    {
		return [profileNames count];
    }
	
	return nil;
}

- (id)tableView:(NSTableView *)aTableView
objectValueForTableColumn:(NSTableColumn *)aColumn row:(int)aRowIndex
{
    if ( aColumn == [[envelopeProfilesTable tableColumns] objectAtIndex:0] )
    {
		return [profileNames objectAtIndex:aRowIndex];
    }
    
	return nil;
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
    if ( aTableView == envelopeProfilesTable )
    {
		[self changeNewProfilesItem:rowIndex toName:anObject];
    }
}

#pragma mark Delegations and Notifications

- (void)textDidChange:(NSNotification *)theNotification
{
	if ( [theNotification object] == backgroundView )
	{
		[cePrefs setObject:[backgroundView attributedString] forKey:@"background_content"];

		return;
	}
	
	if ( [theNotification object] == toView )
    {
		[peoplePicker deselectAll:self];
		
		if ( toAddress )
			[self setToAddress:nil forPerson:nil];
		
		[[self barcodeView] removeFromSuperview];
		[self setBarcodeView:nil];
		[self setBarcode:nil];
		
		if ( [barcodePopup indexOfSelectedItem] > 1 )
		{
			[self setBarcode:[PostalBarcodeGenerator barcodeOfType:[barcodePopup indexOfSelectedItem] forAddrString:[toView string]]];
			
			if ( [self barcode] == nil )
			{
				[self setBarcodeView:nil];
			}
			else
			{
				[self setBarcodeView:[[NKDBarcodeOffscreenView alloc] initWithBarcode:[self barcode]]];
				[printableView addSubview:barcodeView];
				[self positionBarcodeViewForType:[barcodePopup indexOfSelectedItem]];
			}
		}
		
		[printableView display];
		
		return;
    }
}

- (void)controlTextDidChange:(NSNotification *)theNotification
{
    NSString *str;
	
    if ( [theNotification object] == envelopeProfilesTable )
    {
		str = [[[theNotification userInfo] objectForKey:@"NSFieldEditor"] string];
		if ( [str isEqualToString:@""] || [self profileNameExists:str] )
		{
			[envelopeProfilesOKButton setEnabled:NO];
			[envelopeProfilesNewButton setEnabled:NO];
		}
		else
		{
			[envelopeProfilesOKButton setEnabled:YES];
			[envelopeProfilesNewButton setEnabled:YES];
		}
    }
    else if ( [theNotification object] == marginFromLeftField
			  || [theNotification object] == marginFromRightField
			  || [theNotification object] == marginFromTopField
			  || [theNotification object] == marginFromBottomField
			  || [theNotification object] == marginToLeftField
			  || [theNotification object] == marginToRightField
			  || [theNotification object] == marginToTopField
			  || [theNotification object] == marginToBottomField )
    {
        [marginApplyButton setEnabled:YES];
        [marginDefaultButton setEnabled:YES];
		[marginCancelButton setEnabled:YES];
    }
}

- (BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor
{
    NSString *str;
	
    if ( control == envelopeProfilesTable )
    {
		str = [fieldEditor string];
		if ( [str isEqualToString:@""] || [self profileNameExists:str] )
		{
			return NO;
		}
		else
		{
			return YES;
		}
    }
    else
    {
		return YES;
    }
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [[NSApplication sharedApplication]  setServicesProvider:self];
	
	//  NB:  ABPeoplePickerView initial record selection is here instead of awakeFromNib, as the view doesn't appear to be initialised enough at nib awaking time
	
	if ( [[NSUserDefaults standardUserDefaults] objectForKey:@"selected_to_record"] )
    {
		[peoplePicker selectRecord:[addressDB recordForUniqueId:[[NSUserDefaults standardUserDefaults] objectForKey:@"selected_to_record"]] byExtendingSelection:NO];
    }
	
	//  PeoplePicker split view sizes restoring (USES PRIVATE API!!!)
	if ( [[NSUserDefaults standardUserDefaults] valueForKey:@"groupsPaneWidth"]
		 && [[NSUserDefaults standardUserDefaults] valueForKey:@"peoplePaneWidth"]
		 && [peoplePicker respondsToSelector:@selector(_uiController)]
		 && [[peoplePicker performSelector:@selector(_uiController)] respondsToSelector:@selector(groupsPane)]
		 && [[peoplePicker performSelector:@selector(_uiController)] respondsToSelector:@selector(peoplePane)]
		 )
	{
		NSRect groupsFrame = [[[peoplePicker performSelector:@selector(_uiController)] performSelector:@selector(groupsPane)] frame];
		NSRect peopleFrame = [[[peoplePicker performSelector:@selector(_uiController)] performSelector:@selector(peoplePane)] frame];
		groupsFrame.size.width = [[[NSUserDefaults standardUserDefaults] valueForKey:@"groupsPaneWidth"] floatValue];
		peopleFrame.size.width = [[[NSUserDefaults standardUserDefaults] valueForKey:@"peoplePaneWidth"] floatValue];
		[[[peoplePicker performSelector:@selector(_uiController)] performSelector:@selector(groupsPane)] setFrame:groupsFrame];
		[[[peoplePicker performSelector:@selector(_uiController)] performSelector:@selector(peoplePane)] setFrame:peopleFrame];
		[(NSSplitView *)[[[peoplePicker performSelector:@selector(_uiController)] performSelector:@selector(groupsPane)] superview] adjustSubviews];
	}
	
	[controlWindow makeKeyAndOrderFront:self];
	
	//  Make peoplePicker's search field the keyboard focus (USES PRIVATE API!!!)
	if ( [peoplePicker respondsToSelector:@selector(_searchField)] )
		[controlWindow makeFirstResponder:[peoplePicker performSelector:@selector(_searchField)]];
}

- (void)applicationWillBecomeActive:(NSNotification *)aNotification
{
    [self refreshFromAddresses];
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
    NSRect envFrame = [envelopeWindow frame];
	
    [envelopeWindow orderOut:self];
	
    // NB:  Top left point specified in prefs because auto saving window
    // doesn't work correctly
    [[NSUserDefaults standardUserDefaults] setInteger:
        (envFrame.origin.y + envFrame.size.height )
               forKey:@"envelope_top"];
    [[NSUserDefaults standardUserDefaults] setInteger:envFrame.origin.x
               forKey:@"envelope_left"];
    
    [cePrefs setValue:[NSNumber numberWithInt:[fromPopup indexOfSelectedItem]] forKey:@"from_address_menu_index"];
	
    if ( toAddress && [[peoplePicker selectedRecords] count] > 0 )
	{
		[[NSUserDefaults standardUserDefaults] setObject:[[[peoplePicker selectedRecords] objectAtIndex:0] uniqueId] forKey:@"selected_to_record"];
		[[NSUserDefaults standardUserDefaults] setObject:toAddress forKey:@"to_address"];
	}
	else
	{	
		[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"selected_to_record"];
		[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"to_address"];		
	}
	
    [cePrefs setObject:[NSArchiver archivedDataWithRootObject:[fromView attributedString]] forKey:@"from_address_content"];
    [cePrefs setObject:[NSArchiver archivedDataWithRootObject:[toView attributedString]] forKey:@"to_address_content"];
	
    if ( [self barcode] == nil )
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"barcode"];
    else
        [[NSUserDefaults standardUserDefaults] setObject:[NSArchiver archivedDataWithRootObject:[self barcode]] forKey:@"barcode"];
	
    [cePrefs setValue:[NSNumber numberWithInt:[fromTypePopup indexOfSelectedItem]] forKey:@"from_type"];
	
	[currentEnvelopeProfile setPrefs:cePrefs];
	[[NSUserDefaults standardUserDefaults] setObject:[NSArchiver archivedDataWithRootObject:envelopeProfiles] forKey:@"envelope_profiles"];
    [[NSUserDefaults standardUserDefaults] setObject:[[envelopeProfiles allKeysForObject:currentEnvelopeProfile] objectAtIndex:0] forKey:@"current_envelope_profile_name"];
	
	//  Width of people picker split view panes (USES PRIVATE API!!!)
	if ( [peoplePicker respondsToSelector:@selector(_uiController)]
		&& [[peoplePicker performSelector:@selector(_uiController)] respondsToSelector:@selector(groupsPane)]
		&& [[peoplePicker performSelector:@selector(_uiController)] respondsToSelector:@selector(peoplePane)]
		)
	{
		NSNumber *groupsWidth = [NSNumber numberWithFloat:[[[peoplePicker performSelector:@selector(_uiController)] performSelector:@selector(groupsPane)] frame].size.width];
		NSNumber *peopleWidth = [NSNumber numberWithFloat:[[[peoplePicker performSelector:@selector(_uiController)] performSelector:@selector(peoplePane)] frame].size.width];
		[[NSUserDefaults standardUserDefaults] setValue:groupsWidth forKey:@"groupsPaneWidth"];
		[[NSUserDefaults standardUserDefaults] setValue:peopleWidth forKey:@"peoplePaneWidth"];
	}

    return NSTerminateNow;
}

@end
