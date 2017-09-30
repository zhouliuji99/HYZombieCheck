//
//  HYARCObject.m
//  HYZombieCheck
//
//  Created by liujizhou on 2017/8/23.
//  Copyright © 2017年 ZLJ. All rights reserved.
//

#import "HYARCObject.h"

@implementation HYARCObject


- (instancetype)init
{
    if (self = [super init]) {
        _testObject = [HYZombieObjectTest new];
    }
    return self;
}

- (void)dealloc
{
    
}

@end
