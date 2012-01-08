//
//  WDMessage.h
//  LearnBonjour
//
//  Created by 王 得希 on 12-1-6.
//  Copyright (c) 2012年 BMW Group ConnectedDrive Lab China. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WDMessage : NSObject {
    NSString *_sender;
    NSDate *_time;
    NSData *_content;
}

@property (nonatomic, retain) NSString *sender;
@property (nonatomic, retain) NSDate *time;
@property (nonatomic, retain) NSData *content;

+ (id)messageWithText:(NSString *)text;

@end
