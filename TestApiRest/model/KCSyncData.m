//
//  KCSyncData.m
//  TestApiRest
//
//  Created by Andres Kwan on 6/26/14.
//  Copyright (c) 2014 Kwan Castle. All rights reserved.
//

#import "KCSyncData.h"
#import "KCCoreDataStack.h"

static NSString* const serverURL = @"http://localhost:3001/holidays";

@interface KCSyncData()

@property (nonatomic, strong) NSMutableArray *registeredClassesToSync;

@end

@implementation KCSyncData

//@synthesize registeredClassesToSync = _registeredClassesToSync;
//@synthesize syncInProgress = _syncInProgress;

#pragma mark singleton
+ (KCSyncData *)sharedSyncDataEngine {
    static KCSyncData *sharedEngine = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedEngine = [[KCSyncData alloc] init];
    });
    return sharedEngine;
}

//
- (void)startSync {
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

#pragma mark Helpers
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

#pragma Networking
// replace AFNetworking with NSURLSession
//
- (void)downloadDataForRegisteredObjects:(BOOL)useUpdatedAtDate {
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
                           if (error == nil) {
                               NSLog(@"obj class:%@", [arrayOfDict class]);
                               for (id jsonDict in arrayOfDict)
                               {
                                   if ([jsonDict isKindOfClass:[NSDictionary class]]) {
//                                       [self writeJSONResponse:jsonDict
//                                        toDiskForClassWithName:className];
                                       
                                       NSLog(@"Response for %@: %@", className, jsonDict);
                                   }else{
                                       NSLog(@"is not a dictionary is: %@", [jsonDict class]);
                                   }
                               }
                               // 1
                               // Need to write JSON files to disk
                               
                               // 2
                               // - Add a method here that takes the responses saved to disk and
                               //   processes them into Core Data.
                               // - Need to process JSON records into Core Data
                               //
                           }else{
                               NSLog(@"Request for class %@ failed with error: %@", className, error);
                           }
                       }
                   }];
        [dataTask resume]; //8
    }//end for each
}

#pragma mark - File Management
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

- (void)writeJSONResponse:(id)jsonResponse
   toDiskForClassWithName:(NSString *)className
{
    NSURL *fileURL = [NSURL URLWithString:className
                            relativeToURL:[self JSONDataRecordsDirectory]];
    
    if (![(NSDictionary *)jsonResponse writeToFile:[fileURL path] atomically:YES])
    {
        NSLog(@"Error saving response to disk, will attempt to remove NSNull values and try again.");
        
        // remove NSNulls and try again...
        // this key doesn't exist in my dict from the server
        NSArray *records = [jsonResponse objectForKey:@"results"];
        
        NSMutableArray *nullFreeRecords = [NSMutableArray array];
        for (NSDictionary *record in records)
        {
            NSMutableDictionary *nullFreeRecord = [NSMutableDictionary dictionaryWithDictionary:
                                                   record];
            [record enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                if ([obj isKindOfClass:[NSNull class]]) {
                    [nullFreeRecord setValue:nil forKey:key];
                }
            }];
            [nullFreeRecords addObject:nullFreeRecord];
        }
        NSDictionary *nullFreeDictionary = [NSDictionary dictionaryWithObject:nullFreeRecords
                                                                       forKey:@"results"];
        if (![nullFreeDictionary writeToFile:[fileURL path] atomically:YES])
        {
            NSLog(@"Failed all attempts to save response to disk: %@", jsonResponse);
        }
    }
}

@end
