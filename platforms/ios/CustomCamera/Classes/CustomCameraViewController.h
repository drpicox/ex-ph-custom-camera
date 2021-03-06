//
//  CustomCameraViewController.h
//  CustomCamera
//
//  Created by Shane Carr on 1/3/14.
//
//

#import <UIKit/UIKit.h>

// We can't import the CustomCamera class because it would make a circular reference, so "fake" the existence of the class like this:
@class CustomCamera;

@interface CustomCameraViewController : UIViewController <UIImagePickerControllerDelegate, UINavigationControllerDelegate>

// Action method
-(IBAction) takePhotoButtonPressed:(id)sender forEvent:(UIEvent*)event;
-(IBAction) cancelPhotoButtonPressed:(id)sender;
-(void)takePictureTo;
-(void)setCountdown:(NSString*)count;
-(UIImage*)imageByScalingAndCroppingForSize:(UIImage*)anImage toSize:(CGSize)targetSize;
-(UIImage*)imageCorrectedForCaptureOrientation:(UIImage*)anImage;


// Declare some properties (to be explained soon)
@property (strong, nonatomic) CustomCamera* plugin;
@property (strong, nonatomic) UIImagePickerController* picker;
@property (weak, nonatomic) IBOutlet UILabel *countdownLabel;
@property (weak, nonatomic) IBOutlet UIImageView *frameImage;
@property (weak, nonatomic) IBOutlet UIButton *scanButton;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;

@end