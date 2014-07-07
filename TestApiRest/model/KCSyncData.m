//
//  KCSyncData.m
//  TestApiRest
//
//  Created by Andres Kwan on 6/26/14.
//  Copyright (c) 2014 Kwan Castle. All rights reserved.
//

#import "KCSyncData.h"

static NSString* const serverURL = @"http://localhost:3001/holidays";

NSString * const kSDSyncEngineInitialCompleteKey            = @"SDSyncEngineInitialSyncCompleted";
NSString * const kSDSyncEngineSyncCompletedNotificationName = @"SDSyncEngineSyncCompleted";


@interface KCSyncData()

@property (nonatomic, strong) NSMutableArray *registeredClassesToSync;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;

@end

@implementation KCSyncData

//@synthesize registeredClassesToSync = _registeredClassesToSync;
//@synthesize syncInProgress = _syncInProgress;

#pragma mark singleton
+ (KCSyncData *)sharedSyncDataEngine
{
    static KCSyncData *sharedEngine = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedEngine = [[KCSyncData alloc] init];
    });
    return sharedEngine;
}


#pragma mark Write plist(JSON) to disk
//return the NSURL of the location on disk for the cache directory
//take a look at them
- (NSURL *)applicationCacheDirectory
{
#warning ToDo - Review the content of this file
    return [[[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory
                                                   inDomains:NSUserDomainMask] lastObject];
}
- (NSURL *)JSONDataRecordsDirectory
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSURL *url = [NSURL URLWithString:@"JSONRecords/"
                        relativeToURL:[self applicationCacheDirectory]];
    NSError *error = nil;
    if (![fileManager fileExistsAtPath:[url path]]) {
        [fileManager createDirectoryAtPath:[url path]
               withIntermediateDirectories:YES
                                attributes:nil
                                     error:&error];
    }
    return url;
}
- (void)writeJSONResponse:(id)arrayOfNsDictJson
   toDiskForClassWithName:(NSString *)className
{
    NSURL *fileURL = [NSURL URLWithString:className
                            relativeToURL:[self JSONDataRecordsDirectory]];
        #warning ToDo - should this go into a block, be async, another thread?
        if ([arrayOfNsDictJson writeToFile:[fileURL path] atomically:YES])
        {
            NSLog(@"Json data saved in: %@", fileURL);
        #warning ToDo - handle NSNull
        }else{
            NSLog(@"Error saving response to disk, will attempt to remove NSNull values and try again.");
        }
}

#pragma mark Read plist(JSON) from disk
//returns an array of json objs identifyed by key "results" stored in a plist
- (NSArray *)JSONDictionaryForClassWithName:(NSString *)className
{
    NSURL *fileURL = [NSURL URLWithString:className
                            relativeToURL:[self JSONDataRecordsDirectory]];
    NSArray * nsArrayFronDisk = [NSArray arrayWithContentsOfURL:fileURL];
    return nsArrayFronDisk;
}
- (NSArray *)JSONDataRecordsForClass:(NSString *)className
                         sortedByKey:(NSString *)key
{
    NSArray *records = [self JSONDictionaryForClassWithName:className];
    
    return [records sortedArrayUsingDescriptors:[NSArray arrayWithObject:
                                                 [NSSortDescriptor
                                                  sortDescriptorWithKey:key ascending:NO]]];
}

#pragma mark Delete plist(JSON) on disk
//delete the plist
- (void)deleteJSONDataRecordsForClassWithName:(NSString *)className
{
    NSURL *url = [NSURL URLWithString:className
                        relativeToURL:[self JSONDataRecordsDirectory]];
    NSError *error = nil;
    BOOL deleted = [[NSFileManager defaultManager] removeItemAtURL:url
                                                             error:&error];
    if (!deleted) {
        NSLog(@"Unable to delete JSON Records at %@, reason: %@", url, error);
    }
}

#pragma mark Date data manipulation
- (NSDateFormatter *)dateFormatter
{
    if (!_dateFormatter)
    {
        _dateFormatter = [[NSDateFormatter alloc] init];
        [_dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
        [_dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"GMT"]];
    }
    return _dateFormatter;
}
//receives an NSString and returns an NSDate object
- (NSDate *)dateUsingStringFromAPI:(NSString *)dateString
{
    // NSDateFormatter does not like ISO 8601 so strip the milliseconds and timezone
    dateString = [dateString substringWithRange:NSMakeRange(0, [dateString length]-5)];
    return [self.dateFormatter dateFromString:dateString];
}
//receives an NSDate and returns an NSString
- (NSString *)dateStringForAPIUsingDate:(NSDate *)date
{
    NSString *dateString = [self.dateFormatter stringFromDate:date];
    // remove Z
    dateString = [dateString substringWithRange: NSMakeRange(0, [dateString length]-1)];
    // add milliseconds and put Z back on
    dateString = [dateString stringByAppendingFormat:@".000Z"];
    return dateString;
}

