/*
 *  GLNetworkPrivate.h
 *  ANewMac
 *
 *  Created by Wander See on 10-5-13.
 *  Copyright 2010 Leavesoft Inc. All rights reserved.
 *
 */

// 也许是网络实现必须的类。
#include <sys/socket.h>
#include <netinet/in.h>

#import "GLNetworkService.h"

//#define SOCK_MAXADDRLEN 100
// 这个宏在socket里已经定义过了呢。

enum {
    kSendBufferSize = 32768
};

/*
typedef enum tagMessageType {
	kBubblesDataStateToSend, 
	kBubblesDataStateRecieved
} WDBubblesDataState;
*/

typedef enum tagWDBubblesSendDataType {
	kBubblesSendDataTypeIdentifier, 
	kBubblesSendDataTypeText, 
    kBubblesSendDataTypeImage
} WDBubblesSendDataType;

static NSString * const kNFGLNetworkBasicInfo                   = @"kNFGLNetworkBasicInfo";
static NSString * const kNFGLNetworkBasicInfo_MessageType       = @"kNFGLNetworkBasicInfo_MessageType";
static NSString * const kNFGLNetworkBasicInfo_MessageContent    = @"kNFGLNetworkBasicInfo_MessageContent";

static NSString * const kNSString_Domain                = @"local.";
static NSString * const kNSString_NetServiceType		= @"_x-SNSUpload._tcp.";
static NSString * const kNSString_NetServiceName_Auto	= @"Kira";

//@class GLNetworkService;
