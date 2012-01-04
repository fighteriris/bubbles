//
//  WDNetworkController.m
//  Bubbles
//
//  Created by Wander See on 11-4-16.
//  Copyright 2011年 Tongji Apple Club. All rights reserved.
//

#import "WDNetworkController.h"

static NSString * const kWDDomain                = @"local.";
static NSString * const kWDNetServiceType		= @"_x-SNSUpload._tcp.";
static NSString * const kWDNetServiceName_Auto	= @"Kira";

@interface WDNetworkController(Private)
- (void)acceptConnection:(int)fd;
- (void)startServer;
- (void)stopServer:(NSString *)reason;
@end

@implementation WDNetworkController
@synthesize delegate;

#pragma mark - Callbacks

// Called by CFSocket when someone connects to our listening socket.  
// This implementation just bounces the request up to Objective-C.
static void acceptCallback(CFSocketRef s, 
                           CFSocketCallBackType type, 
                           CFDataRef address, 
                           const void *data, 
                           void *info) {
    WDNetworkController * obj;
    obj = (WDNetworkController *)info;
    [obj acceptConnection:*(int *)data];
}

#pragma mark - Network Basic

// 同意接收，说“我愿意”的地方。
- (void)acceptConnection:(int)fd {
    // If we already have a connection, reject this new one.  This is one of the 
	// big simplifying assumptions in this code.  A real server should handle 
	// multiple simultaneous connections.
	// 
    
    // Recieve.
}

- (void)serverDidStartOnPort:(int)port {
	
}

- (int)registerNetworkPort {
    // Create a listening socket and use CFSocket to integrate it into our 
	// runloop.  We bind to port 0, which causes the kernel to give us 
	// any free port, then use getsockname to find out what port number we 
	// actually got.
	BOOL    success;
	int     err;
	int     listenSocket;
	int     port = 0;
	struct sockaddr_in addr;
    
	// socket()
	listenSocket = socket(AF_INET, SOCK_STREAM, 0);
	success = (listenSocket != -1);
	
	// bind()
	if (success) {
		memset(&addr, 0, sizeof(addr));
		addr.sin_len    = sizeof(addr);
		addr.sin_family = AF_INET;
		addr.sin_port   = 0;
		addr.sin_addr.s_addr = INADDR_ANY;
		err = bind(listenSocket, (const struct sockaddr *) &addr, sizeof(addr));
		success = (err == 0);
	}
    
	// listen()
	if (success) {
		err = listen(listenSocket, 5);
		success = (err == 0);
	}
    
	// getsockname(), get the port number.
	if (success) {
		socklen_t   addrLen;
		addrLen = sizeof(addr);
		err = getsockname(listenSocket, (struct sockaddr *)&addr, &addrLen);
		success = (err == 0);
		
		// ntohs(), net work to host.
		if (success) {
			port = ntohs(addr.sin_port);
		}
	}
    
	if (success) {
		// Creat a CFSocket.
		CFSocketContext context = {0, self, NULL, NULL, NULL};
		listenSocket_ = CFSocketCreateWithNative(NULL, 
                                                 listenSocket, 
                                                 kCFSocketAcceptCallBack, 
                                                 acceptCallback, 
                                                 &context);
        success = (listenSocket_ != NULL);
        
        // Add to the run loop.
		if (success) {
			CFRelease(listenSocket_);
            // to balance the create
			listenSocket = -1;
            // listeningSocket is now responsible for closing listenSocket.
			
            CFRunLoopSourceRef  runLoopSource;
			runLoopSource = CFSocketCreateRunLoopSource(NULL, listenSocket_, 0);
			CFRunLoopAddSource(CFRunLoopGetCurrent(), 
                               runLoopSource, 
                               kCFRunLoopDefaultMode);
			CFRelease(runLoopSource);
		}
	}
    
    // Solve all the status here.
    if (success) {
        [self serverDidStartOnPort:port];
        return port;
    } else {
        [self stopServer:@"Start failed"];
        
		if (listenSocket != -1) {
            int junk;
			junk = close(listenSocket);
		}
        
        return 0;
    }
}

#pragma mark - Private Methods

- (void)startServer {
    // Search.
	strDomain_ = kWDDomain;
	strNetServiceType_ = kWDNetServiceType;
	strNetServiceName_ = kWDNetServiceName_Auto;
    
    // Buffer.
	memset(recieveBuffer_, 0, SOCK_MAXADDRLEN);
	
    int registeredPort = [self registerNetworkPort];
    
	// Create the net service.
    netService_ = [[[NSNetService alloc] 
                    initWithDomain:strDomain_ 
                    type:strNetServiceType_ 
                    name:strNetServiceName_ 
                    port:registeredPort] autorelease];
    netService_.delegate = self;
    [netService_ publishWithOptions:NSNetServiceNoAutoRename];
}

// 关闭接收端。
- (void)stopServer:(NSString *)reason {
    if (netService_ != nil) {
		[netService_ stop];
		netService_ = nil;
	}
    
	if (listenSocket_ != NULL) {
		CFSocketInvalidate(listenSocket_);
		listenSocket_ = NULL;
	}
    
	//[self serverDidStopWithReason:reason];
}

#pragma mark - Initial Code

- (id)init {
    if ((self = [super init])) {
        //
        //[self startServer];
    }
    return self;
}

- (void)dealloc {
    [super dealloc];
}

#pragma mark - NSNetServiceDelegate

// Netservice published.
- (void)netServiceDidPublish:(NSNetService *)sender {
    NSLog(@"WDNetwork netServiceDidPublish sender.name: %@.", sender.name);
	// WiTap会用delegate在这里搞自己的gameName。
}

// Netservice not published.
// A NSNetService delegate callback that's called if our Bonjour registration 
// fails.  We respond by shutting down the server.
//
// This is another of the big simplifying assumptions in this sample. 
// A real server would use the real name of the device for registrations, 
// and handle automatically renaming the service on conflicts.  A real 
// client would allow the user to browse for services.  To simplify things 
// we just hard-wire the service name in the client and, in the server, fail 
// if there's a service name conflict.
- (void)netService:(NSNetService *)sender didNotPublish:(NSDictionary *)errorDict {
	NSLog(@"WDNetwork netServiceDidNotPublish.");
	[self stopServer:@"Registration failed"];
}

@end
