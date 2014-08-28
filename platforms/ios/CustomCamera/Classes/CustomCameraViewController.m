//
//  CustomCameraViewController.m
//  CustomCamera
//
//  Created by Shane Carr on 1/3/14.
//
//

#import "CustomCamera.h"
#import "CustomCameraViewController.h"
#import <Cordova/NSData+Base64.h>

@implementation CustomCameraViewController

// Entry point method
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	if (self) {
		// Instantiate the UIImagePickerController instance
		self.picker = [[UIImagePickerController alloc] init];
        
		// Configure the UIImagePickerController instance
		self.picker.sourceType = UIImagePickerControllerSourceTypeCamera;
		self.picker.cameraCaptureMode = UIImagePickerControllerCameraCaptureModePhoto;
		self.picker.cameraDevice = UIImagePickerControllerCameraDeviceFront; //..Rear;
		self.picker.showsCameraControls = NO;
        
		// Make us the delegate for the UIImagePickerController
		self.picker.delegate = self;
        
		// Set the frames to be full screen
		CGRect screenFrame = [[UIScreen mainScreen] bounds];
		self.view.frame = screenFrame;
		self.picker.view.frame = screenFrame;
        
        
		// Set this VC's view as the overlay view for the UIImagePickerController
		self.picker.cameraOverlayView = self.view;

        // Load image mask
        self.frameImage.image = [UIImage imageNamed:@"www/CameraMask.png"];        

        // Do not show countdown... for now
        self.countdownLabel.hidden = true;
        // Set label for the scan button
        [self.scanButton setTitle:@"SCAN!" forState:UIControlStateNormal];
        
	}
	return self;
}

-(void)setCountdown:(NSString*)count {
    [self.scanButton setTitle:count forState:UIControlStateNormal];
    //self.countdownLabel.text = count;
}

-(void)takePictureTo {
    [self.picker takePicture];
}

// Action method.  This is like an event callback in JavaScript.
-(IBAction) takePhotoButtonPressed:(id)sender forEvent:(UIEvent*)event {
	// Call the takePicture method on the UIImagePickerController to capture the image.
	//[self.picker takePicture];
    
    // Take a picture automatically 3 seconds after
    [self performSelector:@selector(setCountdown:) withObject:@"2" afterDelay:1.0f];
    [self performSelector:@selector(setCountdown:) withObject:@"1" afterDelay:2.0f];
    [self performSelector:@selector(setCountdown:) withObject:@"0" afterDelay:3.0f];
    
    // Take the picture
    [self performSelector:@selector(takePictureTo) withObject:nil afterDelay:3.5f];

    [self setCountdown:@"3"];
    //self.countdownLabel.hidden = false;
}

- (UIImage*)imageByScalingAndCroppingForSize:(UIImage*)anImage toSize:(CGSize)targetSize
{
    UIImage* sourceImage = anImage;
    UIImage* newImage = nil;
    CGSize imageSize = sourceImage.size;
    CGFloat width = imageSize.width;
    CGFloat height = imageSize.height;
    CGFloat targetWidth = targetSize.width;
    CGFloat targetHeight = targetSize.height;
    CGFloat scaleFactor = 1;
    CGFloat scaledWidth = targetWidth;
    CGFloat scaledHeight = targetHeight;
    CGPoint thumbnailPoint = CGPointMake(0.0, 0.0);
    
    CGFloat widthFactor = targetWidth / width;
    CGFloat heightFactor = targetHeight / height;
    if (widthFactor > heightFactor) {
        scaleFactor = widthFactor;
    } else {
        scaleFactor = heightFactor;
    }
    
    scaledWidth = width * scaleFactor;
    scaledHeight = height * scaleFactor;
    thumbnailPoint.y = (targetHeight - scaledHeight) * 0.5;
    thumbnailPoint.x = (targetWidth - scaledWidth) * 0.5;
    
    UIGraphicsBeginImageContext(targetSize); // this will crop
    
    CGRect thumbnailRect = CGRectZero;
    thumbnailRect.origin = thumbnailPoint;
    thumbnailRect.size.width = scaledWidth;
    thumbnailRect.size.height = scaledHeight;
    
    [sourceImage drawInRect:thumbnailRect];
    
    
    newImage = UIGraphicsGetImageFromCurrentImageContext();
    if (newImage == nil) {
        NSLog(@"could not scale image");
    }
    
    // pop the context to get back to the default
    UIGraphicsEndImageContext();
    return newImage;
}

- (UIImage*)imageCorrectedForCaptureOrientation:(UIImage*)anImage
{
    float rotation_radians = 0;
    bool perpendicular = false;
    
    switch ([anImage imageOrientation]) {
        case UIImageOrientationUp :
            rotation_radians = 0.0;
            break;
            
        case UIImageOrientationDown:
            rotation_radians = M_PI; // don't be scared of radians, if you're reading this, you're good at math
            break;
            
        case UIImageOrientationRight:
            rotation_radians = M_PI_2;
            perpendicular = true;
            break;
            
        case UIImageOrientationLeft:
            rotation_radians = -M_PI_2;
            perpendicular = true;
            break;
            
        default:
            break;
    }
    
    UIGraphicsBeginImageContext(CGSizeMake(anImage.size.width, anImage.size.height));
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // Rotate around the center point
    CGContextTranslateCTM(context, anImage.size.width / 2, anImage.size.height / 2);
    CGContextRotateCTM(context, rotation_radians);
    
    CGContextScaleCTM(context, 1.0, -1.0);
    float width = perpendicular ? anImage.size.height : anImage.size.width;
    float height = perpendicular ? anImage.size.width : anImage.size.height;
    CGContextDrawImage(context, CGRectMake(-width / 2, -height / 2, width, height), [anImage CGImage]);
    
    // Move the origin back since the rotation might've change it (if its 90 degrees)
    if (perpendicular) {
        CGContextTranslateCTM(context, -anImage.size.height / 2, -anImage.size.width / 2);
    }
    
    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

// older api calls newer didFinishPickingMediaWithInfo
- (void)imagePickerController:(UIImagePickerController*)picker didFinishPickingImage:(UIImage*)image editingInfo:(NSDictionary*)editingInfo
{
    NSDictionary* imageInfo = [NSDictionary dictionaryWithObject:image forKey:UIImagePickerControllerOriginalImage];
    
    [self imagePickerController:picker didFinishPickingMediaWithInfo:imageInfo];
}

// Delegate method.  UIImagePickerController will call this method as soon as the image captured above is ready to be processed.  This is also like an event callback in JavaScript.
-(void) imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
	// Get a reference to the captured image
	UIImage* image = [info objectForKey:UIImagePickerControllerOriginalImage];
    
    // Correct orientation
    image = [self imageCorrectedForCaptureOrientation:image];
    
    // Crop and resize
    CGSize targetSize = CGSizeMake(1200, 500);
    image = [self imageByScalingAndCroppingForSize:image toSize:targetSize];
    
	// Get the image data (blocking; around 1 second)
	NSData* imageData = UIImagePNGRepresentation(image); //UIImageJPEGRepresentation(image, 0.5);
    
	// Write the data to the file
	//[imageData writeToFile:imagePath atomically:YES];
    NSString* imagePath = [imageData base64EncodedString];
    
	// Tell the plugin class that we're finished processing the image
	[self.plugin capturedImageWithPath:imagePath];
}

@end