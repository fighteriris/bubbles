//
//  GLNetworkService.h
//  ANewMac
//
//  Created by Wander See on 10-5-13.
//  Copyright 2010 Leavesoft Inc. All rights reserved.
//

#import "GLNetworkPrivate.h"


@interface GLNetworkService : NSObject {

}

+ (void)helpRegisterANotificationObserver:(id)observer selector:(SEL)aSelector;
//+ (void)notifyMessageInfoWithType:(NSInteger)messageType content:(NSString *)theMessage;

//+ (void)notifyRecievedData:(NSData *)data withType:(WDBubblesSendDataType)type;
+ (void)notifyRecievedText:(NSString *)text;
+ (void)notifyRecievedImage:(NSData *)imageData;

@end
