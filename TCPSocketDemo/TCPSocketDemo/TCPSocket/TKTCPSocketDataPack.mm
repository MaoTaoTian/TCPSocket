//
//  TKTCPSocketDataPack.m
//  TakungSports
//
//  Created by tianmaotao on 2018/5/16.
//  Copyright © 2018年 TakungArt(Shanghai)Co.,Ltd. All rights reserved.
//

#import "TKTCPSocketDataPack.h"
#include "client/backend/tkat.client.backend.data/pinvoke.h"
#include "client/backend/tkat.client.backend.data/pinvoke-transaction-data.h"
#include "client/backend/tkat.client.backend.data/pinvoke-transaction-datapack.h"
#include "client/backend/tkat.client.backend.pinvoke/internal/common.h"

@interface TKTCPSocketDataPack ()
@property (nonatomic, assign) TKTransactionDataPack dataPack;
@end

@implementation TKTCPSocketDataPack
- (void)dealloc {
    transaction_data_handle_t data_handle = (transaction_data_handle_t)self.dataPack;
    transaction_datapack_free(data_handle);
}

- (instancetype)initWithDataPack:(TKTransactionDataPack)dataPack {
    if (self = [super init]) {
        self.dataPack = dataPack;
        self.count = transaction_datapack_get_records_count(self.dataPack);
    }
    
    return self;
}

- (NSArray *)values:(NSArray<NSString *> *)keys {
    if (keys.count == 0) {
        return nil;
    }
    
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:self.count];
    for (int i = 0; i < self.count; i++) {
        NSDictionary *dic = [self values:keys index:i];
        if (dic) {
            [array addObject:dic];
        }
    }
    
    return array;
}

- (NSDictionary *)values:(NSArray<NSString *> *)keys index:(NSInteger)index {
    if (keys.count == 0 || index >= self.count) {
        return nil;
    }
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] initWithCapacity:keys.count];
    for (NSString *key in keys) {
        NSString *value = [self value:key index:index];
        [dic setValue:value forKey:key];
    }
    
    return dic;
}

- (NSString *)value:(NSString *)key index:(NSInteger)index {
    if (TKStringIsEmpty(key) || index < 0 || index >= self.count) {
        return nil;
    }
    
    const_transaction_data_handle_t first_data_handle = transaction_datapack_get_record(self.dataPack, index);
    char const *value_c = transaction_data_get_string(first_data_handle, [key UTF8String], key.length);
    
    NSString *value = nil;
    if (value_c != NULL) {
        value = [NSString stringWithUTF8String:value_c];
    }
    
    void *value_c_ = (void *)value_c;
    tkat::client::pinvoke::free_memory(value_c_);
    
    return value;
}

@end
