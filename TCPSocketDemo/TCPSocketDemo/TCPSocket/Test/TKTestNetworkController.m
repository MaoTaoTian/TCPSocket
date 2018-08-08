//
//  TKTestNetworkController.m
//  TakungSports
//
//  Created by tianmaotao on 2018/5/15.
//  Copyright © 2018年 TakungArt(Shanghai)Co.,Ltd. All rights reserved.
//

#import "TKTestNetworkController.h"
#import "TKTCPSocketClient.h"
#import "TKTCPSocketResponse.h"

@interface TKTestNetworkController ()

@end

@implementation TKTestNetworkController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.title = @"Networking Test";
    [[TKTCPSocketClient sharedInstance] configurationServer:TKTCPSocketServerDefault];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)action:(id)sender {
    for (int i = 0; i < 1; i++) {
        NSDictionary *parameters = @{
                                     @"func" : @"302",
                                     @"fund_account" : @"100043231",
                                     @"stock_account" : @"00043231",
                                     @"entrust_bs" : @"2",
                                     @"stock_code" : @"00202",
                                     @"entrust_amount" : @"100",
                                     @"exchange_type" : @"WJS",
                                     @"entrust_price" : @"3.4",
                                     @"entrust_prop" : @"0",
                                     };
        NSDictionary *parameters_ = @{
                                      @"password" : @"1122aabb"
                                      };
        TKTCPSocketClient *client = [TKTCPSocketClient sharedInstance];
        TKTCPSocketRequest *request = [[TKTCPSocketRequest alloc] initWithFunc:TKTCPSocketRequestFuncTransaction
                                                                          type:TKTCPSocketRequestTypeDisposable
                                                                       general:parameters
                                                                     sensitive:parameters_];
        TKTCPSocketTask *task = [client dataTaskWithRequest:request completionHandler:^(TKTCPSocketResponse *response) {
            TKTCPSocketDataPack *dataPack = response.dataPack;
            for (int i = 0 ; i < dataPack.count; i++) {
                NSArray *keys = @[@"error_no", @"error_info"];
                TKTCPSocketLog(@"%@", [dataPack values:keys]);
            }
            
        } failure:^(NSError *error) {
            NSLog(@"%@", error);
        }];
        
        [task resume];
    }
}

- (IBAction)action1:(id)sender {
    for (int i = 0; i < 1; i++) {
        NSDictionary *parameters = @{
                                     @"func" : @"411",
                                     @"fund_account" : @"100043231",
                                     @"query_direction" : @"1",
                                     @"request_num" : @"10",
                                     @"position_str" : @"0",
                                     @"start_date" : @"20180201",
                                     @"end_date" : @"20180517",
                                     };
        
        TKTCPSocketClient *client = [TKTCPSocketClient sharedInstance];
        TKTCPSocketRequest *request = [[TKTCPSocketRequest alloc] initWithFunc:TKTCPSocketRequestFuncTransaction
                                                                          type:TKTCPSocketRequestTypeDisposable
                                                                       general:parameters
                                                                     sensitive:nil];
        TKTCPSocketTask *task = [client dataTaskWithRequest:request completionHandler:^(TKTCPSocketResponse *response) {
            TKTCPSocketDataPack *dataPack = response.dataPack;
            NSArray *keys = @[@"error_no", @"stock_code", @"stock_name", @"exchange_name", @"business_price", @"business_status", @"entrust_status", @"business_balance", @"status_name", @"post_amount", @"post_balance", @"occur_balance", @"entrust_price", @"entrust_amount", @"bs_name", @"entrust_bs", @"date", @"entrust_no"];
            TKTCPSocketLog(@"%@", [dataPack values:keys]);
            
        } failure:^(NSError *error) {
            NSLog(@"%@", error);
        }];
        
        [task resume];
    }
}

- (IBAction)action2:(id)sender {
    
}

@end
