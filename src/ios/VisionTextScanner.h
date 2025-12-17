#import <Cordova/CDVPlugin.h>
#import <Vision/Vision.h>
#import <VisionKit/VisionKit.h>
#import <UIKit/UIKit.h>

@interface VisionTextScanner : CDVPlugin <UIImagePickerControllerDelegate, UINavigationControllerDelegate, VNDocumentCameraViewControllerDelegate>

@property (nonatomic, strong) CDVInvokedUrlCommand *currentCommand;
@property (nonatomic, strong) UIImagePickerController *imagePicker;

- (void)scanFromCamera:(CDVInvokedUrlCommand*)command;
- (void)scanFromGallery:(CDVInvokedUrlCommand*)command;
- (void)scanFromBase64:(CDVInvokedUrlCommand*)command;

@end