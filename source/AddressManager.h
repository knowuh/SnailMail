#import <Foundation/Foundation.h>
#import <AddressBook/AddressBook.h>

@interface AddressManager : NSObject
{}

+ (AddressManager *)sharedAddressManager;
+ (NSArray *)personSortDescriptors;

- (NSString *)alphaName:(NSDictionary *)addrDict;
- (NSString *)linearAddress:(NSDictionary *)address;
- (NSAttributedString *)addressStringForAddressDict:(NSDictionary *)addrDict;
- (NSDictionary *)addressDictForPerson:(ABPerson *)pers sequence:(NSNumber *)sequence label:(NSString *)label address:(NSDictionary *)addr prefix:(NSString *)prefix suffix:(NSString *)suffix swapNames:(BOOL)swap;
//- (NSAttributedString *)addressStringForPerson:(ABPerson *)pers address:(NSDictionary *)addr prefix:(NSString *)prefix suffix:(NSString *)suffix;
- (NSAttributedString *)defaultAddressAttributesString;

@end
