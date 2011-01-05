// -----------------------------------------------------------------------------------
//  NKDBarcodeOffscreenView.m
// -----------------------------------------------------------------------------------
//  Created by Jeff LaMarche on Mon May 06 2002.
//  ©2002 Naked Software. All rights reserved.
// -----------------------------------------------------------------------------------
// THIS	SOURCE CODE IS PROVIDED AS-IS WITH NO WARRANTY OF ANY KIND
// -----------------------------------------------------------------------------------
// You may use and redistribute this source code with the following limitations
//
// 1) Any redistribution must contain all original comments, including this license.
//    Any changes you make must be wrapped in comments explaining what you did and
//    why and also contain your e-mail address. You should also send a copy of the
//    modified source code file to jeff_lamarche@mac.com
// 2) You may not charge for the source code. If you wish to distribute this source
//    code as part of a larger collection, please contact the author directly.
// 3) You may distribute compiled software that uses this source code without any
//    restrictions or limitations. A mention in the about box or documentation is
//    appreciated.
// -----------------------------------------------------------------------------------
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
