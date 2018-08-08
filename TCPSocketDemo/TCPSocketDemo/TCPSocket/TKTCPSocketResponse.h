//
//  TKTCPSocketResponse.h
//  MTNetworking
//
//  Created by tianmaotao on 2018/5/9.
//  Copyright © 2018年 tianmaotao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TKTCPSocketDataPack.h"

@interface TKTCPSocketResponse : NSObject
@property (nonatomic, strong) NSNumber *requestID;
@property (nonatomic, strong) TKTCPSocketDataPack *dataPack;
@end
