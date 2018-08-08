//
//  TKTCPSocketConfig.h
//  TakungSports
//
//  Created by tianmaotao on 2018/5/15.
//  Copyright © 2018年 TakungArt(Shanghai)Co.,Ltd. All rights reserved.
//

#ifndef TKTCPSocketConfig_h
#define TKTCPSocketConfig_h

/************************************* Server ***************************************/
typedef enum : NSUInteger {
#ifdef DEBUG
    TKTCPSocketServerDefault = 100,
    TKTCPSocketServerQuotation = 101,
    TKTCPSocketServerTransaction = 102,
#else
    TKTCPSocketServerDefault = 200,
    TKTCPSocketServerQuotation = 201,
    TKTCPSocketServerTransaction = 202,
#endif
} TKTCPSocketServer;



/************************************* Socket ***************************************/
typedef enum : NSUInteger {
    TKTCPSocketTypeNone = 0,
    TKTCPSocketTypeQuotation,
    TKTCPSocketTypeTransaction
} TKTCPSocketType;

typedef enum : NSUInteger {
    TKTCPSocketStateNone = 0,
    TKTCPSocketStateConnected,
    TKTCPSocketStateDisConnected,
} TKTCPSocketState;



/************************************* Request ***************************************/
#define kInitRequestID 0x00000400           // RequestID默认开始递增值
#define kDefaultTimeoutInterval 30          // 默认超时时间

typedef enum : NSUInteger {
    TKTCPSocketRequestFuncNone = 0,
    TKTCPSocketRequestFuncQuotation = 1,     // 行情
    TKTCPSocketRequestFuncTransaction = 2,   // 交易
} TKTCPSocketRequestFunc;

typedef enum : NSUInteger {
    TKTCPSocketRequestTypeNone = 0,
    TKTCPSocketRequestTypeDisposable = 1,     // 一次性请求
    TKTCPSocketRequestTypeRepeat = 2,         // 重复性质请求
} TKTCPSocketRequestType;



/************************************** Task ****************************************/
typedef enum : NSUInteger {
    TKTCPSocketTaskStateReady = 0,                  // 任务准备就绪，未开始
    TKTCPSocketTaskStateActive = 1,                 // 任务进行中
    TKTCPSocketTaskStateCanceled = 2,               // 任务被取消
    TKTCPSocketTaskStateCompleted = 3               // 任务已经完成
} TKTCPSocketTaskState;

typedef enum : NSUInteger {
    TKTCPSocketTaskTypeNone = 0,
    TKTCPSocketTaskTypeDisposable = 1,              // 一次性任务，数据返回后任务失效
    TKTCPSocketTaskTypeRepeat = 2,                  // 重复任务，关闭任务需要手动关闭
} TKTCPSocketTaskType;

typedef enum : NSUInteger {
    TKNetworkTaskErrorSuccess = 1,
    TKNetworkTaskErrorTimeOut = 101,
    TKNetworkTaskErrorCannotConnectedToInternet = 102,
    TKNetworkTaskErrorCanceled = 103,
    TKNetworkTaskErrorDefault = 104,
    TKNetworkTaskErrorNoData = 105,
    TKNetworkTaskErrorNoMoreData = 106,
    TKNetworkTaskErrorSendFailure = 108,
} TKNetworkTaskError;



/************************************** Response ****************************************/
@class TKTCPSocketResponse;
typedef void (^TKTCPSocketTaskSuccessHander)(TKTCPSocketResponse *response);
typedef void (^TKTCPSocketTaskFailureHander)(NSError *  error);



/************************************** Other ****************************************/
#define TKAT_EXCHANGE_ID_DEFAULT 1

typedef void const * TKTransactionDataPack;

static NSError *TKTCPError(NSString *domain, NSInteger code) {
    return [NSError errorWithDomain:domain code:code userInfo:nil];
}



/*************************************** Log *****************************************/
#ifdef DEBUG

#define TKTCPSocketLog(...) NSLog(__VA_ARGS__)
#define TKTCPSocketLocationLog(format, ...) NSLog((@"[文件名:%s]" "[函数名:%s]" "[行号:%d]" format), __FILE__, __FUNCTION__, __LINE__, ##__VA_ARGS__);

#else

#define TKTCPSocketLog(...) {}
#define TKTCPSocketLocationLog(format, ...) {}

#endif

#endif /* TKTCPSocketConfig_h */
