//
//  GLReciever.m
//  ANewMac
//
//  Created by Wander See on 10-5-13.
//  Copyright 2010 Leavesoft Inc. All rights reserved.
//

#import "GLReciever.h"

@interface GLReciever ()

// Properties that don't need to be seen by the outside world.
@property (nonatomic, readonly) BOOL                isReceiving;
@property (nonatomic, retain)   NSNetService *      netService;
@property (nonatomic, assign)   CFSocketRef         listeningSocket;
@property (nonatomic, retain)   NSInputStream *     networkStream;
@property (nonatomic, retain)   NSOutputStream *    fileStream;

// Forward declarations

- (void)_startServer;
- (void)_serverDidStartOnPort:(int)port;

static void AcceptCallback(CFSocketRef s, CFSocketCallBackType type, CFDataRef address, const void *data, void *info);
- (void)_acceptConnection:(int)fd;

- (void)_startReceive:(int)fd;
- (void)_receiveDidStart;

- (void)_stopReceiveWithStatus:(NSString *)statusString;
- (void)_receiveDidStopWithStatus:(NSString *)statusString;

- (void)_stopServer:(NSString *)reason;
- (void)_serverDidStopWithReason:(NSString *)reason;

@end

@implementation GLReciever

@synthesize netService      = _netService;
@synthesize networkStream   = _networkStream;
@synthesize listeningSocket = _listeningSocket;
@synthesize fileStream      = _fileStream;

#pragma mark 事件响应

- (void)startOrStopServer
{
	NSLog(@"startOrStopAction.");
    
	if (self.isStarted) {
		[self _stopServer:nil];
	} else {
		[self _startServer];
	}
}

- (void)startReceiving {
	if (self.isStarted) {
        return;
	}
    [self _startServer];
}

- (void)stopReceiving {
	if (!self.isStarted) {
        return;
	}
    [self _stopServer:nil];
    
}

#pragma mark 协助性的函数

//- (id)init
//{
//	if ([super init] == nil)
//	{
//		return nil;
//	}
//	
//	memset(textToRecieveBuffer, 0, SOCK_MAXADDRLEN);
//}

- (void)_updateStatus:(NSString *)statusString {
	assert(statusString != nil);
	
	NSLog(@"_updateStatus: %@.", statusString);
}

#pragma mark 内部逻辑实现

