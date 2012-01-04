//
//  BubblesOnMacAppDelegate.h
//  BubblesOnMac
//
//  Created by Wander See on 11-3-20.
//  Copyright 2011年 Tongji Apple Club. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GLNetwork.h"

@interface BubblesOnMacAppDelegate : NSObject 
<NSApplicationDelegate,
GLSenderDelegate> {
    GLSender *theSender_;
    GLReciever *theReceiver_;
    
    IBOutlet NSTextField *tfStringToSend_;
    IBOutlet NSTextField *lbReceivedText_;
    IBOutlet NSButton *btSwitchReceiver_;
    
@private
    NSWindow *window;
}

@property (assign) IBOutlet NSWindow *window;

- (IBAction)sendText:(id)sender;
- (IBAction)becomeReceiver:(NSButton *)sender;

@end