//////////////////////////////////////////////////////
//
//////////////////////////////////////////////////////

#pragma mark Sync methods
#warning ToDo - Test
- (void)startSync
{
    if (!self.syncInProgress) {
        //property value is about to change
        //invoke this method when implementing key-value observer compliance manually. WHAT!!!
        [self willChangeValueForKey:@"syncInProgress"];
        _syncInProgress = YES;
        
        //invoke this method when implementing key-value observer compliance manually
        [self didChangeValueForKey:@"syncInProgress"];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0),
                       ^{
                           [self downloadDataForRegisteredObjects:YES];
                       });
    }
}
#warning ToDo - Test
- (BOOL)initialSyncComplete
{
    //how to use NSUserDefaults to retrieve a store a value
    return [[[NSUserDefaults standardUserDefaults] valueForKey:kSDSyncEngineInitialCompleteKey]
            boolValue];
}
#warning ToDo - Test
- (void)setInitialSyncCompleted
{
    //how to use NSUserDefaults to set or store a value
    [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithBool:YES]
                                             forKey:kSDSyncEngineInitialCompleteKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}
#warning ToDo - Identify where (by whom) and when this method is called
#warning ToDo - Test
- (void)executeSyncCompletedOperations
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self setInitialSyncCompleted];
        [[NSNotificationCenter defaultCenter] postNotificationName:kSDSyncEngineSyncCompletedNotificationName
                                                            object:nil];
        [self willChangeValueForKey:@"syncInProgress"];
        
        _syncInProgress = NO;
        
        [self didChangeValueForKey:@"syncInProgress"];
    });
}

#pragma mark Core Data Helpers
//Register the NSManagedObjects that will be sync with a remote server
//use an array to hold this classes (templates)
#warning ToDo - Test
- (void)registerNSManagedObjectClassToSync:(Class)aClass
{
    if (!self.registeredClassesToSync) {
        self.registeredClassesToSync = [NSMutableArray array];
    }
    if ([aClass isSubclassOfClass:[NSManagedObject class]]) {
        //does the array have the object?
        if (![self.registeredClassesToSync containsObject:NSStringFromClass(aClass)]) {
            //add the obj to the array
            [self.registeredClassesToSync addObject:NSStringFromClass(aClass)];
        } else {
            NSLog(@"Unable to register %@ as it is already registered",
                  NSStringFromClass(aClass));
        }
    } else {
        NSLog(@"Unable to register %@ as it is not a subclass of NSManagedObject",
              NSStringFromClass(aClass));
    }
}
//returns the “most recent last modified date” for a specific entity.
#warning ToDo - Test
- (NSDate *)mostRecentUpdatedAtDateForEntityWithName:(NSString *)entityName
{
    __block NSDate *date = nil;
    //
    // Create a new fetch request for the specified entity
    //
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:entityName];
    //
    // Set the sort descriptors on the request to sort by updatedAt in descending order
    //
    [request setSortDescriptors:[NSArray arrayWithObject:
                                 [NSSortDescriptor sortDescriptorWithKey:@"updatedAt"
                                                               ascending:NO]
                                 ]];
    //
    // You are only interested in 1 result so limit the request to 1
    //
    [request setFetchLimit:1];
    
    [[[KCCoreDataStack shareCoreDataInstance] backgroundManagedObjectContext]
     performBlockAndWait:^{
         NSError *error = nil;
         NSArray *results = [[[KCCoreDataStack shareCoreDataInstance] backgroundManagedObjectContext]
                             executeFetchRequest:request
                             error:&error];
         
         if ([results lastObject]) {
             //
             // Set date to the fetched result
             //
             date = [[results lastObject] valueForKey:@"updatedAt"];
         }
     }];
    return date;
}
- (void)newManagedObjectWithClassName:(NSString *)className
                            forRecord:(NSDictionary*)record
{
    NSManagedObject *newManagedObject = [NSEntityDescription insertNewObjectForEntityForName:className
                                                                      inManagedObjectContext:
                                         [[KCCoreDataStack shareCoreDataInstance] backgroundManagedObjectContext]];
    [record enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [self setValue:obj forKey:key forManagedObject:newManagedObject];
    }];
    [record setValue:[NSNumber numberWithInt:SDObjectSynced]
              forKey:@"syncStatus"];
}
#warning ToDo - Test
- (void)updateManagedObject:(NSManagedObject *)managedObject
                 withRecord:(NSDictionary *)record
{
    [record enumerateKeysAndObjectsUsingBlock:
     ^(id key, id obj, BOOL *stop) {
         [self setValue:obj forKey:key forManagedObject:managedObject];
     }];
}
#warning ToDo - Test this what does mongo return?
- (void)setValue:(id)value
          forKey:(NSString *)key
