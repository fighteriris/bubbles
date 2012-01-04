//
//  GLReciever.h
//  ANewMac
//
//  Created by Wander See on 10-5-13.
//  Copyright 2010 Leavesoft Inc. All rights reserved.
//

#import "GLNetworkPrivate.h"

// 只要点了“启动”，这个函数就一直在接收接收。

@interface GLReciever : NSObject
<NSNetServiceDelegate, 
NSStreamDelegate, 
NSNetServiceBrowserDelegate> {
	
	NSNetService    *_netService;
	CFSocketRef     _listeningSocket;

	NSInputStream   *_networkStream;
	NSOutputStream  *_fileStream;

	uint8_t     textToRecieveBuffer[SOCK_MAXADDRLEN];
	NSInteger   _actualLengthOfRecievedData;
	
	// 为加入搜索而设。
	NSString    *_strDomain;
	NSString    *_strNetServiceType;
	NSString    *_strNetServiceName;
    
    // Image and text.
    //NSInteger dataType_;
}

@property (nonatomic, readonly) BOOL isStarted;

- (void)startOrStopServer;
- (void)startReceiving;
- (void)stopReceiving;

@end
