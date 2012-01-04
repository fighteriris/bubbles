//
//  BubblesImageViewController.m
//  Bubbles
//
//  Created by Wander See on 11-5-1.
//  Copyright 2011年 Tongji Apple Club. All rights reserved.
//

#import "BubblesImageViewController.h"
#import <MobileCoreServices/UTCoreTypes.h>

@implementation BubblesImageViewController

#pragma mark - Private Methods

- (void)initNetwork {
    
    // Sender
    theSender_ = [[GLSender alloc] init];
    theSender_.delegate = self;
    
    // Receiver
    theReceiver_ = [[GLReciever alloc] init];
    
	[GLNetworkService helpRegisterANotificationObserver:self selector:@selector(parseMessageInfo:)];
	[NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(refreshReceiverTable:) userInfo:nil repeats:YES];
}

- (void)parseMessageInfo:(NSNotification *)noti {
	NSInteger messageType = [[[noti userInfo] objectForKey:kNFGLNetworkBasicInfo_MessageType] intValue];
    NSLog(@"BIVC parseMessageInfo messageType: %i.", messageType);
    if (messageType != kBubblesSendDataTypeImage) {
        return;
    }
    
    NSData *imageData = [[noti userInfo] objectForKey:kNFGLNetworkBasicInfo_MessageContent];
    UIImage *theImage = [UIImage imageWithData:imageData];
    imvImageRecieved_.image = theImage;
}

- (void)refreshReceiverTable:(NSTimer *)timer {
	[theSender_ searchAvaliableServices];
}

#pragma mark - Normal Code

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)dealloc {
    [super dealloc];
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Send Image";
    
    [self initNetwork];
    swbtSwitchReceiver_.on = NO;
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

#pragma mark - IBActions

- (IBAction)selectImage:(id)sender {
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary] == NO) {
        return;
    }
    
    UIImagePickerController *mediaUI = [[UIImagePickerController alloc] init];
    mediaUI.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    mediaUI.mediaTypes =
    [UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
    mediaUI.allowsEditing = NO;
    mediaUI.delegate = self;
    
    [self presentModalViewController:mediaUI animated:YES];
}

- (IBAction)sendImage:(id)sender {
    [theSender_ sendImage:UIImageJPEGRepresentation(imvImageToSend_.image, 1.0)
                toService:kNSString_NetServiceName_Auto];
}

- (IBAction)becomeReceiver:(UISwitch *)sender {
    if (sender.on) {
        [theReceiver_ startReceiving];
    } else {
        [theReceiver_ stopReceiving];
    }
}

#pragma mark - GLSenderDelegate

- (void) glsenderDidSearchAvaliableServices:(NSMutableArray *)serviceArray {
    
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
    UIImage *originalImage, *editedImage, *imageToUse;
    
    // Handle a still image picked from a photo album
    if (CFStringCompare((CFStringRef)mediaType, kUTTypeImage, 0) == kCFCompareEqualTo) {
        editedImage = (UIImage *)[info objectForKey:UIImagePickerControllerEditedImage];
        originalImage = (UIImage *)[info objectForKey:UIImagePickerControllerOriginalImage];
        
        if (editedImage) {
            imageToUse = editedImage;
        } else {
            imageToUse = originalImage;
        }
        // Do something with imageToUse
        NSLog(@"BVC The image is %@.", imageToUse);
        imvImageToSend_.image = imageToUse;
    }
    
    // Handle a movied picked from a photo album
    if (CFStringCompare((CFStringRef)mediaType, kUTTypeMovie, 0) == kCFCompareEqualTo) {
        //NSString *moviePath = [[info objectForKey:UIImagePickerControllerMediaURL] path];
        
        // Do something with the picked movie available at moviePath
    }
    
    [self dismissModalViewControllerAnimated: YES];
    [picker release];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    NSLog(@"BVC canceled picker %@.", picker);
    [self dismissModalViewControllerAnimated:YES];
}

@end
