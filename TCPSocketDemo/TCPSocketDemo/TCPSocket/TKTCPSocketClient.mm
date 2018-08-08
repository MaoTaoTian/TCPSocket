//
//  TKTCPSocketClient.m
//  MTNetworking
//
//  Created by tianmaotao on 2018/5/9.
//  Copyright © 2018年 tianmaotao. All rights reserved.
//

#import "TKTCPSocketClient.h"
#import "TKTCPSocket.h"
#import "TKTCPDataFormatter.h"
#import "TKTCPSocketResponse.h"

#include "client/backend/tkat.client.backend/pinvoke.h"
#include "client/backend/tkat.client.backend.data/pinvoke.h"

#define TKTCPSocketTaskError(domain, code) \
    NSError *error = TKTCPError(domain, code);\
    task.failureHandler(error);\

@interface TKTCPSocketClient() <TKTCPSocketDelegate>
@property (nonatomic, strong) TKTCPSocket *quotationSocket;
@property (nonatomic, strong) TKTCPSocket *transactionSocket;
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, TKTCPSocketTask *> *readyDispatchTable;
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, TKTCPSocketTask *> *activeDispatchTable;
@end

static dispatch_semaphore_t lock;
@implementation TKTCPSocketClient

#pragma mark -
+ (instancetype)sharedInstance {
    static TKTCPSocketClient *sharedInstance;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        lock = dispatch_semaphore_create(1);
        sharedInstance = [super allocWithZone:NULL];
        [sharedInstance configuration];
        
    });
    
    return sharedInstance;
}

- (void)configuration {
    // 准备就绪任务队列表
    self.readyDispatchTable = [[NSMutableDictionary alloc] init];
    // 活跃任务队列表
    self.activeDispatchTable = [[NSMutableDictionary alloc] init];
}

- (void)configurationServer:(TKTCPSocketServer)server {
    switch (server) {
        case TKTCPSocketServerDefault:
            start();
            [self connectToServer];
            break;
        case TKTCPSocketServerQuotation:
            // 配置行情服务器，现在是c++层代码里边去配置，没有提供接口去配置，所以暂时无效
            break;
        case TKTCPSocketServerTransaction:
            // 配置交易服务器，现在是c++层代码里边去配置，没有提供接口去配置，所以暂时无效
            break;
            
        default:
            break;
    }
}

- (void)connectToServer {
    if (self.quotationSocket.state == TKTCPSocketStateNone && self.transactionSocket.state == TKTCPSocketStateNone) {
        // 此处只需要调用交易或者行情socket其中一个连接即可，因为c++层会自动去连接交易和行情服务器的
        [self.transactionSocket connect];
        
        [self.transactionSocket configuration];
        [self.quotationSocket configuration];
    }
}

#pragma mark - task
- (TKTCPSocketTask *)dataTaskWithRequest:(TKTCPSocketRequest *)request
                       completionHandler:(TKTCPSocketTaskSuccessHander)success
                                 failure:(TKTCPSocketTaskFailureHander)failure {
    
    __weak TKTCPSocketClient *weakSelf = self;
    __block NSNumber *requestID;
    TKTCPSocketTask *task = [[TKTCPSocketTask alloc] initWithRequest:request completionHandler:^(TKTCPSocketResponse *response) {
       
        dispatch_queue_t main_queue = dispatch_get_main_queue();;
        dispatch_async(main_queue, ^{
            success(response);
            [weakSelf taskCompletionWithRequestID:requestID];
        });
        
    } failure:^(NSError *error) {
        
        dispatch_queue_t main_queue = dispatch_get_main_queue();;
        dispatch_async(main_queue, ^{
            failure(error);
        });
    }];
    
    [task createRequestID];
    [task client:self];
    
    requestID = task.requestID;

    // 添加到就绪队列中
    [self addReadySocketTask:task];
    
    return task;
}

