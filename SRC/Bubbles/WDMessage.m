//
//  WDMessage.m
//  LearnBonjour
//
//  Created by 王 得希 on 12-1-6.
//  Copyright (c) 2012年 BMW Group ConnectedDrive Lab China. All rights reserved.
//

#import "WDMessage.h"

@implementation WDMessage
@synthesize sender, time, content;

+ (id)messageWithText:(NSString *)text {
    WDMessage *m = [[WDMessage alloc] init];
    m.content = [text dataUsingEncoding:NSUTF8StringEncoding];
    m.time = [NSDate date];
    return m;
}

@end
