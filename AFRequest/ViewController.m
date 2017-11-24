//
//  ViewController.m
//  AFRequest
//
//  Created by YuanGu on 2017/11/24.
//  Copyright © 2017年 YuanGu. All rights reserved.
//

#import "ViewController.h"
#import "AFRequest.h"

@interface ViewController ()

@property (nonatomic ,strong) AFRequest *request;

@end

@implementation ViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    self.title = @"Requst Demo";
    
    self.request = [AFRequest shareRequest];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    
    //点击 进行 网络请求
    [self.request getLoginInfo:@"" andPassWord:@"" andNormalType:YES andSuccess:^(AFRequest *request, id object) {
        
    } andFailure:^(AFRequest *request, NSError *error) {
        
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end