- (void)doActiveTask:(TKTCPSocketTask *)task {
    // 检查socket连接状态
    switch (task.socketRequect.func) {
        case TKTCPSocketRequestFuncQuotation:
            if (![self isConnected:TKTCPSocketTypeQuotation]) {
                // 任务强制取消
                [task cancel];
                
                NSString *domain = [NSString stringWithFormat:@"行情Socket未连接. Task[%p].", task];
                TKTCPSocketTaskError(domain, TKNetworkTaskErrorSendFailure);
                return;
            }
            break;
        case TKTCPSocketRequestFuncTransaction:
            if (![self isConnected:TKTCPSocketTypeTransaction]) {
                // 任务强制取消
                [task cancel];
                
                NSString *domain = [NSString stringWithFormat:@"交易Socket未连接. Task[%p.]", task];
                TKTCPSocketTaskError(domain, TKNetworkTaskErrorSendFailure);
                return;
            }
            break;
            
        default:
            break;
    }
    
    // 检查请求参数中是否包含func字段
    NSString *funcValue = task.socketRequect.generalParameters[@"func"];
    if (TKStringIsEmpty(funcValue)) {
        // 任务强制取消
        [task cancel];
        
        NSString *domain = [NSString stringWithFormat:@"Task[%p]. Request的func字段不存在？", task];
        TKTCPSocketTaskError(domain, TKNetworkTaskErrorSendFailure);
        return;
    }
    
    // 检查requestID是否生成
    if (task.requestID.integerValue == -1) {
        // 任务强制取消
        [task cancel];
        
        NSString *domain = [NSString stringWithFormat:@"Task[%p]. RequestID生成失败.", task];
        TKTCPSocketTaskError(domain, TKNetworkTaskErrorSendFailure);
        return;
    }
    
    // 检查一次性任务是否在就绪队列中（重复性任务不必）
    if (task.type == TKTCPSocketTaskTypeDisposable && ![self inReadyDispatchTableWithTask:task]) {
        // 任务强制取消
        [task cancel];
        
        NSString *domain = [NSString stringWithFormat:@"Task[%p]不在就绪队列中.", task];
        TKTCPSocketTaskError(domain, TKNetworkTaskErrorSendFailure);
        return;
    }
    
    // 区分是一次性任务还是重复性任务
    switch (task.type) {
        case TKTCPSocketTaskTypeDisposable:
            // 一次性任务处理
            [self sendRequestDisposableWithTask:task];
            break;
            
        case TKTCPSocketTaskTypeRepeat:
            // 重复性任务处理
            [self sendRequestRepeatWithTask:task];
            break;
            
        default:
            // 任务强制取消
            [task cancel];
            
            NSString *domain = [NSString stringWithFormat:@"Task[%p]类型无法确认.", task];
            TKTCPSocketTaskError(domain, TKNetworkTaskErrorSendFailure);
            break;
    }
}

// 取消所有任务
- (void)cancelAllTask {
    // 准备就绪任务取消
    for (TKTCPSocketTask *task in self.readyDispatchTable) {
        [self cancelTaskWithTask:task];
    }
    
    // 活跃任务取消
    for (TKTCPSocketTask *task in self.activeDispatchTable) {
        [self cancelTaskWithTask:task];
    }
}

// 根据requestID取消任务
- (void)cancelTaskWithRequestID:(NSNumber *)requestID {
    if ([self inActiveDispatchTableWithRequestID:requestID]) {
        TKTCPSocketTask *task = [self task:self.activeDispatchTable requestID:requestID];
        [self cancelTaskWithTask:task];
        
    } else if ([self inReadyDispatchTableWithRequestID:requestID]) {
        TKTCPSocketTask *task = [self task:self.readyDispatchTable requestID:requestID];
        [self cancelTaskWithTask:task];
        
    }
}

// 根据task取消任务
- (void)cancelTaskWithTask:(TKTCPSocketTask *)task {
    // 根据指定task取消任务
    switch (task.type) {
        case TKTCPSocketTaskTypeDisposable:
            [self cancelDisposableTask:task];
            break;
        case TKTCPSocketTaskTypeRepeat:
            [self cancelRepeatTask:task];
            break;
            
        default:
            break;
    }
    
    [task updateTaskState:TKTCPSocketTaskStateCanceled];
}

