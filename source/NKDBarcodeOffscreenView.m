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


#import "NKDBarcodeOffscreenView.h"

@implementation NKDBarcodeOffscreenView

- (id)initWithBarcode:(NKDBarcode *)inBarcode
{
    NSRect	frame = NSMakeRect(0,0,[inBarcode width], [inBarcode height]);
    // Calculate frame and then...

    
    self = [super initWithFrame:frame];
    if (self)
    {
        [self setBarcode:inBarcode];
    }
    return self;
}

- (void)drawRect:(NSRect)rect
{
    int				i, barCount=0;
    float			curPos = [barcode firstBar];
    NSString 			*codeString = [barcode completeBarcode];
    NSMutableParagraphStyle	*style = [[NSMutableParagraphStyle alloc] init];
    NSBezierPath		*path;

    BOOL			started = NO;

    for (i = 0; i < [codeString length]; i++)
    {
        if ([codeString characterAtIndex:i] == '1')
        {
            if (!started)
                started = YES;
            
            barCount++;

            // If last character is a bar, it needs to be printed here.
            if (i == [codeString length]-1)
            {
                path = [NSBezierPath bezierPathWithRect:NSMakeRect(curPos,
                                                                   [barcode barBottom:i],
                                                                   [barcode barWidth] * barCount,
                                                                   [barcode barTop:i] - [barcode barBottom:i] )];
                [[NSColor blackColor] set];
                [path setLineWidth:0.0];
                [path fill];
                [[NSColor whiteColor] set];                
            }
        }
        else
        {
            if (started)
            {
                path = [NSBezierPath bezierPathWithRect:NSMakeRect(curPos,
                                                                [barcode barBottom:i],
                                                                [barcode barWidth] * barCount,
                                                                [barcode barTop:i] - [barcode barBottom:i] )];
                [[NSColor blackColor] set];
                [path setLineWidth:0.0];
                [path fill];
                [[NSColor whiteColor] set];
            }
            curPos += [barcode barWidth] * (barCount + 1);
            barCount = 0;
            started = NO;
        }
    }
    if ([barcode printsCaption])
    {

        // Left caption for UPC / EAN
        [style setAlignment:NSLeftTextAlignment];
        [[barcode leftCaption] drawAtPoint:NSMakePoint([barcode firstBar]/4, 3)
                            withAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                [NSFont fontWithName:@"Geneva" size:[barcode fontSize]], NSFontAttributeName,
                                style, NSParagraphStyleAttributeName, nil]];
        [style setAlignment:NSCenterTextAlignment];

        // Draw the main caption under the barcode
        [[barcode caption] drawAtPoint:NSMakePoint(0, 0)
                        withAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                            [NSFont fontWithName:@"Geneva" size:[barcode fontSize]], NSFontAttributeName,
                            style, NSParagraphStyleAttributeName, nil]];
        
        // Right caption for UPC / EAN
        [style setAlignment:NSRightTextAlignment];
        [[barcode rightCaption] drawAtPoint:NSMakePoint([barcode lastBar]+ ([barcode width]*.05),3)
                             withAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                 [NSFont fontWithName:@"Geneva" size:[barcode fontSize]], NSFontAttributeName,
                                 style, NSParagraphStyleAttributeName, nil]];

    }

    [style release];
}
// -----------------------------------------------------------------------------------
-(NKDBarcode *)barcode
// -----------------------------------------------------------------------------------
{
    return barcode;
}
// -----------------------------------------------------------------------------------
-(void)setBarcode:(NKDBarcode *)inBarcode
// -----------------------------------------------------------------------------------
{
    [barcode autorelease];
    barcode = inBarcode;
}
// -----------------------------------------------------------------------------------
-(BOOL)knowsPageRange:(NSRange *)rptr
// -----------------------------------------------------------------------------------
{
    rptr->location = 1;
    rptr->length = 1;
    return YES;
}
// -----------------------------------------------------------------------------------
-(NSRect)rectForPage:(int)pageNum
// -----------------------------------------------------------------------------------
{
    return  NSMakeRect(0,0,[[self barcode] width], [[self barcode] height]);
}
@end
