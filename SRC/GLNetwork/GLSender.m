//
//  Sender.m
//  ANewMac
//
//  Created by Wander See on 10-5-13.
//  Copyright 2010 Leavesoft Inc. All rights reserved.
//

#import "GLSender.h"

@interface GLSender ()

// Properties that don't need to be seen by the outside world.

// 这两个属性是没有被synthesize的。
@property (nonatomic, readonly) BOOL              isSending;
@property (nonatomic, readonly) uint8_t *         buffer;

@property (nonatomic, retain)   NSNetService *    netService;
@property (nonatomic, retain)   NSOutputStream *  networkStream;
@property (nonatomic, retain)   NSInputStream *   fileStream;
@property (nonatomic, assign)   size_t            bufferOffset;
@property (nonatomic, assign)   size_t            bufferLimit;
@property (nonatomic, retain, readwrite) NSNetServiceBrowser *netServiceBrowser;

- (void)_startSend:(void *)data length:(const NSUInteger)length type:(WDBubblesSendDataType)type;
- (void)_sendDidStart;

- (void)_stopSendWithStatus:(NSString *)statusString;
- (void)_sendDidStopWithStatus:(NSString *)statusString;

// NSNetServiceBrowser要用的
- (BOOL)searchForServicesOfType:(NSString *)type inDomain:(NSString *)domain;

@end

@implementation GLSender

@synthesize netService		= _netService;
@synthesize networkStream	= _networkStream;
@synthesize fileStream		= _fileStream;
@synthesize bufferOffset	= _bufferOffset;
@synthesize bufferLimit		= _bufferLimit;
@synthesize netServiceBrowser	= _netServiceBrowser;

@synthesize delegate			= _delegate;

#pragma mark 事件响应

- (void)sendData:(void *)anyData toService:(NSString *)theServiceName {
	_strServiceNameToSend = theServiceName;
	
	NSLog(@"GLSender: sendMessage_ByNSString");
	if (!self.isSending ) {
		//[self _startSend:theString];
	}
}

