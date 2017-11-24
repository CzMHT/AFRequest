//
//  AFRequest.m
//  AFRequest
//
//  Created by YuanGu on 2017/10/30.
//  Copyright © 2017年 YuanGu. All rights reserved.
//

#import "AFRequest.h"
#import "AFNetworking.h"
#import <CommonCrypto/CommonDigest.h>


#define HTTP_URL @"https://www.cooldrivehud.com:8443/HUDServer/"  //当前使用

@implementation AFRequest{
    
    AFHTTPSessionManager *_httpsManager; //需要设置 证书 .cer
    AFHTTPSessionManager *_httpManager;  //无需证书 ,例如google search api
}

+ (AFRequest *)shareRequest{
    
    static AFRequest *request;
    
    static dispatch_once_t onecToken;
    
    dispatch_once(&onecToken, ^{
       
        request = [[AFRequest alloc] init];
    });
    
    return request;
}

- (instancetype)init{
    
    self = [super init];
    
    if (self) {
        
        //这个  HTTP_URL  是你们的网址,只要有https就行
        _httpsManager = [[AFHTTPSessionManager alloc] initWithBaseURL:[NSURL URLWithString:HTTP_URL] sessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
        [_httpsManager setSecurityPolicy:[self getCustomSecurityPolicy]];
        _httpsManager.requestSerializer.timeoutInterval = 20.f;
        _httpsManager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"text/html", nil];
        
        _httpManager = [[AFHTTPSessionManager alloc] initWithBaseURL:[NSURL URLWithString:HTTP_URL] sessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
        _httpManager.requestSerializer.timeoutInterval = 20.f;
        _httpManager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"text/html", nil];
    }
    
    return self;
}

- (AFSecurityPolicy *)getCustomSecurityPolicy{
    
    //先导入证书，找到证书的路径 当使用第三方的时候 可能会使用到bundle中的cer
    
    //证书的名字
    NSString *cerPath = [[NSBundle mainBundle] pathForResource:@"HUDHttps" ofType:@"cer"];
    
    NSData *certData  = [NSData dataWithContentsOfFile:cerPath];
    
    //AFSSLPinningModeCertificate 使用证书验证模式
    AFSecurityPolicy *securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate];
    
    //allowInvalidCertificates 是否允许无效证书（也就是自建的证书），默认为NO
    //如果是需要验证自建证书，需要设置为YES
    securityPolicy.allowInvalidCertificates = YES;
    
    //validatesDomainName 是否需要验证域名，默认为YES；
    //假如证书的域名与你请求的域名不一致，需把该项设置为NO；如设成NO的话，即服务器使用其他可信任机构颁发的证书，也可以建立连接，这个非常危险，建议打开。
    //置为NO，主要用于这种情况：客户端请求的是子域名，而证书上的是另外一个域名。因为SSL证书上的域名是独立的，假如证书上注册的域名是www.google.com，那么mail.google.com是无法验证通过的；当然，有钱可以注册通配符的域名*.google.com，但这个还是比较贵的。
    //如置为NO，建议自己添加对应域名的校验逻辑。
    
    securityPolicy.validatesDomainName = NO;
    
    NSSet *set = [[NSSet alloc] initWithObjects:certData, nil];
    
    securityPolicy.pinnedCertificates = set;
    
    return securityPolicy;
}

- (NSDictionary *)alterToJSON:(id)dict{
    
    NSError *error;
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict options:0 error:&error];
    
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    dict = [NSDictionary dictionaryWithObjectsAndKeys:jsonString,@"json", nil];
    
    return dict;
}

- (NSString *)getMd5_32Bit_String:(NSString *)srcString{
    
    const char *original_str = [srcString UTF8String];
    
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    
    CC_MD5(original_str, (CC_LONG)strlen(original_str), result); // This is the md5 call
    
    NSMutableString *hash = [NSMutableString string];
    
    for (int i = 0; i < 16; i++)
        [hash appendFormat:@"%02X", result[i]];
    
    return [hash lowercaseString];
}

- (void)getLoginInfo:(NSString *)mobile
         andPassWord:(NSString *)password
       andNormalType:(BOOL)type
          andSuccess:(AFRequestSuccess)succsess
          andFailure:(AFRequestFailure)faiure
{
    //加密并转换为字典
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
                          mobile ,(type ? @"username" : @"mobile") ,
                          [self getMd5_32Bit_String:password] ,
                          (type ? @"password" : @"code") ,nil];
    
    NSString *urlStr = [NSString stringWithFormat:@"%@userlogin.action" ,HTTP_URL];
    
    [_httpsManager POST:urlStr parameters:[self alterToJSON:dict]
               progress:nil
                success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                    
                    //判断 解析数据类型 可能是 NSData 也可能是 NSDictionary
                    if ([responseObject isKindOfClass:[NSData class]]) {
                        
                        NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingMutableContainers error:nil];
                        
                        succsess(self ,dictionary);
                    }else{
                        succsess(self, (NSDictionary *)responseObject);
                    }
                } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                    
                    faiure(self ,error);
                }];
}

- (void)getGoogleWebSearchResultsWith:(NSString *)query
                          andLocation:(CLLocationCoordinate2D)coordinate
                             andRadiu:(NSInteger)radiu
                           andSuccess:(AFRequestSuccess)succsess
                           andFailure:(AFRequestFailure)faiure
{
    //取消之前的 所有任务
    [_httpManager.operationQueue cancelAllOperations];
    
    NSString *queryStr = [query stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    
    NSString *location = [NSString stringWithFormat:@"%f,%f" ,coordinate.latitude,coordinate.longitude];
    
    NSString *uslStr = [NSString stringWithFormat:@"https://maps.googleapis.com/maps/api/place/queryautocomplete/json?language=en&input=%@&location=%@&radius=%ld&key=AIzaSyAlpIHxCxDfk3sgp8fn_Lksm1lOp2hSJKo" ,queryStr ,location ,(long)radiu];
    
    [_httpManager POST:uslStr parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:(NSData *)responseObject options:NSJSONReadingMutableLeaves error:nil];
        
        succsess(self ,dict);
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
        faiure(self ,error);
    }];
}
@end
