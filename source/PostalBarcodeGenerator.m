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
