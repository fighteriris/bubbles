//
//  BubblesViewController.m
//  Bubbles
//
//  Created by Wander See on 11-3-20.
//  Copyright 2011年 Tongji Apple Club. All rights reserved.
//

#import "BubblesViewController.h"

@implementation BubblesViewController

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
    NSLog(@"BVC parseMessageInfo messageType: %i.", messageType);
    if (messageType != kBubblesSendDataTypeText) {
        return;
    }
    
    NSString * messageContent = [[noti userInfo] objectForKey:kNFGLNetworkBasicInfo_MessageContent];
    lbReceivedText_.text = messageContent;
}

- (void)refreshReceiverTable:(NSTimer *)timer {
	[theSender_ searchAvaliableServices];
}

#pragma mark - Normal Code

- (void)dealloc {
    [theSender_ release];
    [theReceiver_ release];
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
    self.title = @"Send Text";
    
    [self initNetwork];
    swbtSwitchReceiver_.on = NO;
    
    theNetwork_ = [[WDNetworkController alloc] init];
    theNetwork_.delegate = self;
    [theNetwork_ startServer];
}

- (void)viewDidUnload {
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

#pragma mark - Events

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    //UITouch *aTouch = [touches anyObject];
    //NSLog(@"VC touchesEnded view %@.", aTouch.view);
    
    [tfStringToSend_ resignFirstResponder];
}

#pragma mark - IBActions

- (IBAction)sendText:(id)sender {
    NSLog(@"BVC will send %@.", tfStringToSend_.text);
	[theSender_ sendMessage:tfStringToSend_.text 
              toServiceName:kNSString_NetServiceName_Auto];
}

- (IBAction)becomeReceiver:(UISwitch *)sender {
    if (sender.on) {
        [theReceiver_ startReceiving];
    } else {
        [theReceiver_ stopReceiving];
    }
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
	[tfStringToSend_ resignFirstResponder];
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	[tfStringToSend_ resignFirstResponder];
    return YES;
}

#pragma mark - GLSenderDelegate

- (void) glsenderDidSearchAvaliableServices:(NSMutableArray *)serviceArray {
    
}

#pragma mark - WDNetworkControllerDelegate

- (void)didFindPoint:(NSString *)pointID {
    
}

- (void)didReceiveData:(NSData *)data fromPoint:(NSString *)pointID withType:(WDNetworkDataType)dataType {
    
}

@end
