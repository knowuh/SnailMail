#import "ABPersonAdditions.h"


@implementation ABPerson (NixanzAdditions)

- (NSComparisonResult)compare:(ABPerson*)otherPerson
{
	NSString *selfString;
	NSString *otherString;
	NSMutableArray *selfArray = [[NSMutableArray alloc] init];
	NSMutableArray *otherArray = [[NSMutableArray alloc] init];
	NSString *selfLastName = [self valueForProperty:kABLastNameProperty];
	NSString *selfFirstName = [self valueForProperty:kABFirstNameProperty];
	NSString *selfCompany = [self valueForProperty:kABOrganizationProperty];
	NSString *otherLastName = [otherPerson valueForProperty:kABLastNameProperty];
	NSString *otherFirstName = [otherPerson valueForProperty:kABFirstNameProperty];
	NSString *otherCompany = [otherPerson valueForProperty:kABOrganizationProperty];
	
	if ( selfLastName )
		[selfArray addObject:selfLastName];
	if ( selfFirstName )
		[selfArray addObject:selfFirstName];
	if ( selfCompany )
		[selfArray addObject:selfCompany];
	if ( otherLastName )
		[otherArray addObject:otherLastName];
	if ( otherFirstName )
		[otherArray addObject:otherFirstName];
	if ( otherCompany )
		[otherArray addObject:otherCompany];
	
	selfString = [selfArray componentsJoinedByString:@", "];
	otherString = [otherArray componentsJoinedByString:@", "];
	
	[selfArray release];
	[otherArray release];
	
	return [selfString compare:otherString];
}

@end