// 取消一次性任务
- (void)cancelDisposableTask:(TKTCPSocketTask *)task {
    if (task.state == TKTCPSocketTaskStateReady) {
        [self removeReadySocketTaskWithRequestID:task.requestID];
    } else {
        [self removeActiveSocketTaskWithRequestID:task.requestID];
    }
    // 交易和行情取消后，这个地方可能需要各自区分处理，如：行情需要注销掉推送任务
    // ..........
}

// 取消重复性任务
- (void)cancelRepeatTask:(TKTCPSocketTask *)task {
    if (task.state == TKTCPSocketTaskStateReady) {
        [self removeReadySocketTaskWithRequestID:task.requestID];
    } else {
        [self removeActiveSocketTaskWithRequestID:task.requestID];
    }
    // 交易和行情取消后，这个地方可能需要各自区分处理，如：行情需要注销掉推送任务
    // ..........
}

// 任务完成后续处理
- (void)taskCompletionWithRequestID:(NSNumber *)requestID {
    TKTCPSocketTask *task = [self taskAtActiveDispatchTableWithRequestID:requestID];
    
    if (task.type == TKTCPSocketTaskTypeDisposable) {
        [task successed];
        [self removeActiveSocketTaskWithRequestID:task.requestID];
    }
}

#pragma mark - request
// 发送一次性任务请求
- (void)sendRequestDisposableWithTask:(TKTCPSocketTask *)task {
    switch (task.socketRequect.func) {
        case TKTCPSocketRequestFuncQuotation:
            [self sendRequestDisposableQuotationWithTask:task];
            break;
            
        case TKTCPSocketRequestFuncTransaction:
            [self sendRequestDisposableTransactionWithTask:task];
            break;
            
        default:
            break;
    }
}

// 发送重复性任务请求
- (void)sendRequestRepeatWithTask:(TKTCPSocketTask *)task {
    switch (task.socketRequect.func) {
        case TKTCPSocketRequestFuncQuotation:
            [self sendRequestRepeatQuotationWithTask:task];
            break;
            
        case TKTCPSocketRequestFuncTransaction:
            [self sendRequestRepeatTransactionWithTask:task];
            break;
            
        default:
            break;
    }
}

// 一次性任务交易请求
- (void)sendRequestDisposableTransactionWithTask:(TKTCPSocketTask *)task {
    TKTCPSocketRequest *request = [task socketRequect];
    
    if (!request) {
        // 任务强制取消
        [task cancel];
        
        NSString *domain = [NSString stringWithFormat:@"Task[%p]Request不存在.", task];
        TKTCPSocketTaskError(domain, TKNetworkTaskErrorSendFailure);
        return;
    }
    
    transaction_data_handle_t tdata_handle = [TKTCPDataFormatter transactonDataFormatterGeneral:request.generalParameters];
    
    if (request.sensitiveParameters) {
        // 有敏感参数
        tdata_handle = [TKTCPDataFormatter transactonDataFormatterSensitive:tdata_handle parameters:request.sensitiveParameters];
    }
   
    if (tdata_handle == NULL) {
        // 任务强制取消
        [task cancel];
        
        NSString *domain = [NSString stringWithFormat:@"Task[%p]. Request[%p]. 请求参数出错!", task, request];
        TKTCPSocketTaskError(domain, TKNetworkTaskErrorSendFailure);
        
        transaction_data_delete(tdata_handle);
        return;
    }
    
    if ([self.transactionSocket transactionWriteData:tdata_handle requestID:request.requestID]) {
        [self sendRequestSuccessed:task];
    }
}

// 一次性任务行情请求
- (void)sendRequestDisposableQuotationWithTask:(TKTCPSocketTask *)task {
    // 行情相关请求在c++层是通过预定义好参数ID，在本层网络接口设计中，参数全部通过字符串的key-value形式，所以这个地方发送请求前，需要把字符串参数映射到c++层定义好的参数ID
    // ..........
}

