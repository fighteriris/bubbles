//
//  Sender.h
//  ANewMac
//
//  Created by Wander See on 10-5-13.
//  Copyright 2010 Leavesoft Inc. All rights reserved.
//

#import "GLNetworkPrivate.h"

// 调用一次发送函数，发送一次。

@class GLSender;

@protocol GLSenderDelegate <NSObject>
@required
- (void) glsenderDidSearchAvaliableServices:(NSMutableArray *)serviceArray;
@end

@interface GLSender : NSObject<NSNetServiceDelegate, NSStreamDelegate, NSNetServiceBrowserDelegate> {
	
	NSNetService *              _netService;
	NSOutputStream *            _networkStream;
	NSInputStream *             _fileStream;
	uint8_t                     _buffer[kSendBufferSize];
	size_t                      _bufferOffset;
	size_t                      _bufferLimit;
	
	// 加入可以“查看”的Browser。
	id<GLSenderDelegate>			_delegate;
	NSNetServiceBrowser *		_netServiceBrowser;
	NSString *						_strServiceNameToSend;
	NSMutableArray *				_servicesFound;
}

@property (nonatomic, assign) id<GLSenderDelegate> delegate;

- (void)sendData:(void *)anyData toService:(NSString *)theServiceName;
- (void)sendMessage:(NSString *)theString toServiceName:(NSString *)theServiceName;
- (void)sendImage:(NSData *)theImageData toService:(NSString *)theServiceName;
- (void)searchAvaliableServices;

@end