- (void)sendMessage:(NSString *)theString toServiceName:(NSString *)theServiceName {
	_strServiceNameToSend = theServiceName;
	
	if (self.isSending ) {
		//[self _startSend:theString];
        return;
	}
    
    uint8_t textToSendBuffer[SOCK_MAXADDRLEN] = {0};
	[theString 
	 getBytes:textToSendBuffer 
	 maxLength:SOCK_MAXADDRLEN 
	 usedLength:NULL 
	 encoding:NSUTF8StringEncoding 
	 options:NSStringEncodingConversionAllowLossy 
	 range:NSMakeRange(0, SOCK_MAXADDRLEN) 
	 remainingRange:NULL];
	const NSUInteger actualLengthOfSendingData = [theString lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
    //Domain:@"local." type:@"_x-SNSUpload._tcp."
    NSLog(@"Sender actualLengthOfSendingData: %u.", (unsigned int)actualLengthOfSendingData);
    
    [self _startSend:textToSendBuffer length:actualLengthOfSendingData type:kBubblesSendDataTypeText];
}

- (void)sendImage:(NSData *)theImageData toService:(NSString *)theServiceName {
	_strServiceNameToSend = theServiceName;
	if (self.isSending ) {
		//[self _startSend:theString];
        return;
	}
    
    uint8_t dataBuffer[SOCK_MAXADDRLEN] = {0};
    const NSUInteger dataLength = [theImageData length];
    memcpy(dataBuffer, [theImageData bytes], dataLength);
    [self _startSend:dataBuffer
              length:dataLength 
                type:kBubblesSendDataTypeImage];
    
}

- (void)searchAvaliableServices
{
	[_servicesFound release];
	_servicesFound = [[NSMutableArray alloc] init];
	
	[self searchForServicesOfType:kNSString_NetServiceType inDomain:kNSString_Domain];
}

#pragma mark 协助性的函数

//- (id)init
//{
//	if ([super init] == nil)
//	{
//		return nil;
//	}
//
//	memset(_buffer, 0, kSendBufferSize);
//}

- (void)_updateStatus:(NSString *)statusString
{
	assert(statusString != nil);
}

#pragma mark 不知道是不是来自delegate的

- (void)netServiceDidPublish:(NSNetService *)sender
{
    NSLog(@"GLSender netServiceDidPublish: %@.", sender.name);
}

- (void)netService:(NSNetService *)sender didNotPublish:(NSDictionary *)errorDict
{
	NSLog(@"GLSender netServicedidNotPublish.");
}

#pragma mark 发现网络服务

// Creates an NSNetServiceBrowser that searches for services of a particular type in a particular domain.
// If a service is currently being resolved, stop resolving it and stop the service browser from
// discovering other services.
- (BOOL)searchForServicesOfType:(NSString *)type inDomain:(NSString *)domain
{
	// 不知道为什么，这里改成用属性就可以了！
	
	NSLog(@"GLSender: searchForServicesOfType");
	[self.netServiceBrowser stop];
	
	NSNetServiceBrowser *aNetServiceBrowser = [[NSNetServiceBrowser alloc] init];
	if(!aNetServiceBrowser) {
        // The NSNetServiceBrowser couldn't be allocated and initialized.
		return NO;
	}
	
	aNetServiceBrowser.delegate = self;
	self.netServiceBrowser = aNetServiceBrowser;
	[aNetServiceBrowser release];
	[self.netServiceBrowser searchForServicesOfType:type inDomain:domain];
    
	return YES;
}

- (void)netServiceBrowserWillSearch:(NSNetServiceBrowser *)netServiceBrowser
{
	NSLog(@"GLSender netServiceBrowser will search.");
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)netServiceBrowser didFindService:(NSNetService *)service moreComing:(BOOL)moreComing
{
	NSLog(@"GLSender netServiceBrowser did found service");
    
	// If a service came online, add it to the list and update the table view if no more events are queued.
	[_servicesFound addObject:service.name];
    
    
	NSLog(@"GLSender netServiceBrowser found service name: %@, arrya[0]: %@.", [service name], [_servicesFound objectAtIndex:0]);
	if (!moreComing)
	{
		NSLog(@"GLSender no moreComing.");
		[self.delegate glsenderDidSearchAvaliableServices:_servicesFound];
	}
}

// 不知道这个函数什么时候才会调。我总来没见它调过。
- (void)netServiceBrowser:(NSNetServiceBrowser *)netServiceBrowser didNotSearch:(NSDictionary *)errorInfo
{
	NSLog(@"GLSender netServiceBrowser did not found service");
}

// 不知道这个函数什么时候才会调。我总来没见它调过。
- (void)netServiceBrowserDidStopSearch:(NSNetServiceBrowser *)netServiceBrowser
{
	NSLog(@"GLSender netServiceBrowserDidStopSearch");
	
	NSString * serviceName;
	for (serviceName in _servicesFound)
	{
		NSLog(@"serviceName: %@.", serviceName);
	}
}

#pragma mark 内部逻辑实现

// 开始传输，这里做“启动”工作。
- (void)_startSend:(void *)data length:(const NSUInteger)length type:(WDBubblesSendDataType)type {
	NSOutputStream *    output;
    
    // Wander: 开始传字符串了。
	//memset(textToSendBuffer, 0, SOCK_MAXADDRLEN);
	NSInteger theType = type;
    memcpy(data+length, &theType, sizeof(NSInteger));
    
	self.fileStream = [NSInputStream inputStreamWithData:
					   [NSData dataWithBytes:data length:(length+sizeof(NSInteger))]];
	// 后来发现，其实只要控制好发送端的长度，就不会出现乱码了。
	// 但是，不乱的，上次发送的参与，还是不能做好的。
    
	[self.fileStream open];
	// Open a stream to the server, finding the server via Bonjour.  Then configure 
	// the stream for async operation.
	
	self.netService = [[[NSNetService alloc] 
						initWithDomain:kNSString_Domain 
						type:kNSString_NetServiceType 
						name:_strServiceNameToSend] autorelease];
    [self.netService getInputStream:NULL outputStream:&output];
	
	self.networkStream = output;
	[output release];
	self.networkStream.delegate = self;
	[self.networkStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	[self.networkStream open];
    
    [self _sendDidStart];
}

// 启动工作完成了，在这里设置一些提示性的东西。
- (void)_sendDidStart {
}

// 传输过程，这里是真正意义上的收发数据流。
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
			assert(NO);     // should never happen for the output stream
		} break;
		case NSStreamEventHasSpaceAvailable: {
			[self _updateStatus:@"Sending"];
			
			// If we don't have any data buffered, go read the next chunk of data.
			
			if (self.bufferOffset == self.bufferLimit) {
				NSInteger   bytesRead;
				
				bytesRead = [self.fileStream read:self.buffer maxLength:kSendBufferSize];
				
				if (bytesRead == -1) {
					[self _stopSendWithStatus:@"File read error"];
				} else if (bytesRead == 0) {
					[self _stopSendWithStatus:nil];
				} else {
					self.bufferOffset = 0;
					self.bufferLimit  = bytesRead;
				}
			}
			
			// If we're not out of data completely, send the next chunk.
			
			if (self.bufferOffset != self.bufferLimit) {
				NSInteger   bytesWritten;
				bytesWritten = [self.networkStream write:&self.buffer[self.bufferOffset] maxLength:self.bufferLimit - self.bufferOffset];
				assert(bytesWritten != 0);
				if (bytesWritten == -1) {
					[self _stopSendWithStatus:@"Network write error"];
				} else {
					self.bufferOffset += bytesWritten;
				}
			}
		} break;
		case NSStreamEventErrorOccurred: {
			[self _stopSendWithStatus:@"Stream open error"];
		} break;
		case NSStreamEventEndEncountered: {
			// ignore
		} break;
		default: {
			assert(NO);
		} break;
	}
}

// 结束传输，这里做“收尾”工作。
- (void)_stopSendWithStatus:(NSString *)statusString
{
	if (self.networkStream != nil) {
		self.networkStream.delegate = nil;
		[self.networkStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
		[self.networkStream close];
		self.networkStream = nil;
	}
	if (self.netService != nil) {
		[self.netService stop];
		self.netService = nil;
	}
	if (self.fileStream != nil) {
		[self.fileStream close];
		self.fileStream = nil;
	}
	self.bufferOffset = 0;
	self.bufferLimit  = 0;
	[self _sendDidStopWithStatus:statusString];
}

// 收尾工作完成，在这里提示。对收到的数据的处理也在这里。
- (void)_sendDidStopWithStatus:(NSString *)statusString
{
	if (statusString == nil) {
		statusString = @"Send succeeded";
	}
	
	// 在这里加入传输成功后的代码。
}

- (void)dealloc
{
	[self _stopSendWithStatus:@"Stopped"];
	[_netServiceBrowser stop];
	_netServiceBrowser = nil;
	
	[super dealloc];
}

#pragma mark 属性的Getter和Setter

// Because buffer is declared as an array, you have to use a custom getter.  
// A synthesised getter doesn't compile.
- (uint8_t *)buffer
{
	return self->_buffer;
}

- (BOOL)isSending
{
	return (self.networkStream != nil);
}

@end
