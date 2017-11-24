//
//  AFRequest.h
//  AFRequest
//
//  Created by YuanGu on 2017/10/30.
//  Copyright © 2017年 YuanGu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@class AFRequest;

typedef void (^AFRequestSuccess)(AFRequest *request ,id object);
typedef void (^AFRequestFailure)(AFRequest *request ,NSError *error);

@interface AFRequest : NSObject

+ (AFRequest *)shareRequest;

- (void)getLoginInfo:(NSString *)mobile
         andPassWord:(NSString *)password
       andNormalType:(BOOL)type
          andSuccess:(AFRequestSuccess)succsess
          andFailure:(AFRequestFailure)faiure;

- (void)getGoogleWebSearchResultsWith:(NSString *)query
                          andLocation:(CLLocationCoordinate2D)coordinate
                             andRadiu:(NSInteger)radiu
                           andSuccess:(AFRequestSuccess)succsess
                           andFailure:(AFRequestFailure)faiure;

@end
