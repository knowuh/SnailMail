#import <Foundation/Foundation.h>


@interface NSAttributedString (NixanzAdditions)

//  This method will search for single item attribute dictionaries in self, and if the same attribut is found in
//  attributesString, then any other attributes in the same dictionary in attributes string are added to the
//  dictionary containing the original single attribute in self.

- (NSAttributedString *)addMatchingAttributesFromString:(NSAttributedString *)attributesString;
- (NSAttributedString *)reattributedWhitespaceString;

@end


@interface NSMutableAttributedString (NixanzAdditions)

//  This method will append the string aString to the mutable attributed string with the attributes of the
//  last existing character of the mutable attributed string.

- (void)appendString:(NSString *)aString;

@end
