//
//  TKTCPSocketRequest.h
//  MTNetworking
//
//  Created by tianmaotao on 2018/5/9.
//  Copyright © 2018年 tianmaotao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TKTCPSocketConfig.h"

@interface TKTCPSocketRequest : NSObject
@property (nonatomic, assign, readonly) TKTCPSocketRequestFunc func; // 目前只区分行情和交易
@property (nonatomic, assign, readonly) NSNumber *requestID; // 发送请求的时候才去生成
@property (nonatomic, assign, readonly) TKTCPSocketRequestType type;

@property (nonatomic, assign) NSUInteger timeoutInterval;
@property (nonatomic, copy) NSDictionary *generalParameters; // 普通参数
@property (nonatomic, copy) NSDictionary *sensitiveParameters; // 敏感参数，如：密码

/**
 *  实例化一个请求对象
 *  @param func 功能模块（确定是交易或者行情的请求）
 *  @param type 请求类型（一次性请求还是重复性请求）
 **/
- (instancetype)initWithFunc:(TKTCPSocketRequestFunc)func type:(TKTCPSocketRequestType)type;
/**
 *  实例化一个请求对象
 *  @param func 功能模块（确定是交易或者行情的请求）
 *  @param type 请求类型（一次性请求还是重复性请求）
 *  @param generalParameters 普通参数列表(⚠️：在交易模块请求时，普通参数列表必须包含"func"字段，否则会报错)
 *  @param sensitiveParameters 敏感参数列表(⚠️：交易模块功能有的需要传入密码敏感信息，如：买入卖出、撤单，这个和c++网络底层部分已经定义好的，不要需要的这个值时，传入会报错的)
 **/
- (instancetype)initWithFunc:(TKTCPSocketRequestFunc)func
                        type:(TKTCPSocketRequestType)type
                     general:(NSDictionary *)generalParameters
                   sensitive:(NSDictionary *)sensitiveParameters;

#pragma mark - interior
- (NSNumber *)createRequestID;
@end
