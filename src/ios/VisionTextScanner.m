#import "VisionTextScanner.h"

@implementation VisionTextScanner

#pragma mark - Plugin Methods

- (void)scanFromCamera:(CDVInvokedUrlCommand*)command {
    self.currentCommand = command;
    
    // Check if VisionKit Document Scanner is available (iOS 13+)
    if (@available(iOS 13.0, *)) {
        [self presentDocumentCameraViewController];
    } else {
        // Fallback to regular camera
        [self presentImagePickerWithSourceType:UIImagePickerControllerSourceTypeCamera];
    }
}

- (void)scanFromGallery:(CDVInvokedUrlCommand*)command {
    self.currentCommand = command;
    [self presentImagePickerWithSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
}

- (void)scanFromBase64:(CDVInvokedUrlCommand*)command {
    self.currentCommand = command;
    
    NSString *base64String = [command.arguments objectAtIndex:0];
    
    // Remove data URL prefix if present
    if ([base64String containsString:@"base64,"]) {
        NSArray *parts = [base64String componentsSeparatedByString:@"base64,"];
        if (parts.count > 1) {
            base64String = parts[1];
        }
    }
    
    // Convert base64 to image
    NSData *imageData = [[NSData alloc] initWithBase64EncodedString:base64String options:NSDataBase64DecodingIgnoreUnknownCharacters];
    UIImage *image = [UIImage imageWithData:imageData];
    
    if (image) {
        [self performTextRecognition:image];
    } else {
        [self sendError:@"Failed to decode base64 image"];
    }
}

#pragma mark - Document Camera (iOS 13+)

- (void)presentDocumentCameraViewController API_AVAILABLE(ios(13.0)) {
    dispatch_async(dispatch_get_main_queue(), ^{
        VNDocumentCameraViewController *documentCamera = [[VNDocumentCameraViewController alloc] init];
        documentCamera.delegate = self;
        
        UIViewController *rootViewController = [UIApplication sharedApplication].delegate.window.rootViewController;
        [rootViewController presentViewController:documentCamera animated:YES completion:nil];
    });
}

// VNDocumentCameraViewControllerDelegate
- (void)documentCameraViewController:(VNDocumentCameraViewController *)controller didFinishWithScan:(VNDocumentCameraScan *)scan API_AVAILABLE(ios(13.0)) {
    [controller dismissViewControllerAnimated:YES completion:^{
        // Process all scanned pages
        NSMutableArray *allText = [NSMutableArray array];
        
        for (NSUInteger i = 0; i < scan.pageCount; i++) {
            UIImage *image = [scan imageOfPageAtIndex:i];
            [self performTextRecognition:image completion:^(NSString *text) {
                if (text) {
                    [allText addObject:text];
                }
                
                // If this is the last page, send results
                if (i == scan.pageCount - 1) {
                    NSString *combinedText = [allText componentsJoinedByString:@"\n\n"];
                    [self sendSuccess:combinedText withImage:image];
                }
            }];
        }
    }];
}

- (void)documentCameraViewControllerDidCancel:(VNDocumentCameraViewController *)controller API_AVAILABLE(ios(13.0)) {
    [controller dismissViewControllerAnimated:YES completion:^{
        [self sendError:@"User cancelled"];
    }];
}

- (void)documentCameraViewController:(VNDocumentCameraViewController *)controller didFailWithError:(NSError *)error API_AVAILABLE(ios(13.0)) {
    [controller dismissViewControllerAnimated:YES completion:^{
        [self sendError:error.localizedDescription];
    }];
}

#pragma mark - Image Picker

- (void)presentImagePickerWithSourceType:(UIImagePickerControllerSourceType)sourceType {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.imagePicker = [[UIImagePickerController alloc] init];
        self.imagePicker.delegate = self;
        self.imagePicker.sourceType = sourceType;
        self.imagePicker.allowsEditing = NO;
        
        UIViewController *rootViewController = [UIApplication sharedApplication].delegate.window.rootViewController;
        [rootViewController presentViewController:self.imagePicker animated:YES completion:nil];
    });
}

// UIImagePickerControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey,id> *)info {
    [picker dismissViewControllerAnimated:YES completion:^{
        UIImage *image = info[UIImagePickerControllerOriginalImage];
        if (image) {
            [self performTextRecognition:image];
        } else {
            [self sendError:@"Failed to get image"];
        }
    }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:^{
        [self sendError:@"User cancelled"];
    }];
}

#pragma mark - Vision Text Recognition

- (void)performTextRecognition:(UIImage *)image {
    [self performTextRecognition:image completion:^(NSString *text) {
        [self sendSuccess:text withImage:image];
    }];
}

- (void)performTextRecognition:(UIImage *)image completion:(void(^)(NSString *text))completion {
    // Convert UIImage to CIImage
    CIImage *ciImage = [[CIImage alloc] initWithImage:image];
    
    // Create text recognition request
    VNRecognizeTextRequest *request = [[VNRecognizeTextRequest alloc] initWithCompletionHandler:^(VNRequest *request, NSError *error) {
        if (error) {
            NSLog(@"Text recognition error: %@", error.localizedDescription);
            if (completion) completion(nil);
            return;
        }
        
        // Process results
        NSMutableArray *recognizedStrings = [NSMutableArray array];
        
        for (VNRecognizedTextObservation *observation in request.results) {
            VNRecognizedText *topCandidate = [observation topCandidates:1].firstObject;
            if (topCandidate) {
                [recognizedStrings addObject:topCandidate.string];
            }
        }
        
        NSString *finalText = [recognizedStrings componentsJoinedByString:@"\n"];
        
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(finalText);
            });
        }
    }];
    
    // Configure request
    request.recognitionLevel = VNRequestTextRecognitionLevelAccurate;
    request.recognitionLanguages = @[@"en-US"]; // Add more languages as needed
    request.usesLanguageCorrection = YES;
    
    // Create request handler
    VNImageRequestHandler *handler = [[VNImageRequestHandler alloc] initWithCIImage:ciImage options:@{}];
    
    // Perform request
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        NSError *error;
        [handler performRequests:@[request] error:&error];
        if (error) {
            NSLog(@"Failed to perform text recognition: %@", error.localizedDescription);
            if (completion) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    completion(nil);
                });
            }
        }
    });
}

#pragma mark - Helper Methods

- (void)sendSuccess:(NSString *)text withImage:(UIImage *)image {
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    result[@"text"] = text ?: @"";
    result[@"success"] = @YES;
    
    // Convert image to base64 (optional)
    if (image) {
        NSData *imageData = UIImageJPEGRepresentation(image, 0.8);
        NSString *base64Image = [imageData base64EncodedStringWithOptions:0];
        result[@"image"] = [NSString stringWithFormat:@"data:image/jpeg;base64,%@", base64Image];
    }
    
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:result];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:self.currentCommand.callbackId];
}

- (void)sendError:(NSString *)errorMessage {
    NSDictionary *result = @{
        @"success": @NO,
        @"error": errorMessage ?: @"Unknown error"
    };
    
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:result];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:self.currentCommand.callbackId];
}

@end