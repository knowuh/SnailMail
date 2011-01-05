//
//  SnailMailPlugin.h
//  Snail Mail
//
//  Created by Nik Sands on Fri May 07 2004.
//  Copyright (c) 2004 NIXANZ. All rights reserved.
//

@interface SnailMailPlugin : NSObject
{
}

- (NSString *)actionProperty;
- (NSString *)titleForPerson:(ABPerson *)person identifier:(NSString *)identifier;
- (void)performActionForPerson:(ABPerson *)person identifier:(NSString *)identifier;
- (BOOL)shouldEnableActionForPerson:(ABPerson *)person identifier:(NSString *)identifier;

@end

