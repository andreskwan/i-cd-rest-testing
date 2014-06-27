//
//  KCSyncData.m
//  TestApiRest
//
//  Created by Andres Kwan on 6/26/14.
//  Copyright (c) 2014 Kwan Castle. All rights reserved.
//

#import "KCSyncData.h"
#import "KCCoreDataStack.h"


@interface KCSyncData()

@property (nonatomic, strong) NSMutableArray *registeredClassesToSync;

@end

@implementation KCSyncData

@synthesize registeredClassesToSync = _registeredClassesToSync;


+ (KCSyncData *)sharedSyncDataEngine {
    static KCSyncData *sharedEngine = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedEngine = [[KCSyncData alloc] init];
    });
    return sharedEngine;
}

//store the NSManagedObjects in an array that will be used for sync
- (void)registerNSManagedObjectClassToSync:(Class)aClass
{
    if (!self.registeredClassesToSync) {
        self.registeredClassesToSync = [NSMutableArray array];
    }
    if ([aClass isSubclassOfClass:[NSManagedObject class]]) {
        //does the array have the object?
        if (![self.registeredClassesToSync containsObject:NSStringFromClass(aClass)]) {
            
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
                                 [NSSortDescriptor sortDescriptorWithKey:@"updatedAt" ascending:
                                  NO]]];
    //
    // You are only interested in 1 result so limit the request to 1
    //
    [request setFetchLimit:1];
    [[[KCCoreDataStack shareCoreDataInstance] backgroundManagedObjectContext] performBlockAndWait:^{
         NSError *error = nil;
         NSArray *results = [[[KCCoreDataStack shareCoreDataInstance] backgroundManagedObjectContext]
                             executeFetchRequest:request error:&error];
         if ([results lastObject]) {
             //
             // Set date to the fetched result
             //
             date = [[results lastObject] valueForKey:@"updatedAt"];
         }
     }];
    return date;
}

@end
