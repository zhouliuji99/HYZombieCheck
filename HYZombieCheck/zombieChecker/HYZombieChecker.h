//
//  HYZombieChecker.h
//  HYZombieCheck
//
//  Created by liujizhou on 2017/8/22.
//  Copyright © 2017年 ZLJ. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^HYZombieCallBlock)(NSString* className,NSString * selector,void* objectAddress);

@interface HYZombieChecker : NSObject

+ (instancetype)shareInstance;

- (void)freeAllCacheObjects;

+ (void)zombieCheckStartCallBlock:(HYZombieCallBlock)callBlock;

+ (void)setZombieEnabeled:(BOOL)enabel;

@end
