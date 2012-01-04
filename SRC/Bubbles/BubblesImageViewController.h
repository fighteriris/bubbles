//
//  BubblesImageViewController.h
//  Bubbles
//
//  Created by Wander See on 11-5-1.
//  Copyright 2011年 Tongji Apple Club. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GLNetwork.h"

@interface BubblesImageViewController : UIViewController
<GLSenderDelegate, 
UIImagePickerControllerDelegate, 
UINavigationControllerDelegate> {
    GLSender *theSender_;
    GLReciever *theReceiver_;
    
    IBOutlet UIImageView *imvImageToSend_;
    IBOutlet UIImageView *imvImageRecieved_;
    IBOutlet UISwitch *swbtSwitchReceiver_;
}

- (IBAction)selectImage:(id)sender;
- (IBAction)sendImage:(id)sender;
- (IBAction)becomeReceiver:(UISwitch *)sender;

@end
