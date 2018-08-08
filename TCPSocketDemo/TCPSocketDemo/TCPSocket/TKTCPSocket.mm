//
//  TKTCPSocket.m
//  MTNetworking
//
//  Created by tianmaotao on 2018/5/9.
//  Copyright © 2018年 tianmaotao. All rights reserved.
//

#import "TKTCPSocket.h"
#import "TKTCPSocketClient.h"
#import "TKTCPSocketResponse.h"
#import "TKTCPSocketDataPack.h"

#include "client/backend/tkat.client.backend.data/pinvoke.h"
#include "client/backend/tkat.client.backend.pinvoke/internal/common.h"
#include "client/backend/tkat.client.backend.data/pinvoke-transaction-datapack.h"


static NSString *TCP_SOCKET_QUOTATION_CONNECTED = @"tcp_socket_quotation_connected";
static NSString *TCP_SOCKET_QUOTATION_DISCONNECTED = @"tcp_socket_quotation_disconnected";
static NSString *TCP_SOCKET_QUOTATION_DATA_READY = @"tcp_socket_quotation_data_ready";

static NSString *TCP_SOCKET_TRANSACTION_CONNECTED = @"tcp_socket_transaction_connected";
static NSString *TCP_SOCKET_TRANSACTION_DISCONNECTED = @"tcp_socket_transaction_disconnected";
static NSString *TCP_SOCKET_TRANSACTION_DATA_READY = @"tcp_socket_transaction_data_ready";

@interface TKTCPSocket()
@property (nonatomic, weak) TKTCPSocketClient *socketClient;
@property (nonatomic, assign) BOOL isConfiguration;
@end

@implementation TKTCPSocket
#pragma mark -
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)initWithClient:(TKTCPSocketClient *)socketClient type:(TKTCPSocketType)type {
    if (self = [super init]) {
        _type = type;
        _state = TKTCPSocketStateNone;
        self.socketClient = socketClient;
        self.isConfiguration = NO;
    }
    
    return self;
}

- (void)configuration {
    if (!self.isConfiguration) {
        [self registerSocketCallBack];
        [self registerNotificationCallBack];
        
        self.isConfiguration = !self.isConfiguration;
    }
}

- (void)registerSocketCallBack {
    // 注意⚠️：行情和交易的回调重复注册会导致多次调用!!!!!!!!!!!!!!!!!!!!!!
    switch (_type) {
        case TKTCPSocketTypeQuotation:
            subscribe_quotation_connected(&on_exchange_connected);
            subscribe_quotation_disconnected(&on_exchange_disconnected);
            subscribe_quotation_timeout(&on_exchange_timeout);
            subscribe_quotation_data_ready(&on_quotation_data_ready);
            break;
            
        case TKTCPSocketTypeTransaction:
            subscribe_transaction_data_ready(&on_transaction_data_ready);
            subscribe_transaction_connected(&on_transaction_connected);
            subscribe_transaction_disconnected(&on_transaction_disconnected);
            break;
            
        default:
            // 错误处理
            break;
    }
}

- (void)connect {
    dispatch_queue_t queue = dispatch_queue_create("tkat_tcp_socket_connect", DISPATCH_QUEUE_CONCURRENT);
    dispatch_async(queue, ^{
        // 调用如下函数，现在是c++层的逻辑是，根据c++里边的配置（服务器地址）去连接相应的服务器，目前只有交易服务器和行情服务器，所以调用如下方法实际上交易和行情都会连上
        tkat_connect();
    });
}

- (void)close {
    switch (_type) {
        case TKTCPSocketTypeQuotation:
            disconnect_quotation(1);
            break;
            
        case TKTCPSocketTypeTransaction:
            disconnect_transaction(1);
            break;
            
        default:
            // 错误处理
            break;
    }
}

- (void)reconnect {
    switch (_type) {
        case TKTCPSocketTypeQuotation:
            reconnect_quotation(1);
            break;
            
        case TKTCPSocketTypeTransaction:
            reconnect_transaction(1);
            break;
            
        default:
            // 错误处理
            break;
    }
}

- (BOOL)isConnected {
    return (_state == TKTCPSocketStateConnected) ? YES : NO;;
}

- (BOOL)transactionWriteData:(transaction_data_handle_t)data_handle requestID:(NSNumber *)requestID {
    if (self.type != TKTCPSocketTypeTransaction) {
        return NO;
    }
    
    send_transaction_request(TKAT_EXCHANGE_ID_DEFAULT, [requestID integerValue], data_handle);
    transaction_data_delete(data_handle);
    
    return YES;
}

- (BOOL)quotationWriteData:(NSDictionary *)datas requestID:(NSNumber *)requestID {
    return YES;
}

- (void)updateSocketState:(TKTCPSocketState)state {
    _state = state;
}