// 启动接收端，最终是会配置好netService和listeningSocket。
- (void)_startServer {
	// 做为一个Reciever嘛，很简单，一些参数是写死了的。
	_strDomain = kNSString_Domain;
	_strNetServiceType = kNSString_NetServiceType;
	_strNetServiceName = kNSString_NetServiceName_Auto;
	
	memset(textToRecieveBuffer, 0, SOCK_MAXADDRLEN);
	
	BOOL        success;
	int         err;
	int         fd;
	int         junk;
	struct sockaddr_in addr;
	int         port;
	
	// Create a listening socket and use CFSocket to integrate it into our 
	// runloop.  We bind to port 0, which causes the kernel to give us 
	// any free port, then use getsockname to find out what port number we 
	// actually got.
	
	port = 0;
	
	// socket()
	fd = socket(AF_INET, SOCK_STREAM, 0);
	success = (fd != -1);
	
	// bind()
	if (success) {
		memset(&addr, 0, sizeof(addr));
		addr.sin_len    = sizeof(addr);
		addr.sin_family = AF_INET;
		addr.sin_port   = 0;
		addr.sin_addr.s_addr = INADDR_ANY;
		err = bind(fd, (const struct sockaddr *) &addr, sizeof(addr));
		success = (err == 0);
	}
	// listen()
	if (success) {
		err = listen(fd, 5);
		success = (err == 0);
	}
	// getsockname()
	if (success) {
		socklen_t   addrLen;
		
		addrLen = sizeof(addr);
		err = getsockname(fd, (struct sockaddr *) &addr, &addrLen);
		success = (err == 0);
		
		// ntohs()
		if (success) {
			assert(addrLen == sizeof(addr));
			port = ntohs(addr.sin_port);
		}
	}
	if (success) {
		
		// 根据上面的信息生成一个“CFSocket”。我们有电话了！
		
		CFSocketContext context = { 0, self, NULL, NULL, NULL };
		// 这个生成的是最低要求的。
		
		self.listeningSocket = CFSocketCreateWithNative(
														NULL, 
														fd, 
														kCFSocketAcceptCallBack, 
														AcceptCallback, 
														&context
														);
		
		// 加入主循环。
		
		success = (self.listeningSocket != NULL);
		
		if (success) {
			CFRunLoopSourceRef  rls;
			
			CFRelease(self.listeningSocket);        // to balance the create
			
			fd = -1;        // listeningSocket is now responsible for closing fd
			
			rls = CFSocketCreateRunLoopSource(NULL, self.listeningSocket, 0);
			assert(rls != NULL);
			
			CFRunLoopAddSource(CFRunLoopGetCurrent(), rls, kCFRunLoopDefaultMode);
			
			CFRelease(rls);
		}
	}
	
	// Now register our service with Bonjour.  See the comments in -netService:didNotPublish: 
	// for more info about this simplifying assumption.
	
	// 正儿八经地生成一个NSNetService的类。
	if (success) {
		self.netService = [[[NSNetService alloc] initWithDomain:_strDomain type:_strNetServiceType name:_strNetServiceName port:port] autorelease];
		success = (self.netService != nil);
	}
	// 广播自己。
	if (success) {
		self.netService.delegate = self;
		
		[self.netService publishWithOptions:NSNetServiceNoAutoRename];
		
		// continues in -netServiceDidPublish: or -netService:didNotPublish: ...
	}
	
	// Clean up after failure.
	
	if ( success ) 
	{
		assert(port != 0);
		[self _serverDidStartOnPort:port];
	} 
	else 
	{
		[self _stopServer:@"Start failed"];
		if (fd != -1) 
		{
			junk = close(fd);
			assert(junk == 0);
		}
	}
}

// 接收端完成启动，这里做显示性工作。
- (void)_serverDidStartOnPort:(int)port
{
	assert( (port > 0) && (port < 65536) );
}

// 一直在等人连接啊。
static void AcceptCallback(CFSocketRef s, CFSocketCallBackType type, CFDataRef address, const void *data, void *info)
// Called by CFSocket when someone connects to our listening socket.  
// This implementation just bounces the request up to Objective-C.
{
    GLReciever *  obj;
    
#pragma unused(type)
    assert(type == kCFSocketAcceptCallBack);
#pragma unused(address)
    // assert(address == NULL);
    assert(data != NULL);
    
    obj = (GLReciever *) info;
    assert(obj != nil);
	
#pragma unused(s)
    assert(s == obj->_listeningSocket);
    
    [obj _acceptConnection:*(int *)data];
}

// 同意接收，说“我愿意”的地方。
- (void)_acceptConnection:(int)fd
{
	int     junk;
	
	// If we already have a connection, reject this new one.  This is one of the 
	// big simplifying assumptions in this code.  A real server should handle 
	// multiple simultaneous connections.
	
	if ( self.isReceiving ) {
		
		// 接收端只能是一个。
		
		junk = close(fd);
		assert(junk == 0);
	} else {
		[self _startReceive:fd];
	}
}

