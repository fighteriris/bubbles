//
//  GLNetworkService.m
//  ANewMac
//
//  Created by Wander See on 10-5-13.
//  Copyright 2010 Leavesoft Inc. All rights reserved.
//

#import "GLNetworkService.h"


@implementation GLNetworkService

+ (void)helpRegisterANotificationObserver:(id)observer selector:(SEL)aSelector {
	// Register Notification.
	[[NSNotificationCenter defaultCenter] 
     addObserver:observer
     selector:aSelector
	 name:kNFGLNetworkBasicInfo
	 object:nil];
}

/*
+ (void)notifyMessageInfoWithType:(NSInteger)messageType content:(NSString *)theMessage {
	//发送版。
	// post the notification to app delegate, and jump to setting view.
	NSMutableDictionary *d = [[[NSMutableDictionary alloc] init] autorelease];
	[d setObject:[NSString stringWithFormat:@"%d", messageType] 
          forKey:kNFGLNetworkBasicInfo_MessageType];
	[d setObject:theMessage 
          forKey:kNFGLNetworkBasicInfo_MessageContent];
	
	NSNotification *n = [NSNotification notificationWithName:kNFGLNetworkBasicInfo
                                                      object:NULL
                                                    userInfo:d];
	[[NSNotificationCenter defaultCenter] postNotification:n];
}

+ (void)notifyRecievedData:(NSData *)data withType:(WDBubblesSendDataType)type {
	NSMutableDictionary *d = [[[NSMutableDictionary alloc] init] autorelease];
	[d setObject:[NSNumber numberWithInt:type]
          forKey:kNFGLNetworkBasicInfo_MessageType];
	[d setObject:data
          forKey:kNFGLNetworkBasicInfo_MessageContent];
    
    NSNotification *n = [NSNotification notificationWithName:kNFGLNetworkBasicInfo
                                                      object:NULL
                                                    userInfo:d];
	[[NSNotificationCenter defaultCenter] postNotification:n];
}
*/

+ (void)notifyRecievedText:(NSString *)text {
	NSMutableDictionary *d = [[[NSMutableDictionary alloc] init] autorelease];
	[d setObject:[NSNumber numberWithInt:kBubblesSendDataTypeText]
          forKey:kNFGLNetworkBasicInfo_MessageType];
	[d setObject:text
          forKey:kNFGLNetworkBasicInfo_MessageContent];
    
    NSNotification *n = [NSNotification notificationWithName:kNFGLNetworkBasicInfo
                                                      object:NULL
                                                    userInfo:d];
	[[NSNotificationCenter defaultCenter] postNotification:n];
}


+ (void)notifyRecievedImage:(NSData *)imageData {
	NSMutableDictionary *d = [[[NSMutableDictionary alloc] init] autorelease];
	[d setObject:[NSNumber numberWithInt:kBubblesSendDataTypeImage]
          forKey:kNFGLNetworkBasicInfo_MessageType];
	[d setObject:imageData
          forKey:kNFGLNetworkBasicInfo_MessageContent];
    
    NSNotification *n = [NSNotification notificationWithName:kNFGLNetworkBasicInfo
                                                      object:NULL
                                                    userInfo:d];
	[[NSNotificationCenter defaultCenter] postNotification:n];
}

@end
