//
//  TKTCPSocket.h
//  MTNetworking
//
//  Created by tianmaotao on 2018/5/9.
//  Copyright © 2018年 tianmaotao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TKTCPSocketConfig.h"

#include "client/backend/tkat.client.backend.data/pinvoke-transaction-datapack.h"

@class TKTCPSocket;
@class TKTCPSocketResponse;
@protocol TKTCPSocketDelegate <NSObject>

@optional
- (void)socketDidConnect:(TKTCPSocket *)sock;
- (void)socketCanNotConnectToService:(TKTCPSocket *)sock;
- (void)socketDidDisconnect:(TKTCPSocket *)sock error:(NSError *)error;
- (void)socket:(TKTCPSocket *)sock didReadData:(TKTCPSocketResponse *)response;

@end

@class TKTCPSocketClient;
@interface TKTCPSocket : NSObject
@property (nonatomic, weak) id<TKTCPSocketDelegate> delegate;

@property (nonatomic, assign, readonly) TKTCPSocketType type;
@property (nonatomic, assign, readonly) TKTCPSocketState state;

@property (nonatomic, assign) NSUInteger maxRetryTime;

- (instancetype)initWithClient:(TKTCPSocketClient *)socketClient type:(TKTCPSocketType)type;
- (void)configuration; // c++层网络库初始化后，才能去调用此方法去配置


- (void)connect;
- (void)close;
- (void)reconnect;

- (BOOL)isConnected;
- (BOOL)transactionWriteData:(transaction_data_handle_t)data_handle requestID:(NSNumber *)requestID;
- (BOOL)quotationWriteData:(NSDictionary *)datas requestID:(NSNumber *)requestID;

- (void)updateSocketState:(TKTCPSocketState)state;
@end
