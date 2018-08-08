//
//  TKTCPSocketTask.m
//  MTNetworking
//
//  Created by tianmaotao on 2018/5/9.
//  Copyright © 2018年 tianmaotao. All rights reserved.
//

#import "TKTCPSocketTask.h"
#import "TKTCPSocketRequest.h"
#import "TKTCPSocketClient.h"

@interface TKTCPSocketTask()
@property (nonatomic, weak) TKTCPSocketClient *socketClient;
@property (nonatomic, strong) TKTCPSocketRequest *request;
@property (nonatomic, assign) NSUInteger timeoutInterval;
@property (nonatomic, strong) NSTimer *timer;
@end

@implementation TKTCPSocketTask
- (instancetype)initWithRequest:(TKTCPSocketRequest *)request
              completionHandler:(TKTCPSocketTaskSuccessHander)success
                        failure:(TKTCPSocketTaskFailureHander)failure {
    if (self = [self init]) {
        _state = TKTCPSocketTaskStateReady;
        self.request = request;
        _completionHandler = success;
        _failureHandler = failure;
        self.timeoutInterval = self.request.timeoutInterval;
        
        switch (request.type) {
            case TKTCPSocketRequestTypeDisposable:
                _type = TKTCPSocketTaskTypeDisposable;
                break;
            case TKTCPSocketRequestTypeRepeat:
                _type = TKTCPSocketTaskTypeRepeat;
                break;
                
            default:
                break;
        }
    }
    
    return self;
}

- (void)cancel {
    if (self.state == TKTCPSocketTaskStateCompleted) {
        return;
    }
    
    [self.socketClient cancelTaskWithTask:self];
    
    // 终止超时定时器
    [self.timer invalidate];
    self.timer = nil;
}

- (void)successed {
    [self updateTaskState:TKTCPSocketTaskStateCompleted];
    
    // 终止超时定时器
    [self.timer invalidate];
    self.timer = nil;
}

- (void)resume {
    if (self.state != TKTCPSocketTaskStateReady) {return;}
    
    if (self.timer) {
        [self.timer invalidate];
        self.timer = nil;
    }
    
    self.timer = [NSTimer timerWithTimeInterval:self.timeoutInterval target:self selector:@selector(requestTimeout) userInfo:nil repeats:NO];
    [[NSRunLoop mainRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
    
    TKTCPSocketLog(@"Send Request. Task%@.  RequestID = %lu.", self, [self.requestID integerValue]);
    [self.socketClient doActiveTask:self];
}

- (void)requestTimeout {
    //  超时处理
    _state = TKTCPSocketTaskStateCanceled;
    
    NSError *error = TKTCPError(@"请求超时", TKNetworkTaskErrorTimeOut);
    self.failureHandler(error);
    
    [self cancel];
    
    [self.timer invalidate];
    self.timer = nil;
}

- (void)createRequestID {
    [self.request createRequestID];
}

- (NSNumber *)requestID {
    return self.socketRequect.requestID;
}

- (TKTCPSocketRequest *)socketRequect {
    return self.request;
}

-(void)client:(TKTCPSocketClient *)client {
    self.socketClient = client;
}

- (void)updateTaskState:(TKTCPSocketTaskState)state {
    _state = state;
}

@end
