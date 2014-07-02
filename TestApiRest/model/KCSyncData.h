//
//  KCSyncData.h
//  TestApiRest
//
//  Created by Andres Kwan on 6/26/14.
//  Copyright (c) 2014 Kwan Castle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KCCoreDataStack.h"


@interface KCSyncData : NSObject

//to track the sync status:
@property (atomic, readonly) BOOL syncInProgress;

+ (KCSyncData *) sharedSyncDataEngine;

- (void)registerNSManagedObjectClassToSync:(Class)aClass;
- (void)startSync;


- (void)setValue:(id)value
          forKey:(NSString *)key
forManagedObject:(NSManagedObject *)managedObject;

//#pragma mark Read plist(JSON) from disk
- (NSDictionary *)JSONDictionaryForClassWithName:(NSString *)className;
- (NSArray *)JSONDataRecordsForClass:(NSString *)className
                         sortedByKey:(NSString *)key;

//#pragma mark Date data manipulation
- (NSDate *)dateUsingStringFromAPI:(NSString *)dateString;
- (NSString *)dateStringForAPIUsingDate:(NSDate *)date;
@end
