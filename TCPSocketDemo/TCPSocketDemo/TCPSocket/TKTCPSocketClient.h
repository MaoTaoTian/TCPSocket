//
//  TKTCPSocketClient.h
//  MTNetworking
//
//  Created by tianmaotao on 2018/5/9.
//  Copyright © 2018年 tianmaotao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TKTCPSocketConfig.h"
#import "TKTCPSocketRequest.h"
#import "TKTCPSocketTask.h"

@interface TKTCPSocketClient : NSObject
+ (instancetype)sharedInstance;

// 根据配置去连接服务器，建议打开应用的时候调用此方法
- (void)configurationServer:(TKTCPSocketServer)server;
/**
 *  创建一个任务
 *  @param request 请求对象
 *  @param success 任务成功回调
 *  @param failure 任务失败回调
 **/
- (TKTCPSocketTask *)dataTaskWithRequest:(TKTCPSocketRequest *)request
                       completionHandler:(TKTCPSocketTaskSuccessHander)success
                                 failure:(TKTCPSocketTaskFailureHander)failure;


// 取消任务；可以取消重复性和不是活动状态的一次性任务
- (void)cancelAllTask;
- (void)cancelTaskWithTask:(TKTCPSocketTask *)task;
- (void)cancelTaskWithRequestID:(NSNumber *)requestID;

- (TKTCPSocketState)quotationState;
- (TKTCPSocketState)transactionState;
- (void)disconnectAll;
- (void)disconnectQuotation;
- (void)disconnectTransaction;

#pragma mark - interior
- (void)doActiveTask:(TKTCPSocketTask *)task;
@end
