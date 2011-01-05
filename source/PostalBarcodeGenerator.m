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

#import "PostalBarcodeGenerator.h"
#import <AddressBook/AddressBook.h>


@implementation PostalBarcodeGenerator

+ (NKDBarcode *)barcodeOfType:(int)type forContent:(NSString *)content;
{
    NKDBarcode 	*barcode;

    if ( type == 2 )
    {
	barcode = [[NKDPostnetBarcode alloc] initWithContent:content printsCaption:0];

	if ([barcode isContentValid])
	{
	    [barcode calculateWidth];

	    return barcode;
	}
	else
	{
	    return nil;
	}
    }
    else
    {
	return nil;
    }
}

+ (NKDBarcode *)barcodeOfType:(int)type forAddress:(NSDictionary *)addr;
{
    NSMutableString *content;

    if ( type == 2 )
    {
        content = [[addr objectForKey:kABAddressZIPKey] mutableCopy];
        [content replaceOccurrencesOfString:@"-"
                                 withString:@""
                                    options:NSLiteralSearch
                                      range:NSMakeRange(0, [content length])
            ];
	[content autorelease];
	
        return [PostalBarcodeGenerator barcodeOfType:type forContent:content];
    }
    else
    {
        return nil;
    }
}

+ (NKDBarcode *)barcodeOfType:(int)type forAddrString:(NSString *)addr
{
    NSArray *lines = [addr componentsSeparatedByString:@"\n"];
    NSRange digitRange;
    NSRange whitespaceRange, postCodeRange;
    NSString *postCode, *postCodeLine;
    NSMutableString *content;

    if ( [lines count] < 1 )
    {
	return nil;
    }
    else
    {
	// Try last line as post code line
	postCodeLine = [lines objectAtIndex:([lines count] - 1)];
	digitRange = [postCodeLine rangeOfCharacterFromSet:[NSCharacterSet decimalDigitCharacterSet]];
    }

    if ( type == 2 )
    {
	// If no digits in last line, try second last line as post code line
	if ( digitRange.location == NSNotFound )
	{
	    if ( [lines count] < 2 )
		return nil;
	    else
		postCodeLine = [lines objectAtIndex:([lines count] - 2)];
	}

	whitespaceRange = [postCodeLine rangeOfCharacterFromSet:[NSCharacterSet whitespaceCharacterSet] options:NSBackwardsSearch];

	if ( whitespaceRange.location == NSNotFound )
	{
	    postCode = postCodeLine;
	}
	else
	{
	    postCodeRange.location = whitespaceRange.location + whitespaceRange.length;
	    postCodeRange.length = [postCodeLine length] - postCodeRange.location;

	    postCode = [postCodeLine substringWithRange:postCodeRange];
	}
	content = [postCode mutableCopy];
        [content replaceOccurrencesOfString:@"-"
                                 withString:@""
                                    options:NSLiteralSearch
                                      range:NSMakeRange(0, [content length])
            ];
	[content autorelease];

        return [PostalBarcodeGenerator barcodeOfType:type forContent:content];
    }
    else
    {
	return nil;
    }
}

@end
