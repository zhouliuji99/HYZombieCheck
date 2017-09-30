//
//  HYZombieObjectTest.m
//  HYZombieCheck
//
//  Created by liujizhou on 2017/8/22.
//  Copyright © 2017年 ZLJ. All rights reserved.
//

#import "HYZombieObjectTest.h"


@interface HYObject : NSObject

@property (nonatomic, strong) NSDictionary* dic;

@end


@implementation HYObject

- (instancetype)init
{
    if (self = [super init]) {
        _dic = [NSDictionary new];
    }
    return self;
}

- (void)dealloc
{
    [_dic release];
    [super dealloc];
}

@end
@implementation HYZombieObjectTest

- (void)testArray
{
    NSMutableArray* arr = [NSMutableArray array];
    [arr release];
    [arr addObject:@"1"];
    [arr addObject:@"2"];
    [arr addObject:@"3"];
    [arr addObject:@"4"];
    [arr addObject:@"5"];

    NSMutableArray* tempArray = [NSMutableArray arrayWithObjects:arr, nil];
    [tempArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[NSArray class]]) {
            NSLog(@"");
        }
    }];
    HYObject * object = [HYObject new];
    NSDictionary* dic = object.dic;
    [object release];
    [object dealloc];
    [object release];
    [object retain];
    [object autorelease];
    __weak HYObject* temp = object;
    
    [object release];
    [object release];
    [temp release];
    dispatch_async(dispatch_get_global_queue(0, 0),^{
       [temp release];
    });
    
    if ([dic isKindOfClass:[NSDictionary class]]) {
        NSLog(@"");
    }
    if ([object dic]) {
        NSLog(@"");
    }
    if ([object isKindOfClass:[HYObject class]]) {
        NSLog(@"");
    }
}

- (void)dealloc
{
    [super dealloc];
}

@end
