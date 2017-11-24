//
//  AppDelegate.h
//  AFRequest
//
//  Created by YuanGu on 2017/11/24.
//  Copyright © 2017年 YuanGu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong) NSPersistentContainer *persistentContainer;

- (void)saveContext;


@end