#pragma mark -  notification
- (void)registerNotificationCallBack {
    switch (_type) {
        case TKTCPSocketTypeQuotation:
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(connected) name:TCP_SOCKET_QUOTATION_CONNECTED object:nil];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(disconnected) name:TCP_SOCKET_QUOTATION_DISCONNECTED object:nil];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReadData:) name:TCP_SOCKET_QUOTATION_DATA_READY object:nil];
            break;
            
        case TKTCPSocketTypeTransaction:
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(connected) name:TCP_SOCKET_TRANSACTION_CONNECTED object:nil];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(disconnected) name:TCP_SOCKET_TRANSACTION_DISCONNECTED object:nil];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReadData:) name:TCP_SOCKET_TRANSACTION_DATA_READY object:nil];
            break;
            
        default:
            // 错误处理
            break;
    }
}

// socket 连接成功
- (void)connected {
    _state = TKTCPSocketStateConnected;
    if ([self.delegate respondsToSelector:@selector(socketDidConnect:)]) {
        [self.delegate socketDidConnect:self];
    }
}

// socket 连接断开
- (void)disconnected {
    _state = TKTCPSocketStateDisConnected;
    if ([self.delegate respondsToSelector:@selector(socketDidDisconnect:error:)]) {
        [self.delegate socketDidDisconnect:self error:nil];
    }
}

// socket 数据返回
- (void)didReadData:(NSNotification *)notification {
    TKTCPSocketResponse *response = notification.object;
    if ([self.delegate respondsToSelector:@selector(socket:didReadData:)]) {
        [self.delegate socket:self didReadData:response];
    }
}

#pragma mark - quotation callback
TKAT_EXTERN_C
void
__cdecl
on_exchange_connected(tkat::client::network::socket_id_t::value_type const)
{
    TKTCPSocketLog(@"TCPSocket 行情长连接成功");
    [[NSNotificationCenter defaultCenter] postNotificationName:TCP_SOCKET_QUOTATION_CONNECTED object:nil userInfo:nil];
}

TKAT_EXTERN_C
void
__cdecl
on_exchange_disconnected(tkat::data::exchange_id_t::value_type const,
                         std::int32_t const errcode,
                         char_t const *error)
{
    TKTCPSocketLog(@"TCPSocket 行情长连接断开. Error Message:%s", error);
    [[NSNotificationCenter defaultCenter] postNotificationName:TCP_SOCKET_QUOTATION_DISCONNECTED object:nil userInfo:nil];
}

TKAT_EXTERN_C
void
__cdecl
on_exchange_timeout(tkat::data::exchange_id_t::value_type const)
{
    TKTCPSocketLog(@"TCPSocket 行情连接超时");
}

TKAT_EXTERN_C
void
__cdecl
on_quotation_data_ready(tkat::data::exchange_id_t::value_type const exchange_id,
                        tkat::quote::data::sequence_id_t::value_type const sequence_id,
                        tkat::data::request_id_t::value_type const request_id,
                        tkat::quote::data::period_t::value_type const period,
                        tkat::quote::data::quotation_datapack_t const *datapack,
                        tkat::quote::data::data_id_t::value_type const *,
                        std::uint32_t const)
{
    TKTCPSocketLog(@"TCPSocket 行情数据回调");
    [[NSNotificationCenter defaultCenter] postNotificationName:TCP_SOCKET_QUOTATION_DATA_READY object:nil userInfo:nil];
}

#pragma mark - transaction callback
TKAT_EXTERN_C
void
__cdecl
on_transaction_connected(tkat::client::network::socket_id_t::value_type const exchange_id)
{
    TKTCPSocketLog(@"TCPSocket 交易长连接成功");
    [[NSNotificationCenter defaultCenter] postNotificationName:TCP_SOCKET_TRANSACTION_CONNECTED object:nil userInfo:nil];
}

TKAT_EXTERN_C
void
__cdecl
on_transaction_disconnected(tkat::data::exchange_id_t::value_type const exchange_id,
                            std::int32_t const errcode,
                            char_t const *error)
{
    TKTCPSocketLog(@"TCPSocket 交易长连接断开. Error Message:%s", error);
    [[NSNotificationCenter defaultCenter] postNotificationName:TCP_SOCKET_TRANSACTION_DISCONNECTED object:nil userInfo:nil];
}

TKAT_EXTERN_C
void
__cdecl
on_transaction_data_ready(tkat::data::exchange_id_t::value_type const, const_transaction_datapack_handle_t datapack)
{
    TKTCPSocketLog(@"TCPSocket 交易数据回调");
   
    transaction_datapack_handle_t datapack_handle = transaction_datapack_clone(datapack);
    auto request_id = transaction_datapack_get_request_id(datapack_handle);
    
    TKTCPSocketDataPack *dataPack = [[TKTCPSocketDataPack alloc] initWithDataPack:datapack_handle];
    TKTCPSocketResponse *response = [[TKTCPSocketResponse alloc] init];
    
    response.requestID = @(request_id);
    response.dataPack = dataPack;
    
    
    [[NSNotificationCenter defaultCenter] postNotificationName:TCP_SOCKET_TRANSACTION_DATA_READY object:response userInfo:nil];
}

@end
