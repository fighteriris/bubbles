//
//  WDNetworkController.h
//  Bubbles
//
//  Created by Wander See on 11-4-16.
//  Copyright 2011年 Tongji Apple Club. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <sys/socket.h>
#include <netinet/in.h>

typedef enum tagWDNetworkDataType {
    eNDTText, 
    eNDTImage
} WDNetworkDataType;

@protocol WDNetworkControllerDelegate
- (void)didFindPoint:(NSString *)pointID;
- (void)didReceiveData:(NSData *)data fromPoint:(NSString *)pointID withType:(WDNetworkDataType)dataType;
@end

@interface WDNetworkController : NSObject
<NSNetServiceDelegate> {
    id<WDNetworkControllerDelegate> delegate;
    
    // Send and recieve.
    NSNetService    *netService_;
    uint8_t         recieveBuffer_[SOCK_MAXADDRLEN];
    CFSocketRef     listenSocket_;
    
    // Search.
    NSString *strDomain_;
    NSString *strNetServiceType_;
    NSString *strNetServiceName_;
}

@property (nonatomic, assign) id<WDNetworkControllerDelegate> delegate;
- (void)startServer;
- (void)stopServer:(NSString *)reason;

@end
