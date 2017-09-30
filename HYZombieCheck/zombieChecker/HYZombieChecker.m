//
//  HYZombieChecker.m
//  HYZombieCheck
//
//  Created by liujizhou on 2017/8/22.
//  Copyright © 2017年 ZLJ. All rights reserved.
//

#import "HYZombieChecker.h"
#import <objc/runtime.h>
#import <pthread.h>
#import <malloc/malloc.h>
#import <objc/message.h>

#define HYZombieClassPre @"_HYZombie_"

extern void *objc_destructInstance(id obj) ;
OBJC_EXPORT void _objc_rootDealloc(id obj);

static HYZombieCallBlock __zombieCallBlock = NULL;

static dispatch_queue_t __HYZombieQueue = nil;
static dispatch_queue_t __HYZombieChangeClassQue = nil;

static NSMutableDictionary * __zombieClassKeyDic = nil;

static BOOL   __HYZombieEnabel = NO;


@implementation HYZombieChecker
{
    dispatch_queue_t _queue;
    CFMutableArrayRef _cacheObjectArray;
}

+ (instancetype)shareInstance
{
    static dispatch_once_t onceToken;
    static HYZombieChecker *checker = nil;
    dispatch_once(&onceToken, ^{
        checker = [HYZombieChecker new];
    });
    return checker;
}

+ (void)initialize
{
    if (self == [HYZombieChecker class]) {
        __HYZombieQueue = dispatch_queue_create("HYZombieChangeClassQue",DISPATCH_QUEUE_CONCURRENT);
        __HYZombieChangeClassQue = dispatch_queue_create("HYZombieChangeClassQue",DISPATCH_QUEUE_SERIAL);
    }
}

- (instancetype)init
{
    if (self = [super init]) {
        _queue = dispatch_queue_create("HYZombieCheckerQue",DISPATCH_QUEUE_SERIAL);
        _cacheObjectArray = CFArrayCreateMutable(NULL, 100, NULL);;
    }
    return self;
}

- (void) addCacheObject:(id)object
{
    if (!object) {
        return;
    }
    void* address = (void*)object;
    dispatch_async(_queue, ^{
        CFArrayAppendValue(_cacheObjectArray, address);
    });
}

- (void)freeAllCacheObjects
{
    dispatch_async(_queue, ^{
        for (int index = 0;index < CFArrayGetCount(_cacheObjectArray);index++) {
            void *ptr = (void*)CFArrayGetValueAtIndex(_cacheObjectArray, index);
            if (!ptr) {
                continue;
            }
            freeZombieObjectInArray(ptr, NULL);
        }
        CFArrayRemoveAllValues(_cacheObjectArray);
    });
}

void freeZombieObjectInArray(const void* value, void * context)
{
    id zombieObj = (id)value;
//    _objc_rootDealloc(zombieObj);
}

+ (void)zombieCheckStartCallBlock:(HYZombieCallBlock)callBlock
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self swizzleDeallocMethod:[NSObject class]];
        __zombieCallBlock = callBlock;
        __HYZombieEnabel = YES;
    });
}

+ (void)setZombieEnabeled:(BOOL)enabel
{
    __HYZombieEnabel = enabel;
}

+ (void) swizzleDeallocMethod:(Class)currentClass
{
    SEL selector = @selector(dealloc);
    Method method = class_getInstanceMethod(currentClass, selector);
    char* typeDescription = (char *)method_getTypeEncoding(method);
    class_replaceMethod(currentClass, selector, (IMP)_HYZombieDealloc, typeDescription);

}

static void _changeToZombieClass(NSObject* object)
{
    dispatch_sync(__HYZombieChangeClassQue, ^{
        NSString *zombieClass = [NSString stringWithFormat:@"%@%@",HYZombieClassPre, NSStringFromClass([object class])];
        __block Class resultClass = NSClassFromString(zombieClass);
        NSString* objectClass = NSStringFromClass(object_getClass(object));
        if ([objectClass hasPrefix:HYZombieClassPre]) {
            return;
        }
        if (!resultClass) {
            @synchronized (_obtainSynchronizedObject(zombieClass)) {
                resultClass = NSClassFromString(zombieClass);
                if (resultClass) {
                    return;
                }
                resultClass = objc_allocateClassPair([NSProxy class], [zombieClass UTF8String], 0);
                class_replaceMethod(resultClass, @selector(methodSignatureForSelector:), (IMP)_HYMethodSignatureForSelector, "@@::");
                class_replaceMethod(resultClass, @selector(forwardInvocation:), (IMP)_zombieOCForwardInvocation, "v@:@");
                class_replaceMethod(resultClass, @selector(release), (IMP)_objc_msgForward, "v@:");
                class_replaceMethod(resultClass, @selector(dealloc), (IMP)_objc_msgForward, "v@:");
                class_replaceMethod(resultClass, @selector(retain), (IMP)_objc_msgForward, "@16@0:8");
                class_replaceMethod(resultClass, @selector(autorelease), (IMP)_objc_msgForward, "v@:");
                class_replaceMethod(resultClass, @selector(allowsWeakReference), (IMP)_objc_msgForward, "B16@0:8");
                class_replaceMethod(resultClass, @selector(retainWeakReference), (IMP)_objc_msgForward, "B16@0:8");
                objc_registerClassPair(resultClass);
                
            };
        }
        object_setClass(object,resultClass);
    });    
}

static NSObject* _obtainSynchronizedObject(NSString* objectClass)
{
    if (!objectClass) {
        return nil;
    }
    __block NSObject* synch = nil;
    dispatch_sync(__HYZombieQueue, ^{
        synch = [__zombieClassKeyDic objectForKey:objectClass];
    });
    
    if (!synch) {
        dispatch_barrier_sync(__HYZombieQueue, ^{
            synch = [__zombieClassKeyDic objectForKey:objectClass];
            if (!synch) {
                 [__zombieClassKeyDic setObject:objectClass forKey:objectClass];
                synch = objectClass;
            }
           
        });
    }
    return synch;
}


static void _zombieOCForwardInvocation(id slf, SEL selector, NSInvocation *invocation)
{
    NSString *selectorName = NSStringFromSelector(invocation.selector);
    Class className =object_getClass(slf);
    NSString* original = [NSStringFromClass(className) stringByReplacingOccurrencesOfString:HYZombieClassPre withString:@""];
    if (__zombieCallBlock) {
        __zombieCallBlock(original,selectorName,slf);
    }
}



static NSMethodSignature* _HYMethodSignatureForSelector(id slf, SEL selector)
{
    NSString* objectClass = NSStringFromClass(object_getClass(slf));
    if (![objectClass hasPrefix:HYZombieClassPre]) {
        return [slf methodSignatureForSelector:selector];
    }
    NSString* original = [objectClass stringByReplacingOccurrencesOfString:HYZombieClassPre withString:@""];
    Class originalClass = NSClassFromString(original);
    return [originalClass instanceMethodSignatureForSelector:selector];
}


static void _HYZombieDealloc(id slf, SEL selector)
{
    if (!slf) {
        return;
    }
    if (__HYZombieEnabel) {
//        objc_destructInstance(slf);
        _changeToZombieClass(slf);
        [[HYZombieChecker shareInstance]addCacheObject:slf];
    }else
    {
         _objc_rootDealloc(slf);
    }
    
}


@end

