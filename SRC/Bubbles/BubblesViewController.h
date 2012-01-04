//
//  BubblesViewController.h
//  Bubbles
//
//  Created by Wander See on 11-3-20.
//  Copyright 2011年 Tongji Apple Club. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GLNetwork.h"

#import "WDNetworkController.h"

@interface BubblesViewController : UIViewController
<UITextFieldDelegate, 
GLSenderDelegate, 
WDNetworkControllerDelegate> {
    GLSender *theSender_;
    GLReciever *theReceiver_;
    
    WDNetworkController *theNetwork_;
    
    IBOutlet UITextView *tfStringToSend_;
    IBOutlet UITextView *lbReceivedText_;
    IBOutlet UISwitch *swbtSwitchReceiver_;
}

- (IBAction)sendText:(id)sender;
- (IBAction)becomeReceiver:(UISwitch *)sender;

@end
