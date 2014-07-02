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
#pragma mark Sync methods
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
- (BOOL)initialSyncComplete
{
    //how to use NSUserDefaults to retrieve a store a value
    return [[[NSUserDefaults standardUserDefaults] valueForKey:kSDSyncEngineInitialCompleteKey]
            boolValue];
}
- (void)setInitialSyncCompleted
{
    //how to use NSUserDefaults to set or store a value
    [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithBool:YES]
                                             forKey:kSDSyncEngineInitialCompleteKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}
#warning ToDo - Identify where (by whom) and when this method is called
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
#warning ToDo - what does mongo return?
- (void)setValue:(id)value
          forKey:(NSString *)key
forManagedObject:(NSManagedObject *)managedObject
{
    if ([key isEqualToString:@"createdAt"] || [key isEqualToString:@"updatedAt"]) {
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
        [managedObject setValue:value forKey:key];
    }
}
#pragma mark Networking
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
#pragma mark - Write plist(JSON) to disk
//return an NSURL to a location on disk where the files will reside
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
    
    NSURL *url = [NSURL URLWithString:@"JSONRecords/" relativeToURL:[self applicationCacheDirectory]];
    
    NSError *error = nil;
    if (![fileManager fileExistsAtPath:[url path]]) {
        [fileManager createDirectoryAtPath:[url path]
               withIntermediateDirectories:YES
                                attributes:nil
                                     error:&error];
    }
    return url;
}
- (void)writeJSONResponse:(id)arrayOfJson
   toDiskForClassWithName:(NSString *)className
{
    NSURL *fileURL = [NSURL URLWithString:className
                            relativeToURL:[self JSONDataRecordsDirectory]];
    //here I should save the array
    //or create one
//    for (NSDictionary * dict in arrayOfJson) {
        if ([arrayOfJson writeToFile:[fileURL path] atomically:YES])
        {
            NSLog(@"Json data saved in: %@", fileURL);
        #warning ToDO - handel NSNull
        }else{
            NSLog(@"Error saving response to disk, will attempt to remove NSNull values and try again.");
        }
//    }
}
#pragma mark Read plist(JSON) from disk
#warning ToDo - Test this
//returns an array of json objs identifyed by key "results"
- (NSDictionary *)JSONDictionaryForClassWithName:(NSString *)className
{
    NSURL *fileURL = [NSURL URLWithString:className
                            relativeToURL:[self JSONDataRecordsDirectory]];
    return [NSDictionary dictionaryWithContentsOfURL:fileURL];
}

- (NSArray *)JSONDataRecordsForClass:(NSString *)className
                         sortedByKey:(NSString *)key
{
    NSDictionary *JSONDictionary = [self JSONDictionaryForClassWithName:className];
    NSArray *records = [JSONDictionary objectForKey:@"results"];
    
    return [records sortedArrayUsingDescriptors:[NSArray arrayWithObject:
                                                 [NSSortDescriptor
                                                  sortDescriptorWithKey:key ascending:YES]]];
}
#pragma mark Delete plist(JSON) on disk
#warning ToDo - Test this
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
#warning DONE - ToDo - Test this
- (NSDateFormatter *)dateFormatter
{
    if (!_dateFormatter) {
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































@end
