//
//  WDBubbleService.m
//  LearnBonjour
//
//  Created by 王 得希 on 12-1-5.
//  Copyright (c) 2012年 BMW Group ConnectedDrive Lab China. All rights reserved.
//

#import "WDBubble.h"
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>

@implementation NSData (Additions)

- (int)port {
    int port;
    struct sockaddr *addr;
    
    addr = (struct sockaddr *)[self bytes];
    if (addr->sa_family == AF_INET)
        // IPv4 family
        port = ntohs(((struct sockaddr_in *)addr)->sin_port);
    else if (addr->sa_family == AF_INET6)
        // IPv6 family
        port = ntohs(((struct sockaddr_in6 *)addr)->sin6_port);
    else
        // The family is neither IPv4 nor IPv6. Can't handle.
        port = 0;
    
    return port;
}


- (NSString *)host {
    struct sockaddr *addr = (struct sockaddr *)[self bytes];
    if (addr->sa_family == AF_INET) {
        char *address = inet_ntoa(((struct sockaddr_in *)addr)->sin_addr);
        if (address)
            return [NSString stringWithCString:address encoding:NSUTF8StringEncoding];
    } else if (addr->sa_family == AF_INET6) {
        struct sockaddr_in6 *addr6 = (struct sockaddr_in6 *)addr;
        char straddr[INET6_ADDRSTRLEN];
        inet_ntop(AF_INET6, &(addr6->sin6_addr), straddr, sizeof(straddr));
        return [NSString stringWithCString:straddr encoding:NSUTF8StringEncoding];
    }
    return nil;
}

@end

@implementation WDBubble
@synthesize service, browser, socketListen, socketSender, servicesFound = _servicesFound;
@synthesize delegate;

#pragma mark - Private Methods

- (void)resolveService:(NSNetService *)s {
    s.delegate = self;
    [s resolveWithTimeout:0];
}

- (void)connectService:(NSNetService *)s {
    //const void *d = [[sender.addresses objectAtIndex:0] bytes];
    //const struct sockaddr_in *a = (const struct sockaddr_in *)d;
    NSData *t = [s.addresses objectAtIndex:0];
    DLog(@"WDBubble connectService %@ addr %@:%i", s, [t host], [t port]);
    DLog(@"WDBubble connectService sender %@:%i", s.name, s.port);
    [self.socketSender connectToHost:[t host] onPort:[t port] error:nil];
}

#pragma mark - Publice Methods

- (void)initSocket {
    DLog(@"WDBubbleService initSocket");
    
    _currentMessage = nil;
    _dataBuffer = nil;
    
    // DW: accepts connections, creates new sockets to connect incoming sockets.
    self.socketListen = [[AsyncSocket alloc] init];
    self.socketListen.delegate = self;
    [self.socketListen acceptOnPort:0 error:nil];
    
    // DW: connect to remote sockets (which are created by remote's "socketListen") and send them data.
    self.socketSender = [[AsyncSocket alloc] init];
    self.socketSender.delegate = self;
}

- (void)publishService {
    DLog(@"WDBubbleService publishService <%@>%@ port %i", self.service.name, self.socketListen, self.socketListen.localPort);
    self.service = [[NSNetService alloc] initWithDomain:@""
                                                   type:@"_bubbles._tcp"
                                                   name:[[UIDevice currentDevice] name]
                                                   port:self.socketListen.localPort];
    self.service.delegate = self;
    [self.service publish];
}

- (void)browseServices {
    _servicesFound = [[NSMutableArray alloc] init];
    DLog(@"WDBubbleService browseServices");
    self.browser = [[NSNetServiceBrowser alloc] init];
    self.browser.delegate = self;
    [self.browser searchForServicesOfType:kWebServiceType inDomain:kInitialDomain];
}

