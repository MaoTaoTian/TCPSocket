//
//  TKTCPSocketDataPack.h
//  TakungSports
//
//  Created by tianmaotao on 2018/5/16.
//  Copyright © 2018年 TakungArt(Shanghai)Co.,Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TKTCPSocketConfig.h"

@interface TKTCPSocketDataPack : NSObject
@property (nonatomic, assign) NSInteger count; // 数据条数

- (instancetype)initWithDataPack:(TKTransactionDataPack)dataPack;
/**
 *  返回下标为index数据组中某个key的value
 *  @param key 组数据中某个key
 *  @param index 某组数据的下标
 **/
- (NSString *)value:(NSString *)key index:(NSInteger)index;
/**
 *  返回下标为index数据组中多个key的value
 *  @param keys 组数据中多个keys
 *  @param index 某组数据的下标
 **/
- (NSDictionary *)values:(NSArray<NSString *> *)keys index:(NSInteger)index;
/**
 *  返回下标为index数据组中某个key的value
 *  @param keys 组数据中多个key
 **/
- (NSArray *)values:(NSArray<NSString *> *)keys;
@end
