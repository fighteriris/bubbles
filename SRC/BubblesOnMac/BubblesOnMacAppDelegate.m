//
//  BubblesOnMacAppDelegate.m
//  BubblesOnMac
//
//  Created by Wander See on 11-3-20.
//  Copyright 2011年 Tongji Apple Club. All rights reserved.
//

#import "BubblesOnMacAppDelegate.h"

#define TEXT_RECEIVER_ON    @"Receiving"
#define TEXT_RECEIVER_OFF   @"Stopped"

@implementation BubblesOnMacAppDelegate

@synthesize window;

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
    //NSLog(@"BVC parseMessageInfo messageType: %ld.", messageType);
    if (messageType != kBubblesSendDataTypeText) {
        return;
    }
    
    NSString * messageContent = [[noti userInfo] objectForKey:kNFGLNetworkBasicInfo_MessageContent];
    [lbReceivedText_ setStringValue:messageContent];
}

- (void)refreshReceiverTable:(NSTimer *)timer {
	[theSender_ searchAvaliableServices];
}

#pragma mark - Normal Code

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [self initNetwork];
    [btSwitchReceiver_ setTitle:TEXT_RECEIVER_OFF];
}

#pragma mark - IBActions

- (IBAction)sendText:(id)sender {
    NSLog(@"BVC will send %@.", [tfStringToSend_ stringValue]);
	[theSender_ sendMessage:[tfStringToSend_ stringValue] 
              toServiceName:kNSString_NetServiceName_Auto];
}

- (IBAction)becomeReceiver:(NSButton *)sender {
    NSLog(@"becomeReceiver theValue: %@.", [sender stringValue]);
    if ([[sender title] isEqualToString:TEXT_RECEIVER_ON]) {
        [theReceiver_ stopReceiving];
        [sender setTitle:TEXT_RECEIVER_OFF];
    } else if ([[sender title] isEqualToString:TEXT_RECEIVER_OFF]) {
        [theReceiver_ startReceiving];
        [sender setTitle:TEXT_RECEIVER_ON];
    }  
}

#pragma mark - GLSenderDelegate

- (void) glsenderDidSearchAvaliableServices:(NSMutableArray *)serviceArray {
    
}

@end