forManagedObject:(NSManagedObject *)managedObject
{
    if ([key isEqualToString:@"date"]      ||
        [key isEqualToString:@"createdAt"] ||
        [key isEqualToString:@"updatedAt"])
    {
        NSDate *date = [self dateUsingStringFromAPI:value];
        [managedObject setValue:date forKey:key];
    } else if ([value isKindOfClass:[NSDictionary class]]) {
        if ([value objectForKey:@"__type"]) {
            NSString *dataType = [value objectForKey:@"__type"];
            if ([dataType isEqualToString:@"Date"]) {
                NSString *dateString = [value objectForKey:@"iso"];
                NSDate *date = [self dateUsingStringFromAPI:dateString];
                [managedObject setValue:date forKey:key];
            } else if ([dataType isEqualToString:@"File"]) {
                NSString *urlString = [value objectForKey:@"url"];
                NSURL *url = [NSURL URLWithString:urlString];
                NSURLRequest *request = [NSURLRequest requestWithURL:url];
                NSURLResponse *response = nil;
                NSError *error = nil;
                NSData *dataResponse = [NSURLConnection sendSynchronousRequest:request returningResponse:&
                                        response error:&error];
                [managedObject setValue:dataResponse forKey:key];
            } else {
                NSLog(@"Unknown Data Type Received");
                [managedObject setValue:nil forKey:key];
            }
        }
    } else {
        //if key == _id then key = objectID
        //both ways
        if ([key isEqualToString:@"_id"]) {
            key = @"objectId";
        }
        [managedObject setValue:value forKey:key];
    }
}

