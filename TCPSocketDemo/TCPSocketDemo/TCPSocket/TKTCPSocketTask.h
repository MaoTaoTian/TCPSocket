//
//  TKTCPSocketTask.h
//  MTNetworking
//
//  Created by tianmaotao on 2018/5/9.
//  Copyright © 2018年 tianmaotao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TKTCPSocketConfig.h"

@class TKTCPSocketClient;
@class TKTCPSocketRequest;
@interface TKTCPSocketTask : NSObject
@property (nonatomic, assign, readonly) TKTCPSocketTaskState state; // 任务的状态
@property (nonatomic, assign, readonly) TKTCPSocketTaskType type; // 任务的类型，根据初始化时传入的请求对象确定
@property (nonatomic, strong) NSNumber *requestID;

@property (nonatomic, copy, readonly) TKTCPSocketTaskSuccessHander completionHandler;
@property (nonatomic, copy, readonly) TKTCPSocketTaskFailureHander failureHandler;
/**
 *  实例化一个任务
 *  @param request 请求对象
 *  @param success 任务成功回调
 *  @param failure 任务失败回调
 **/
- (instancetype)initWithRequest:(TKTCPSocketRequest *)request
              completionHandler:(TKTCPSocketTaskSuccessHander)success
                        failure:(TKTCPSocketTaskFailureHander)failure;

- (void)cancel;
- (void)resume;

- (TKTCPSocketRequest *)socketRequect;

#pragma mark - interior
-(void)client:(TKTCPSocketClient *)client;
- (void)updateTaskState:(TKTCPSocketTaskState)state;
- (void)successed;
- (void)createRequestID;
@end
