//
//  KCSyncData.h
//  TestApiRest
//
//  Created by Andres Kwan on 6/26/14.
//  Copyright (c) 2014 Kwan Castle. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KCSyncData : NSObject
+ (KCSyncData *) sharedSyncDataEngine;

- (void)registerNSManagedObjectClassToSync:(Class)aClass;
@end
