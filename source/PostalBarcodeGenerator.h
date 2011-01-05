#import <Foundation/Foundation.h>
#import "NKDBarcode.h"
#import "NKDBarcodeOffscreenView.h"
#import "NKDPostnetBarcode.h"


@interface PostalBarcodeGenerator : NSObject
{

}

+ (NKDBarcode *)barcodeOfType:(int)type forContent:(NSString *)content;
+ (NKDBarcode *)barcodeOfType:(int)type forAddress:(NSDictionary *)addr;
+ (NKDBarcode *)barcodeOfType:(int)type forAddrString:(NSString *)addr;

@end
