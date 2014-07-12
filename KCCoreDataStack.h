//
//  KCCoreDataStack.h
//  Apple-E1
//
//  Created by Andres Kwan on 6/3/14.
//  Copyright (c) 2014 Kwan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface KCCoreDataStack : NSObject

//Like id
//this is the singleton
+(instancetype)shareCoreDataInstance;


@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) NSManagedObjectContext           *backgroundManagedObjectContext;
@property (strong, nonatomic) NSManagedObjectContext           *masterManagedObjectContext;


@property (readonly, strong, nonatomic) NSManagedObjectModel         *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;



- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;
- (void)saveMasterContext;
- (void)saveBackgroundContext;

- (void)newManagedObjectWithClassName:(NSString *)className
                            forRecord:(NSDictionary *)record;

@end
