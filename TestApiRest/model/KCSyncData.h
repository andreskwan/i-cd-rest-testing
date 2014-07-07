//
//  KCSyncData.h
//  TestApiRest
//
//  Created by Andres Kwan on 6/26/14.
//  Copyright (c) 2014 Kwan Castle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KCCoreDataStack.h"

typedef enum {
    SDObjectSynced = 0,
    SDObjectCreated,
    SDObjectDeleted,
} SDObjectSyncStatus;

@interface KCSyncData : NSObject

//to track the sync status:
@property (atomic, readonly) BOOL syncInProgress;

+ (KCSyncData *) sharedSyncDataEngine;

- (void)registerNSManagedObjectClassToSync:(Class)aClass;
- (void)startSync;

#pragma mark Core Data Helpers
- (void)setValue:(id)value
          forKey:(NSString *)key
forManagedObject:(NSManagedObject *)managedObject;
- (void)newManagedObjectWithClassName:(NSString *)className
                            forRecord:(NSDictionary*)record;


#pragma mark Write plist(JSON) to disk
- (void)writeJSONResponse:(id)arrayOfNsDictJson
   toDiskForClassWithName:(NSString *)className;

#pragma mark Read plist(JSON) from disk
//readJsonOnDiskForClassWithName
- (NSArray *)JSONDictionaryForClassWithName:(NSString *)className;
- (NSArray *)JSONDataRecordsForClass:(NSString *)className
                         sortedByKey:(NSString *)key;
#pragma mark Delete
- (void)deleteJSONDataRecordsForClassWithName:(NSString *)className;

#pragma mark Date data manipulation
- (NSDate *)dateUsingStringFromAPI:(NSString *)dateString;
- (NSString *)dateStringForAPIUsingDate:(NSDate *)date;

- (NSURL *)applicationCacheDirectory;
- (NSURL *)JSONDataRecordsDirectory;

@end
