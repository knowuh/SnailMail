//
//  SnailMailPlugin.m
//  Snail Mail
//
//  Created by Nik Sands on Fri May 07 2004.
//  Copyright (c) 2004 NIXANZ. All rights reserved.
//

#import "SnailMailPlugin.h"
#import "SnailMailController.h"


@implementation SnailMailPlugin

- (NSString *)actionProperty
{
    return kABAddressProperty;
}

- (NSString *)titleForPerson:(ABPerson *)person identifier:(NSString *)identifier
{
    return [NSString stringWithFormat:@"Print Snail Mail Envelope"];    
}

- (void)performActionForPerson:(ABPerson *)person identifier:(NSString *)identifier
{
	ABMultiValue *personAddresses;
    int index;
    NSDictionary *address;
	id smControllerProxy = NULL;
	NSDate *timeoutDate = [NSDate dateWithTimeIntervalSinceNow:60];

    personAddresses = [person valueForProperty:kABAddressProperty];
    index = [personAddresses indexForIdentifier:identifier];
    address = [personAddresses valueAtIndex:index];
	
	NSLog(@"Launching SM application");

	if ( ! [[NSWorkspace sharedWorkspace] launchAppWithBundleIdentifier:@"com.nixanz.snailmail"
														 options:NSWorkspaceLaunchAndHide
								  additionalEventParamDescriptor:NULL
												launchIdentifier:NULL]
		 )
	{
		NSLog(@"Snail Mail Address Book plug-in failed to launch Snail Mail application");
		NSRunAlertPanel(@"Failed to Launch Snail Mail",
						@"The plug-in was unable to launch the Snail Mail application.\n\nMake sure there is only one instance of Snail Mail installed (none in the Trash), and log out/in again.",
						@"Cancel",
						nil,
						nil);
		return;
	}
	
	while ( ! smControllerProxy && [timeoutDate timeIntervalSinceNow] > 0 )
	{
		smControllerProxy = [NSConnection rootProxyForConnectionWithRegisteredName:@"com_nixanz_snailmail" host:nil];
	}
	if ( ! smControllerProxy )
	{
		NSLog(@"Snail Mail Address Book plug-in failed to communicate with Snail Mail application (timed out)");
		return;
	}
	
	[smControllerProxy pluginPrintEnvelopeForPerson:person address:address];
}

- (BOOL)shouldEnableActionForPerson:(ABPerson *)person identifier:(NSString *)identifier
{
    return YES;
}

@end