// 重复性交易请求
- (void)sendRequestRepeatTransactionWithTask:(TKTCPSocketTask *)task {
    // 交易暂时还没有重复性任务
    // ..........
}

// 重复性行情请求
- (void)sendRequestRepeatQuotationWithTask:(TKTCPSocketTask *)task {
    // 行情相关请求在c++层是通过预定义好参数ID，在本层网络接口设计中，参数全部通过字符串的key-value形式，所以这个地方发送请求前，需要把字符串参数映射到c++层定义好的参数ID
    // ..........
}

// 任务请求成功后续处理
- (void)sendRequestSuccessed:(TKTCPSocketTask *)task {
    [task updateTaskState:TKTCPSocketTaskStateActive];
    
    [self addActiveSocketTask:task];
    
    [self removeReadySocketTaskWithRequestID:task.requestID];
}

#pragma mark - DispatchTable
- (BOOL)addActiveSocketTask:(TKTCPSocketTask *)task {
    return [self addSocketTask:task dispatchTable:self.activeDispatchTable];
}

- (BOOL)addReadySocketTask:(TKTCPSocketTask *)task {
    return [self addSocketTask:task dispatchTable:self.readyDispatchTable];
}

- (BOOL)addSocketTask:(TKTCPSocketTask *)task dispatchTable:(NSMutableDictionary *)dispatchTable {
    if (!task || task.requestID == nil) {
        return NO;
    }
    
    dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER);
    [dispatchTable setObject:task forKey:task.requestID];
    dispatch_semaphore_signal(lock);
    return YES;
}

- (BOOL)removeActiveAllTask {
    // 移除未就绪的任务
    dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER);
    [self.readyDispatchTable removeAllObjects];
    
    // 移除重复性活动的任务
    for (TKTCPSocketTask *taskTemp in self.activeDispatchTable) {
        if (taskTemp.type == TKTCPSocketTaskTypeRepeat) {
            [self removeActiveSocketTaskWithRequestID:taskTemp.requestID];
        }
    }
    dispatch_semaphore_signal(lock);
    
    return YES;
}

- (BOOL)removeActiveSocketTaskWithRequestID:(NSNumber *)requestID {
    return [self removeSocketTaskWithRequestID:requestID dispatchTable:self.activeDispatchTable];
}

- (BOOL)removeReadySocketTaskWithRequestID:(NSNumber *)requestID {
    return [self removeSocketTaskWithRequestID:requestID dispatchTable:self.readyDispatchTable];
}

- (BOOL)removeSocketTaskWithRequestID:(NSNumber *)requestID dispatchTable:(NSMutableDictionary *)dispatchTable {
    if (requestID == nil) {
        return NO;
    }
    
    dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER);
    [dispatchTable removeObjectForKey:requestID];
    dispatch_semaphore_signal(lock);
    
    return YES;
}

