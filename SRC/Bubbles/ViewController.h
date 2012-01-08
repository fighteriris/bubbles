//
//  ViewController.h
//  LearnBonjour
//
//  Created by 王 得希 on 12-1-5.
//  Copyright (c) 2012年 BMW Group ConnectedDrive Lab China. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WDBubble.h"

@interface ViewController : UIViewController <UITextFieldDelegate, WDBubbleDelegate>

@property (nonatomic, retain) WDBubble *bubble;
@property (nonatomic, retain) IBOutlet UITextField *input;
@property (nonatomic, retain) IBOutlet UITextView *result;

@end
