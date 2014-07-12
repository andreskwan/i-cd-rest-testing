//
//  KCCoreDataStack.m
//  Apple-E1
//
//  Created by Andres Kwan on 6/3/14.
//  Copyright (c) 2014 Kwan. All rights reserved.
//

#import "KCCoreDataStack.h"

@implementation KCCoreDataStack

@synthesize managedObjectContext       = _managedObjectContext;
@synthesize managedObjectModel         = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

@synthesize masterManagedObjectContext = _masterManagedObjectContext;
@synthesize backgroundManagedObjectContext = _backgroundManagedObjectContext;


+(instancetype)shareCoreDataInstance
{
    //static variables exist only once in our app
    static KCCoreDataStack *shareCoreDataInstance;
    //
    static dispatch_once_t  onceToken;
    
    //using grand central dispatch
    dispatch_once(&onceToken, ^{
        //will be execute only once
        //It could have a better name
        shareCoreDataInstance = [[self alloc] init];
    });
    return shareCoreDataInstance;
}
#pragma mark - Core Data stack


// Used to propegate saves to the persistent store (disk) without blocking the UI
// Master
// runs in an independent thread
- (NSManagedObjectContext *)masterManagedObjectContext
{
    if (_masterManagedObjectContext != nil) {
        return _masterManagedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        _masterManagedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        //why block and wait??
        //to allow to perform safely??
        [_masterManagedObjectContext performBlockAndWait:^{
            [_masterManagedObjectContext setPersistentStoreCoordinator:coordinator];
        }];
        
    }
    return _masterManagedObjectContext;
}

// Return the NSManagedObjectContext to be used in the background during sync
// runs in an independent thread
- (NSManagedObjectContext *)backgroundManagedObjectContext
{
    if (_backgroundManagedObjectContext != nil) {
        return _backgroundManagedObjectContext;
    }
    
    NSManagedObjectContext *masterContext = [self masterManagedObjectContext];
    if (masterContext != nil) {
        _backgroundManagedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        [_backgroundManagedObjectContext performBlockAndWait:^{
            [_backgroundManagedObjectContext setParentContext:masterContext];
        }];
    }
    
    return _backgroundManagedObjectContext;
}

//lazy instantiation
// Returns the managed object context for the application.
// If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
//- (NSManagedObjectContext *)managedObjectContext
//{
//    if (_managedObjectContext != nil) {
//        return _managedObjectContext;
//    }
//    
//    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
//    if (coordinator != nil) {
//        _managedObjectContext = [[NSManagedObjectContext alloc] init];
//        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
//    }
//    return _managedObjectContext;
//}

// Return the NSManagedObjectContext to be used in the background during sync
- (NSManagedObjectContext *)managedObjectContext
{
    NSManagedObjectContext *newContext = nil;
    NSManagedObjectContext *masterContext = [self masterManagedObjectContext];
    if (masterContext != nil) {
        newContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        [newContext performBlockAndWait:^{
            [newContext setParentContext:masterContext];
        }];
    }
    
    return newContext;
}

- (void)saveContext
{
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
    #warning ToDo - this should not be in production
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}
- (void)saveMasterContext
{
   if (self.masterManagedObjectContext != nil) {
    [self.masterManagedObjectContext performBlockAndWait:^{
        NSError *error = nil;
        BOOL changed = [self.masterManagedObjectContext hasChanges];
        BOOL saved = [self.masterManagedObjectContext save:&error];
        if (changed && !saved) {
            // do some real error handling
            NSLog(@"Could not save master context due to %@", error);
        }
    }];
   }
}
- (void)saveBackgroundContext
{
    if (self.backgroundManagedObjectContext != nil) {
        [self.backgroundManagedObjectContext performBlockAndWait:^{
            NSError *error = nil;
            BOOL changed = [self.backgroundManagedObjectContext hasChanges];
            BOOL saved = [self.backgroundManagedObjectContext save:&error];
            if ( changed && !saved) {
                // do some real error handling
                NSLog(@"Could not save background context due to %@", error);
            }
        }];
    }
}

// Returns the managed object model for the application.
// If the model doesn't already exist, it is created from the application's model.
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    #warning ToDo - CHANGE modelURL
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"TestApiRest"
                                              withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

// Returns the persistent store coordinator for the application.
// If the coordinator doesn't already exist, it is created and the application's store added to it.
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    //where our data store is going to live
    #warning ToDo - CHANGE storeURL
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"TestApiRest.sqlite"];
    
    NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
         
         Typical reasons for an error here include:
         * The persistent store is not accessible;
         * The schema for the persistent store is incompatible with current managed object model.
         Check the error message to determine what the actual problem was.
         
         If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
         
         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
         * Simply deleting the existing store:
         [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
         
         * Performing automatic lightweight migration by passing the following dictionary as the options parameter:
         @{NSMigratePersistentStoresAutomaticallyOption:@YES, NSInferMappingModelAutomaticallyOption:@YES}
         
         Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
         
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        #warning ToDo -  this should not be in production
        abort();
    }
    return _persistentStoreCoordinator;
}

#pragma mark - Application's Documents directory

// Returns the URL to the application's Documents directory.
- (NSURL *)applicationDocumentsDirectory
{
    NSURL *urlDB = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory
                                                   inDomains:NSUserDomainMask]
            lastObject];
    //allows me to interact with the DB in my mac
    NSLog(@"DB path:\n%@",urlDB);
    return urlDB;
}

@end