- (void)broadcastMessage:(WDMessage *)msg {
    _currentMessage = [msg retain];
    for (NSNetService *s in self.servicesFound) {
        if ([s.name isEqualToString:self.service.name])
            continue;
        
        if ([s.addresses count] <= 0) {
            [s resolveWithTimeout:0];
        } else {
            [self connectService:s];
        }
    }
}

#pragma mark NSNetServiceDelegate

// Publish

- (void)netServiceWillPublish:(NSNetService *)sender {
    DLog(@"NSNetServiceDelegate netServiceWillPublish");
}

- (void)netServiceDidPublish:(NSNetService *)sender {
    DLog(@"NSNetServiceDelegate netServiceDidPublish %@, %i", self.service, self.service.port);
}

- (void)netService:(NSNetService *)sender didNotPublish:(NSDictionary *)errorDict {
    DLog(@"NSNetServiceDelegate netService didNotPublish code: %@, domain: %@.", 
         [errorDict objectForKey:NSNetServicesErrorCode], 
         [errorDict objectForKey:NSNetServicesErrorDomain]);
}

// Resolve

- (void)netServiceDidResolveAddress:(NSNetService *)sender {
    //[self connectService:sender];
}

#pragma mark AsyncSocketDelegate

- (void)onSocket:(AsyncSocket *)sock didAcceptNewSocket:(AsyncSocket *)newSocket {
    DLog(@"AsyncSocketDelegate didAcceptNewSocket %@: %@", sock, newSocket);
    
    // DW: this "newSocket" is connected to remote's "socketSender", use it to read data then.
    [newSocket readDataWithTimeout:kTimeOut tag:0];
    _dataBuffer = [[NSMutableData alloc] init];
}

- (void)onSocket:(AsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    DLog(@"AsyncSocketDelegate didReadData %@: %@", sock, data);
    [_dataBuffer appendData:data];
    [sock readDataWithTimeout:kTimeOut tag:0];
}

- (void)onSocket:(AsyncSocket *)sock willDisconnectWithError:(NSError *)err {
    DLog(@"AsyncSocketDelegate willDisconnectWithError %@: %@", sock, err);
    [sock readDataWithTimeout:kTimeOut tag:0];
}

- (void)onSocket:(AsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port {
    DLog(@"AsyncSocketDelegate didConnectToHost %@ (l%@, c %@)", sock, self.socketListen, self.socketSender);
    
    // DW: after connected, "socketSender" will send data.
    if ([sock isEqual:self.socketSender]) {
        [sock writeData:_currentMessage.content withTimeout:kTimeOut tag:0];
    }
}

- (void)onSocket:(AsyncSocket *)sock didWriteDataWithTag:(long)tag {
    DLog(@"AsyncSocketDelegate didWriteDataWithTag %@", sock);
    
    // DW: anyone of the two connected sockets call "disconnect" will disconnect the connection. XD
    [sock disconnectAfterWriting];
}

- (void)onSocketDidDisconnect:(AsyncSocket *)sock {
    DLog(@"AsyncSocketDelegate onSocketDidDisconnect %@", sock);
    //[sock disconnectAfterReadingAndWriting];
    
    if (_dataBuffer != nil) {
        [self.delegate didReceiveText:[[NSString alloc] initWithData:_dataBuffer encoding:NSUTF8StringEncoding]];
    }
}

#pragma mark NSNetServiceBrowserDelegate

- (void)netServiceBrowser:(NSNetServiceBrowser *)netServiceBrowser didFindService:(NSNetService *)netService moreComing:(BOOL)moreServicesComing {
    if ([_servicesFound indexOfObject:netService] != NSNotFound) {
        return;
    }
    
    [_servicesFound addObject:netService];
    DLog(@"NSNetServiceBrowserDelegate didFindService %@", self.servicesFound);
    if (![netService.name isEqualToString:self.service.name]) {
        DLog(@"NSNetServiceBrowserDelegate didFindService resolve %@ : %@", netService.name, self.service.name);
        [self resolveService:netService];
    }
}

@end
