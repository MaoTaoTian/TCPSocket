//
//  TKTCPDataFormatter.m
//  MTNetworking
//
//  Created by tianmaotao on 2018/5/9.
//  Copyright © 2018年 tianmaotao. All rights reserved.
//

#import "TKTCPDataFormatter.h"

static NSInteger tkat_string_length(NSString *str) {return str.length;}
static unsigned int tkat_string_length_unint(NSString *str) {return (unsigned int)str.length;}
static const char *tkat_string_c(NSString *str) {return [str UTF8String];}

#define transaction_handle_set_string(key, value)\
  transaction_data_set_string(tdata_handle, tkat_string_c(key), tkat_string_length(key), tkat_string_c(value), tkat_string_length(value))

#define transaction_handle_set_bytes(key, value)                                                              \
  std::uint32_t esize = 0;                                                                                    \
  const unsigned char *sensitiveValue = encrypt_string(tkat_string_c(value), tkat_string_length_unint(value), &esize);\
  transaction_data_set_bytes(tdata_handle, tkat_string_c(key), tkat_string_length(key), sensitiveValue, esize); \


@implementation TKTCPDataFormatter
#pragma mark - request data formatter
+ (transaction_data_handle_t)transactonDataFormatterGeneral:(NSDictionary *)parameters {
    NSArray *keys = [parameters allKeys];
    if (keys.count <= 0) {
        return NULL;
    }
    
    transaction_data_handle_t tdata_handle = transaction_data_new();
    return [TKTCPDataFormatter transactonDataFormatterGeneral:tdata_handle parameters:parameters];
}

+ (transaction_data_handle_t)transactonDataFormatterGeneral:(transaction_data_handle_t)tdata_handle parameters:(NSDictionary *)parameters {
    if (tdata_handle == NULL) {
        return NULL;
    }
    
    NSArray *keys = [parameters allKeys];
    if (keys.count <= 0) {
        return NULL;
    }
    
    for (NSString *key in keys) {
        NSString *value = parameters[key];
        transaction_handle_set_string(key, value);
    }
    
    return tdata_handle;
}

+ (transaction_data_handle_t)transactonDataFormatterSensitive:(transaction_data_handle_t)tdata_handle parameters:(NSDictionary *)parameters {
    if (tdata_handle == NULL) {
        return NULL;
    }
    
    NSArray *keys = [parameters allKeys];
    if (keys.count <= 0) {
        return NULL;
    }
    
    for (NSString *key in keys) {
        NSString *value = parameters[key];
        transaction_handle_set_bytes(key, value);
    }
    
    return tdata_handle;
}

#pragma mark - response data formatter

@end
