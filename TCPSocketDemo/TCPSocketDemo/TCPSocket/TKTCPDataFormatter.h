//
//  TKTCPDataFormatter.h
//  MTNetworking
//
//  Created by tianmaotao on 2018/5/9.
//  Copyright © 2018年 tianmaotao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TKTCPSocketConfig.h"
#include "client/backend/tkat.client.backend/pinvoke.h"
#include "client/backend/tkat.client.backend.data/pinvoke.h"
#include "client/backend/tkat.client.backend.data/crypto.h"
#include "shared/tkat.quote.data/quotation-datapack.h"
#include "shared/tkat.transaction.data/command-id.h"
#include "client/backend/tkat.client.backend.pinvoke/pinvoke.h"
#include "client/backend/tkat.client.backend.data/pinvoke-crypto.h"
#include "shared/tkat.quote.data/period.h"
#include "shared/tkat.quote.data/data-id.h"

@interface TKTCPDataFormatter : NSObject
/**
 *  转化普通参数
 *  @param parameters 普通参数字典
 **/
+ (transaction_data_handle_t)transactonDataFormatterGeneral:(NSDictionary *)parameters;
/**
 *  转化普通参数
 *  @param tdata_handle c层参数表示
 *  @param parameters 普通参数字典
 **/
+ (transaction_data_handle_t)transactonDataFormatterGeneral:(transaction_data_handle_t)tdata_handle parameters:(NSDictionary *)parameters;
/**
 *  转化敏感参数
 *  @param tdata_handle c层参数表示
 *  @param parameters 敏感参数字典
 **/
+ (transaction_data_handle_t)transactonDataFormatterSensitive:(transaction_data_handle_t)tdata_handle parameters:(NSDictionary *)parameters;
@end
