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
