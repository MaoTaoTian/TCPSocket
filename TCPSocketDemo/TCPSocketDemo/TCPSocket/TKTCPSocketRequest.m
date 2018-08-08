//
//  TKTCPSocketRequest.m
//  MTNetworking
//
//  Created by tianmaotao on 2018/5/9.
//  Copyright © 2018年 tianmaotao. All rights reserved.
//

#import "TKTCPSocketRequest.h"

@interface TKTCPSocketRequest()

@end

@implementation TKTCPSocketRequest
- (instancetype)initWithFunc:(TKTCPSocketRequestFunc)func
                        type:(TKTCPSocketRequestType)type {
    return [[TKTCPSocketRequest alloc] initWithFunc:func type:type general:nil sensitive:nil];
}

- (instancetype)initWithFunc:(TKTCPSocketRequestFunc)func
                        type:(TKTCPSocketRequestType)type
                     general:(NSDictionary *)generalParameters
                   sensitive:(NSDictionary *)sensitiveParameters {
    if (self = [super init]) {
        _func = func;
        _requestID = @(-1);
        _type = type;
        self.timeoutInterval = kDefaultTimeoutInterval;
        
        self.generalParameters = generalParameters;
        self.sensitiveParameters = sensitiveParameters;
    }
    
    return self;
}

- (NSNumber *)createRequestID {
    if (_requestID.integerValue == -1) {
        uint32_t requestID_t = [TKTCPSocketRequest currentRequestIdentifier];
        _requestID = @(requestID_t);
    }
    
    return _requestID;
}

+ (uint32_t)currentRequestIdentifier {
    
    static uint32_t currentRequestID;
    static dispatch_semaphore_t lock;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        currentRequestID = kInitRequestID;
        lock = dispatch_semaphore_create(1);
    });
    
    dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER);
    if (currentRequestID + 1 == 0xffffffff) {
        currentRequestID = kInitRequestID;
    }
    currentRequestID += 1;
    dispatch_semaphore_signal(lock);
    
    return currentRequestID;
}

@end
