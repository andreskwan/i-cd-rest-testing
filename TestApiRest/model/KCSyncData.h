//
//  KCSyncData.h
//  TestApiRest
//
//  Created by Andres Kwan on 6/26/14.
//  Copyright (c) 2014 Kwan Castle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KCCoreDataStack.h"

typedef NS_ENUM(NSInteger, SDObjectSyncStatus) {
    SDObjectSynced,
    SDObjectCreated,
    SDObjectDeleted,
};

//NSString * const kSDSyncEngineInitialCompleteKey            = @"SDSyncEngineInitialSyncCompleted";
//NSString * const kSDSyncEngineSyncCompletedNotificationName = @"SDSyncEngineSyncCompleted";

@interface KCSyncData : NSObject

@property (nonatomic, strong) NSMutableArray *registeredClassesToSync;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;

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
- (void)updateManagedObject:(NSManagedObject *)managedObject
                 withRecord:(NSDictionary *)record;
- (NSArray *)managedObjectsForClass:(NSString *)className
                     withSyncStatus:(SDObjectSyncStatus)syncStatus;
- (NSArray *)managedObjectsForClass:(NSString *)className
                        sortedByKey:(NSString *)key
                    usingArrayOfIds:(NSArray *)idArray
                       inArrayOfIds:(BOOL)inIds;
- (void)processJSONDataRecordsIntoCoreData;

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
