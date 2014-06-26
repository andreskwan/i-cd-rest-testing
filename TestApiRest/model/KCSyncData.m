//
//  KCSyncData.m
//  TestApiRest
//
//  Created by Andres Kwan on 6/26/14.
//  Copyright (c) 2014 Kwan Castle. All rights reserved.
//

#import "KCSyncData.h"

@implementation KCSyncData
+ (KCSyncData *)sharedSyncDataEngine {
    static KCSyncData *sharedEngine = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedEngine = [[KCSyncData alloc] init];
    });
    return sharedEngine;
}
@end
