/*
 Copyright (c) 2002 Jeff LaMarche
 
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


#import "NKDPostnetBarcode.h"


@implementation NKDPostnetBarcode
// -----------------------------------------------------------------------------------
-(id)initWithContent: (NSString *)inContent
       printsCaption: (BOOL)inPrints
// -----------------------------------------------------------------------------------
{

    if (self = [super init])
    {
        if (!inContent)
        {
            [self release];
            return nil;
        }
        [self setContent:inContent];

        [self setBarWidth:.015*kScreenResolution];
        [self setPrintsCaption:inPrints];

        // Postnet has a mandatory check digit
        [self generateChecksum];
        
        // .125 inch bar height is about the middle of the allowed values
        [self setHeight:.125*kScreenResolution];

        // Calculate width based on number of bars needed to encode this content
        [self calculateWidth];

        

    }
    return self;
}
// -----------------------------------------------------------------------------------
-(BOOL)printsCaption
// -----------------------------------------------------------------------------------
{
    // PostNet barcodes NEVER,EVER use a caption
    return NO;
}
// -----------------------------------------------------------------------------------
-(NSString *)initiator
// -----------------------------------------------------------------------------------
{
    return @"100";
}
// -----------------------------------------------------------------------------------
-(NSString *)terminator
// -----------------------------------------------------------------------------------
{
    return @"1";
}
// -----------------------------------------------------------------------------------
-(NSString *)_encodeChar:(char)inChar
// -----------------------------------------------------------------------------------
{
    // Each postnet character takes up 5 bars
    return @"100100100100100";
}
// -----------------------------------------------------------------------------------
-(float)barTop:(int)index
// -----------------------------------------------------------------------------------
{
    int		digit, bar;
    
    // Postnet works by varying the height of the bars - there are two heights, tall
    // and short. The terminator and initiator bars are always single tall bars

    // Look for and deal with terminator and initiator first
    if (index == 1)
        return TALL_BAR * kScreenResolution;

    if (index >= ([[self completeBarcode] length] - 1))
        return TALL_BAR * kScreenResolution;

    // Now, figure out which digit we're encoding, and which bar of that digit
    digit = (int)((index-3) / 15);
    bar = (index - (digit * 15)) / 3;
    return [self _heightForDigit:digit andBar:bar] * kScreenResolution;
}
// -----------------------------------------------------------------------------------
-(float)_heightForDigit:(int)index
                andBar:(int)bar
// -----------------------------------------------------------------------------------
{
    char *	barcode = (char *) [content lossyCString];
    char	check;

    check = (index >= strlen(barcode)) ? checkDigit : barcode[index];
    switch (check)
    {
       case '1':
           switch (bar)
           {
               case 4:
               case 5:
                   return TALL_BAR;
               default:
                   return SHORT_BAR;
           }
       case '2':
           switch (bar)
           {
               case 3:
               case 5:
                   return TALL_BAR;
               default:
                   return SHORT_BAR;
           }
       case '3':
           switch (bar)
           {
               case 3:
               case 4:
                   return TALL_BAR;
               default:
                   return SHORT_BAR;
           }
       case '4':
           switch (bar)
           {
               case 2:
               case 5:
                   return TALL_BAR;
               default:
                   return SHORT_BAR;
               
           }
       case '5':
           switch (bar)
           {
               case 2:
               case 4:
                   return TALL_BAR;
               default:
                   return SHORT_BAR;
               
            }
       case '6':
           switch (bar)
           {
               case 2:
               case 3:
                   return TALL_BAR;
               default:
                   return SHORT_BAR;
           }
       case '7':
           switch (bar)
           {
               case 1:
               case 5:
                   return TALL_BAR;
               default:
                   return SHORT_BAR;
           }
       case '8':
           switch (bar)
           {
               case 1:
               case 4:
                   return TALL_BAR;
               default:
                   return SHORT_BAR;
           }
       case '9':
           switch (bar)
           {
               case 1:
               case 3:
                   return TALL_BAR;
               default:
                   return SHORT_BAR;
           }
       case '0':
           switch (bar)
           {
               case 1:
               case 2:
                   return TALL_BAR;
               default:
                   return SHORT_BAR;
           }
    }
    return 0;
}
// -----------------------------------------------------------------------------------
-(BOOL) isContentValid
// -----------------------------------------------------------------------------------
{
    return ( [[[self content] stringByTrimmingCharactersInSet:[NSCharacterSet decimalDigitCharacterSet]] isEqualToString:@""]
             &&
            ( [[self content] length] == 5
            || [[self content] length] == 9
            || [[self content] length] == 11
              )
            );
}
// -----------------------------------------------------------------------------------
-(void)generateChecksum
// -----------------------------------------------------------------------------------
{
    char *	code = (char *)[[self content] lossyCString];
    int		i, sum=0;

    for (i = 0; i < strlen(code); i++)
        sum += code[i] - '0';

    [self setCheckDigit: (sum%10 == 0) ? '0': (10-(sum%10)) + '0'];
    
}
@end