// 接收端做接收数据流的启动工作。
- (void)_startReceive:(int)fd
{
	CFReadStreamRef     readStream;
	
	assert(fd >= 0);
	
	assert(self.networkStream == nil);      // can't already be receiving
	assert(self.fileStream == nil);         // ditto
	//assert(self.filePath == nil);           // ditto
	
	// Open a stream for the file we're going to receive into.
	
	//self.filePath = [[ANewDeviceAppDelegate sharedAppDelegate] pathForTemporaryFileWithPrefix:@"Receive"];
	//assert(self.filePath != nil);
	
	//self.fileStream = [NSOutputStream outputStreamToFileAtPath:self.filePath append:NO];
	self.fileStream = [NSOutputStream outputStreamToBuffer:textToRecieveBuffer capacity:SOCK_MAXADDRLEN];
	assert(self.fileStream != nil);
	
	[self.fileStream open];
	
	// Open a stream based on the existing socket file descriptor.  Then configure 
	// the stream for async operation.
	
	CFStreamCreatePairWithSocket(NULL, fd, &readStream, NULL);
	assert(readStream != NULL);
	
	self.networkStream = (NSInputStream *) readStream;
	
	CFRelease(readStream);
	
	[self.networkStream setProperty:(id)kCFBooleanTrue forKey:(NSString *)kCFStreamPropertyShouldCloseNativeSocket];
	
	self.networkStream.delegate = self;
	[self.networkStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	
	[self.networkStream open];
	
	// Tell the UI we're receiving.
	
	[self _receiveDidStart];
}

// 接收端接受数据流已经开始，这里做显示性工作。
- (void)_receiveDidStart
{
}

// 这里是真正实现传输的地方。
- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode
// An NSStream delegate callback that's called when events happen on our 
// network stream.
{
#pragma unused(aStream)
	assert(aStream == self.networkStream);
	
	switch (eventCode) {
		case NSStreamEventOpenCompleted: {
			[self _updateStatus:@"Opened connection"];
		} break;
		case NSStreamEventHasBytesAvailable: {
			NSInteger       bytesRead;
			uint8_t         buffer[32768];
			
			[self _updateStatus:@"Receiving"];
			
			// Pull some data off the network.
			
			bytesRead = [self.networkStream read:buffer maxLength:sizeof(buffer)];
			if (bytesRead == -1)
			{
				[self _stopReceiveWithStatus:@"Network read error"];
			}
			else if (bytesRead == 0) 
			{
				// 接收完成。
				[self _stopReceiveWithStatus:nil];
				
			}
			else
			{
				NSInteger   bytesWritten;
				int   bytesWrittenSoFar;
				
				// Write to the file.
				
				bytesWrittenSoFar = 0;
				do
				{
					bytesWritten = [self.fileStream write:&buffer[bytesWrittenSoFar] maxLength:bytesRead - bytesWrittenSoFar];
					assert(bytesWritten != 0);
					if (bytesWritten == -1)
					{
						[self _stopReceiveWithStatus:@"File write error"];
						break;
					}
					else
					{
						bytesWrittenSoFar += bytesWritten;
					}
				}
				while (bytesWrittenSoFar != bytesRead);
				
				// 哈哈，知道了，这里就是整个字符串的长度。
				// 不过还是那个情况，这个只使用于英文。
				NSLog(@"Reciever bytesWrittenSoFar: %d.", bytesWrittenSoFar);
				_actualLengthOfRecievedData = bytesWrittenSoFar;
			}
		} break;
		case NSStreamEventHasSpaceAvailable: {
			assert(NO);     // should never happen for the output stream
		} break;
		case NSStreamEventErrorOccurred: {
			[self _stopReceiveWithStatus:@"Stream open error"];
		} break;
		case NSStreamEventEndEncountered: {
			// ignore
		} break;
		default: {
			assert(NO);
		} break;
	}
}

// 接收端接受数据流结束，这里做收尾工作。
- (void)_stopReceiveWithStatus:(NSString *)statusString
{
	if (self.networkStream != nil) {
		self.networkStream.delegate = nil;
		[self.networkStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
		[self.networkStream close];
		self.networkStream = nil;
	}
	if (self.fileStream != nil) {
		[self.fileStream close];
		self.fileStream = nil;
	}
	[self _receiveDidStopWithStatus:statusString];
	//self.filePath = nil;
}

// 接收端接受数据流收尾工作完成，这里做显示性工作。
//	对收到的数据也在这里进行处理。
- (void)_receiveDidStopWithStatus:(NSString *)statusString {
	if (statusString != nil) {
		statusString = @"Receive failed.";
        return;
    }
    
    NSInteger theType = 0;
    memcpy(&theType, textToRecieveBuffer+_actualLengthOfRecievedData-sizeof(NSInteger), sizeof(NSInteger));
    
    switch (theType) {
        case kBubblesSendDataTypeText: {
            NSLog(@"GLR _receiveDidStopWithStatus text.");
            NSString * textToShow = [[NSString alloc] initWithBytes:textToRecieveBuffer 
                                                             length:_actualLengthOfRecievedData-sizeof(NSInteger)
                                                           encoding:NSUTF8StringEncoding];
            NSLog(@"Sender textToRecieveBuffer: %s, textToShow: %@.", textToRecieveBuffer, textToShow);
            //[GLNetworkService notifyMessageInfoWithType:kBubblesDataStateRecieved content:textToShow];
            [GLNetworkService notifyRecievedText:textToShow];
            break;
        }
        case kBubblesSendDataTypeImage: {
            NSLog(@"GLR _receiveDidStopWithStatus image.");
            //NSLog(@"GLR _receiveDidStopWithStatus image %@.", (UIImage *)textToRecieveBuffer);
            [GLNetworkService notifyRecievedImage:
             [NSData dataWithBytes:textToRecieveBuffer 
                            length:_actualLengthOfRecievedData-sizeof(NSInteger)]];
            break;
        }
        default: {
            break;
        }
    }
    
	NSLog(@"_receiveDidStopWithStatus: %@.", statusString);
}

// Bonjou搞好了就调这个函数吧。
- (void)netServiceDidPublish:(NSNetService *)sender
{
    NSLog(@"GLReiever netServiceDidPublish sender.name: %@.", sender.name);
	// WiTap会用delegate在这里搞自己的gameName。
}

// Bonjour没搞好就会调这个函数。
- (void)netService:(NSNetService *)sender didNotPublish:(NSDictionary *)errorDict
// A NSNetService delegate callback that's called if our Bonjour registration 
// fails.  We respond by shutting down the server.
//
// This is another of the big simplifying assumptions in this sample. 
// A real server would use the real name of the device for registrations, 
// and handle automatically renaming the service on conflicts.  A real 
// client would allow the user to browse for services.  To simplify things 
// we just hard-wire the service name in the client and, in the server, fail 
// if there's a service name conflict.
{
	NSLog(@"GLReiever netServiceDidNotPublish.");
    
#pragma unused(sender)
	assert(sender == self.netService);
#pragma unused(errorDict)
	
	[self _stopServer:@"Registration failed"];
}

// 关闭接收端。
- (void)_stopServer:(NSString *)reason
{
	if (self.isReceiving) {
		[self _stopReceiveWithStatus:@"Cancelled"];
	}
	if (self.netService != nil) {
		[self.netService stop];
		self.netService = nil;
	}
	if (self.listeningSocket != NULL) {
		CFSocketInvalidate(self.listeningSocket);
		self.listeningSocket = NULL;
	}
	[self _serverDidStopWithReason:reason];
}

// 接收端完成关闭，这里做显示性工作。
- (void)_serverDidStopWithReason:(NSString *)reason
{
	if (reason == nil) {
		reason = @"Stopped";
	}
}

- (void)dealloc
{
	[self _stopServer:nil];
	
	[super dealloc];
}

#pragma mark 属性的Getter和Setter

- (BOOL)isStarted
{
	return (self.netService != nil);
}

- (BOOL)isReceiving
{
	return (self.networkStream != nil);
}

// Have to write our own setter for listeningSocket because CF gets grumpy 
// if you message NULL.
- (void)setListeningSocket:(CFSocketRef)newValue
{
	if (newValue != self->_listeningSocket) {
		if (self->_listeningSocket != NULL) {
			CFRelease(self->_listeningSocket);
		}
		self->_listeningSocket = newValue;
		if (self->_listeningSocket != NULL) {
			CFRetain(self->_listeningSocket);
		}
	}
}

@end
