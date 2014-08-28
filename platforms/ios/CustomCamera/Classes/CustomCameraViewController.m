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
    
    // Change image representation
    image = [self applyThreshold:image];
    
	// Get the image data (blocking; around 1 second)
	NSData* imageData = UIImagePNGRepresentation(image); //UIImageJPEGRepresentation(image, 0.5);
    
	// Write the data to the file
	//[imageData writeToFile:imagePath atomically:YES];
    NSString* imagePath = [imageData base64EncodedString];
    
	// Tell the plugin class that we're finished processing the image
	[self.plugin capturedImageWithPath:imagePath];
}



// https://github.com/OmidH/Filtrr/blob/master/FiltrrApp/FiltrrApp/Filtrr/UIImage%2BFiltrr.m

- (UIImage*) applyThreshold:(UIImage*)image {
    
    int i = 0;
    
    CGContextRef cgctx = [self createARGBBitmapContextFromImage:image.CGImage];
    size_t width = CGImageGetWidth(image.CGImage);
    size_t height = CGImageGetHeight(image.CGImage);
    
    
    
    
    
    unsigned char* data = CGBitmapContextGetData (cgctx);
    if (data != NULL) {
        int max = width * height * 4;

        // accummulate frequencies form two boxes
        unsigned int frequencies[256];
        for (i = 0; i < 256; i++) {
            frequencies[i] = 0;
        }
        /* with external control point
        [self accumulateFrequencies:frequencies from:data width:width height:height startX:575 startY:225];
        [self accumulateFrequencies:frequencies from:data width:width height:height startX:575 startY:375];
        [self accumulateFrequencies:frequencies from:data width:width height:height startX:225 startY:375];
        [self accumulateFrequencies:frequencies from:data width:width height:height startX:925 startY:375];
         */
        // Four "points" of the MRZ
        [self accumulateFrequencies:frequencies from:data width:width height:height startX:316 startY:375];
        [self accumulateFrequencies:frequencies from:data width:width height:height startX:478 startY:375];
        [self accumulateFrequencies:frequencies from:data width:width height:height startX:641 startY:375];
        [self accumulateFrequencies:frequencies from:data width:width height:height startX:803 startY:375];
        
        int threshold, accum = 0; // max accum === 10000 (50*50 * 2)
        for (threshold = 0; threshold < 256 && accum < 1800; threshold++) {
            accum += frequencies[threshold];
        }
        if (accum > 2100) {
            threshold--;
        }
        
        for (i = 0; i < max; i+=4) {
            
            unsigned char red,green,blue;
            
            red = data[i+1];
            green = data[i+2];
            blue = data[i+3];
            
            int sum = (red + green + blue)/3;
            if (sum > threshold) {
                red = green = blue = 255;
            } else {
                red = green = blue = 0;
            }
            
            data[i+1]=red;
            data[i+2]=green;
            data[i+3]=blue;
        }
    }
    
    UIImage *img = [self createImageFromContext:cgctx WithSize:CGSizeMake(width, height)];
    
    if (data) { free(data); }
    
    return img;
}

- (void) accumulateFrequencies:(unsigned int*)frequencies from:(unsigned char*)data width:(size_t)width height:(size_t)height startX:(int)startX startY:(int)startY {
    
    int x,y,sum;
    
    for (y = startY; y < startY + 50; y+=1) {
        for (x = startX; x < startX + 50; x++) {
            int offset = ((y*width)+x)*4;
            sum = 0; // no alpha
            sum += data[offset + 1];
            sum += data[offset + 2];
            sum += data[offset + 3];
            frequencies[sum/3]++;
        }
    }
}

- (CGContextRef) createARGBBitmapContextFromImage:(CGImageRef) imageRef {
    CGContextRef    context = NULL;
	CGColorSpaceRef colorSpace;
	void *          bitmapData;
	int             bitmapByteCount;
	int             bitmapBytesPerRow;
    
	// Get image width, height. We'll use the entire image.
	size_t pixelsWide = CGImageGetWidth(imageRef);
	size_t pixelsHigh = CGImageGetHeight(imageRef);
    
	// Declare the number of bytes per row. Each pixel in the bitmap in this
	// example is represented by 4 bytes; 8 bits each of red, green, blue, and
	// alpha.
	bitmapBytesPerRow   = (pixelsWide * 4);
	bitmapByteCount     = (bitmapBytesPerRow * pixelsHigh);
    
	// Use the generic RGB color space.
	colorSpace = CGColorSpaceCreateDeviceRGB();
	if (colorSpace == NULL)
	{
		fprintf(stderr, "Error allocating color space\n");
		return NULL;
	}
    
	// Allocate memory for image data. This is the destination in memory
	// where any drawing to the bitmap context will be rendered.
	bitmapData = malloc( bitmapByteCount );
	if (bitmapData == NULL)
	{
		fprintf (stderr, "Memory not allocated!");
		CGColorSpaceRelease( colorSpace );
		return NULL;
	}
    
	// Create the bitmap context. We want pre-multiplied ARGB, 8-bits
	// per component. Regardless of what the source image format is
	// (CMYK, Grayscale, and so on) it will be converted over to the format
	// specified here by CGBitmapContextCreate.
	context = CGBitmapContextCreate (bitmapData,
									 pixelsWide,
									 pixelsHigh,
									 8,      // bits per component
									 bitmapBytesPerRow,
									 colorSpace,
									 kCGImageAlphaPremultipliedFirst);
	if (context == NULL)
	{
		free (bitmapData);
		fprintf (stderr, "Context not created!");
	}
    
    CGRect rect = {{0,0},{pixelsWide, pixelsHigh}};
    //
    //        // Draw the image to the bitmap context. Once we draw, the memory
    //        // allocated for the context for rendering will then contain the
    //        // raw image data in the specified color space.
    CGContextDrawImage(context, rect, imageRef);
    
	// Make sure and release colorspace before returning
	CGColorSpaceRelease( colorSpace );
    
	return context;
}

- (UIImage *) createImageFromContext:(CGContextRef) cgctx WithSize:(CGSize) size {
    
    if (cgctx == NULL)
        // error creating context
        return nil;
    
    CGContextScaleCTM(cgctx, 1, -1);
    CGContextTranslateCTM(cgctx, 0, -size.height);
    
    CGImageRef   img = CGBitmapContextCreateImage(cgctx);
    UIImage*     ui_img = [UIImage imageWithCGImage: img];
    
    CGImageRelease(img);
    CGContextRelease(cgctx);
    
    return ui_img;
}



@end