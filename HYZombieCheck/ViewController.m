//
//  ViewController.m
//  HYZombieCheck
//
//  Created by liujizhou on 2017/8/22.
//  Copyright © 2017年 ZLJ. All rights reserved.
//

#import "ViewController.h"
#import "HYZombieObjectTest.h"
#import "HYARCObject.h"
#import "HYZombieChecker.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    @autoreleasepool {
        HYARCObject * object = [HYARCObject new];
    }
    HYZombieObjectTest* zoTest = [HYZombieObjectTest new];
    [zoTest testArray];
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [[HYZombieChecker shareInstance] freeAllCacheObjects];
    });
    // Do any additional setup after loading the view, typically from a nib.
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