#pragma mark Networking
#warning ToDo - Test
// replace AFNetworking with NSURLSession
- (void)downloadDataForRegisteredObjects:(BOOL)useUpdatedAtDate
{
    //for each managedObj in the array
    for (NSString *className in self.registeredClassesToSync) {
        NSDate *mostRecentUpdatedDate = nil;
        //
        if (useUpdatedAtDate) {
            mostRecentUpdatedDate = [self mostRecentUpdatedAtDateForEntityWithName:className];
        }
        
        //Networking code
        //get json in the db for entity recent updated
#warning ToDo - ID specify the id of the object requested
        NSString * urlString = [NSString stringWithFormat:serverURL];
        NSURL* url = [NSURL URLWithString:urlString];
        
        NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url];
        request.HTTPMethod =@"GET";
        
        [request addValue:@"application/json" forHTTPHeaderField:@"Accept"]; //4
        
        NSURLSessionConfiguration* config = [NSURLSessionConfiguration defaultSessionConfiguration];
        NSURLSession* session = [NSURLSession sessionWithConfiguration:config];
        
        NSURLSessionDataTask* dataTask =
        [session dataTaskWithRequest:request
                   completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) { //5
                       if (error == nil) {
                           NSError *error;
                           id arrayOfDict = [NSJSONSerialization JSONObjectWithData:data
                                                                            options:0
                                                                              error:&error];
                           if (error == nil)
                           {
                               NSLog(@"obj class:%@", [arrayOfDict class]);
                               
                               [self writeJSONResponse:arrayOfDict
                                toDiskForClassWithName:className];
                               
                           }else{
                               NSLog(@"Request for class %@ failed with error: %@", className, error);
                           }
                       }
                   }];
        [dataTask resume]; //8
    }//end for each
}
- (NSArray *)managedObjectsForClass:(NSString *)className
                     withSyncStatus:(SDObjectSyncStatus)syncStatus
{
    __block NSArray *results = nil;
    NSManagedObjectContext *managedObjectContext = [[KCCoreDataStack shareCoreDataInstance]
                                                    backgroundManagedObjectContext];
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:className];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"syncStatus = %d", syncStatus];
    [fetchRequest setPredicate:predicate];
    [managedObjectContext performBlockAndWait:^{
        NSError *error = nil;
        results = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
    }];
    return results;
}
- (NSArray *)managedObjectsForClass:(NSString *)className
                        sortedByKey:(NSString *)key
                    usingArrayOfIds:(NSArray *)idArray
                       inArrayOfIds:(BOOL)inIds
{
    __block NSArray *results = nil;
    NSManagedObjectContext *managedObjectContext = [[KCCoreDataStack shareCoreDataInstance]
                                                    backgroundManagedObjectContext];
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:className];
    NSPredicate *predicate;
    if (inIds) {
        predicate = [NSPredicate predicateWithFormat:@"objectId IN %@", idArray];
    } else {
        predicate = [NSPredicate predicateWithFormat:@"NOT (objectId IN %@)", idArray];
    }
    [fetchRequest setPredicate:predicate];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObject:
                                      [NSSortDescriptor sortDescriptorWithKey:@"objectId"
                                                                    ascending:YES]]];
    [managedObjectContext performBlockAndWait:^{
        NSError *error = nil;
        results = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
    }];
    return results;
}
- (void)processJSONDataRecordsIntoCoreData
{
    NSManagedObjectContext *managedObjectContext = [[KCCoreDataStack shareCoreDataInstance]
                                                    backgroundManagedObjectContext];
    //
    // Iterate over all registered classes to sync
    //
    for (NSString *className in self.registeredClassesToSync) {
        if (![self initialSyncComplete]) { // import all downloaded data to Core Data for initial sync
            //
            // If this is the initial sync then the logic is pretty simple, you will fetch the JSON data from disk
            // for the class of the current iteration and create new NSManagedObjects for each record
            //
            NSDictionary *JSONDictionary = [self JSONDictionaryForClassWithName:className];
            NSArray *records = [JSONDictionary objectForKey:@"results"];
            for (NSDictionary *record in records) {
                [self newManagedObjectWithClassName:className forRecord:record];
            }
        } else {
            //
            // Otherwise you need to do some more logic to determine if the record is new or has been updated.
            // First get the downloaded records from the JSON response, verify there is at least one object in
            // the data, and then fetch all records stored in Core Data whose objectId matches those from the JSON response.
            //
            NSArray *downloadedRecords = [self JSONDataRecordsForClass:className sortedByKey:@"objectId"];
            if ([downloadedRecords lastObject]) {
                //
                // Now you have a set of objects from the remote service and all of the matching objects
                // (based on objectId) from your Core Data store. Iterate over all of the downloaded records
                // from the remote service.
                //
                NSArray *storedRecords = [self managedObjectsForClass:className
                                                          sortedByKey:@"objectId"
                                                      usingArrayOfIds:[downloadedRecords valueForKey:@"objectId"]
                                                         inArrayOfIds:YES];
                int currentIndex = 0;
                //
                // If the number of records in your Core Data store is less than the currentIndex, you know that
                // you have a potential match between the downloaded records and stored records because you sorted
                // both lists by objectId, this means that an update has come in from the remote service
                //
                for (NSDictionary *record in downloadedRecords) {
                    NSManagedObject *storedManagedObject = nil;
                    // Make sure we don't access an index that is out of bounds as we are iterating over both collections together
                    if ([storedRecords count] > currentIndex) {
                        storedManagedObject = [storedRecords objectAtIndex:currentIndex];
                    }
                    if ([[storedManagedObject valueForKey:@"objectId"] isEqualToString:
                         [record valueForKey:@"objectId"]]) {
                        //
                        // Do a quick spot check to validate the objectIds in fact do match, if they do update the stored
                            // object with the values received from the remote service
                            //
                            [self updateManagedObject:[storedRecords objectAtIndex:currentIndex]
                                           withRecord:record];
                    } else {
                        //
                        // Otherwise you have a new object coming in from your remote service so create a new
                        // NSManagedObject to represent this remote object locally
                        //
                        [self newManagedObjectWithClassName:className forRecord:record];
                    }
                    currentIndex++;
                }
            }
        }
        //
        // Once all NSManagedObjects are created in your context you can save the context to persist the objects
        // to your persistent store. In this case though you used an NSManagedObjectContext who has a parent context
        // so all changes will be pushed to the parent context
        //
        [managedObjectContext performBlockAndWait:^{
            NSError *error = nil;
            if (![managedObjectContext save:&error]) {
                NSLog(@"Unable to save context for class %@", className);
            }
        }];
        //
        // You are now done with the downloaded JSON responses so you can delete them to clean up after yourself,
        // then call your -executeSyncCompletedOperations to save off your master context and set the
        // syncInProgress flag to NO
        //
        [self deleteJSONDataRecordsForClassWithName:className];
        [self executeSyncCompletedOperations];
    }
}

@end