- (BOOL)inReadyDispatchTableWithTask:(TKTCPSocketTask *)task {
    NSArray *keys = [self.readyDispatchTable allKeys];
    for (NSNumber *key in keys) {
        TKTCPSocketTask *taskTemp = self.readyDispatchTable[key];
        if (taskTemp.requestID.integerValue == task.requestID.integerValue) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)inReadyDispatchTableWithRequestID:(NSNumber *)requestID {
    NSArray *keys = [self.readyDispatchTable allKeys];
    for (NSNumber *key in keys) {
        TKTCPSocketTask *taskTemp = self.readyDispatchTable[key];
        if (taskTemp.requestID.integerValue == [requestID integerValue]) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)inActiveDispatchTableWithTask:(TKTCPSocketTask *)task {
    NSArray *keys = [self.activeDispatchTable allKeys];
    for (NSNumber *key in keys) {
        TKTCPSocketTask *taskTemp = self.activeDispatchTable[key];
        if (taskTemp.requestID.integerValue == task.requestID.integerValue) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)inActiveDispatchTableWithRequestID:(NSNumber *)requestID {
    NSArray *keys = [self.activeDispatchTable allKeys];
    for (NSNumber *key in keys) {
        TKTCPSocketTask *taskTemp = self.activeDispatchTable[key];
        if (taskTemp.requestID.integerValue == [requestID integerValue]) {
            return YES;
        }
    }
    return NO;
}

// 根据requestID返回准备就绪队列中的task
- (TKTCPSocketTask *)taskAtReadyDispatchTableWithRequestID:(NSNumber *)requestID{
    return [self task:self.readyDispatchTable requestID:requestID];
}

// 根据requestID返回活跃队列中的task
- (TKTCPSocketTask *)taskAtActiveDispatchTableWithRequestID:(NSNumber *)requestID{
    return [self task:self.activeDispatchTable requestID:requestID];
}

- (TKTCPSocketTask *)task:(NSDictionary<NSNumber *, TKTCPSocketTask *> *)dispatchTable requestID:(NSNumber *)requestID {
    NSArray *keys = dispatchTable.allKeys;
    if (keys.count <= 0) {
        return nil;
    }
    
    for (NSNumber *key in keys) {
        TKTCPSocketTask *task = self.activeDispatchTable[key];
        if (task.requestID.integerValue == [requestID integerValue]) {
            return task;
        }
    }
    
    return nil;
}

#pragma mark - socket
- (TKTCPSocketState)quotationState {
    return self.quotationSocket.state;
}

- (TKTCPSocketState)transactionState {
    return self.transactionSocket.state;
}

- (void)disconnectAll {
    [self disconnectQuotation];
    [self disconnectTransaction];
}

- (void)disconnectQuotation {
    if (self.quotationSocket.state == TKTCPSocketStateConnected) {
        [self.quotationSocket close];
    }
}

- (void)disconnectTransaction {
    if (self.transactionSocket.state == TKTCPSocketStateConnected) {
         [self.transactionSocket close];
    }
}

- (BOOL)isConnected:(TKTCPSocketType)type {
    switch (type) {
        case TKTCPSocketTypeQuotation:
            return self.quotationSocket.state == TKTCPSocketStateConnected ? YES : NO;
            break;
        case TKTCPSocketTypeTransaction:
            return self.transactionSocket.state == TKTCPSocketStateConnected ? YES : NO;
            break;
            
        default:
            break;
    }
    return NO;
}

#pragma mark - TKTCPSocketDelegate
- (void)socketDidConnect:(TKTCPSocket *)sock {
    // socket成功连上
}

- (void)socketCanNotConnectToService:(TKTCPSocket *)sock {
    // socket未连接
}

- (void)socketDidDisconnect:(TKTCPSocket *)sock error:(NSError *)error {
    // socket断开连接
}

- (void)socket:(TKTCPSocket *)sock didReadData:(TKTCPSocketResponse *)response {
    // socket数据返回
    @autoreleasepool {
        NSNumber *requestID = response.requestID;
        TKTCPSocketTask *task = [self taskAtActiveDispatchTableWithRequestID:requestID];
        
        if (!task) {
            NSString *domain = [NSString stringWithFormat:@"RequestID = %lu. 任务已经取消或者不在活跃队列中.", [requestID integerValue]];
            TKTCPSocketLog(@"%@", domain);
            return;
        }
        
        task.completionHandler(response);
    }
}

#pragma mark -
- (TKTCPSocket *)quotationSocket {
    if (!_quotationSocket) {
        _quotationSocket = [[TKTCPSocket alloc] initWithClient:self type:TKTCPSocketTypeQuotation];
        _quotationSocket.delegate = self;
    }
    
    return _quotationSocket;
}

- (TKTCPSocket *)transactionSocket {
    if (!_transactionSocket) {
        _transactionSocket = [[TKTCPSocket alloc] initWithClient:self type:TKTCPSocketTypeTransaction];
        _transactionSocket.delegate = self;
    }
    
    return _transactionSocket;
}
@end
