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