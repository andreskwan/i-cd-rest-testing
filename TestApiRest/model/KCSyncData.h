//
//  KCSyncData.h
//  TestApiRest
//
//  Created by Andres Kwan on 6/26/14.
//  Copyright (c) 2014 Kwan Castle. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KCSyncData : NSObject

//to track the sync status:
@property (atomic, readonly) BOOL syncInProgress;

+ (KCSyncData *) sharedSyncDataEngine;

- (void)registerNSManagedObjectClassToSync:(Class)aClass;
- (void)startSync;

//put here to allow testing
- (NSDate *)dateUsingStringFromAPI:(NSString *)dateString;
- (NSString *)dateStringForAPIUsingDate:(NSDate *)date;
@end
