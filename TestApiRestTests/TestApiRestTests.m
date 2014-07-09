//
//  TestApiRestTests.m
//  TestApiRestTests
//
//  Created by Andres Kwan on 6/19/14.
//  Copyright (c) 2014 Kwan Castle. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "KCSyncData.h"
#import "KCCoreDataStack.h"
#import <CoreData/CoreData.h>

@interface TestApiRestTests : XCTestCase{
    KCSyncData * _syncData;
    NSString * _className;
    NSString * _strTestDate;
    NSArray  * _jsonArray;
    NSArray  * _nsArrayJson;
    NSManagedObject * _newManagedObject;
}
@end

@implementation TestApiRestTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    _syncData    = [[KCSyncData alloc]init];
    _className   = @"Holiday";
    _strTestDate = @"2014-06-28T17:58:18.846Z";
    //@"2012-12-25T00:00:00.000Z";
    _nsArrayJson = nil;
    _jsonArray   = @[@{
                         @"__v" : @0,
                         @"_id" : @"53b43b98d557c1d512bfc180",
                         @"createdAt" : @"2014-07-02T17:04:24.339Z",
                         @"date" : @"1982-09-09T00:00:00.000Z",
                         @"details" : @"Give gifts",
                         @"image" : @"http://en.wikipedia.org/wiki/Main_Page#mediaviewer/File:Mouse_mechanism_diagram.svg",
                         @"name" : @"Andrea's Birthday",
                         @"observedBy" : @[
                                 @"US",
                                 @"COL"
                                 ],
                         @"syncStatus" : @0,
                         @"updatedAt" : @"2014-07-02T11:33:00.000Z",
                         @"wikipediaLink" : @"http://en.wikipedia.org/wiki/IOS_8"
                         },
                     @{
                         @"__v" : @0,
                         @"_id" : @"53b43cedd557c1d512bfc182",
                         @"createdAt" : @"2014-07-02T17:10:05.912Z",
                         @"date" : @"1982-03-16T00:00:00.000Z",
                         @"details" : @"Give gifts",
                         @"image" : @"http://en.wikipedia.org/wiki/Main_Page#mediaviewer/File:Mouse_mechanism_diagram.svg",
                         @"name" : @"Andres Wish",
                         @"observedBy" : @[
                                 @"US",
                                 @"COL"
                                 ],
                         @"syncStatus" : @0,
                         @"updatedAt" : @"2014-07-02T11:33:00.000Z",
                         @"wikipediaLink" : @"http://en.wikipedia.org/wiki/IOS_8"
                         }];
    
    _newManagedObject = [NSEntityDescription insertNewObjectForEntityForName:_className
                                                      inManagedObjectContext:
                                         [[KCCoreDataStack shareCoreDataInstance] backgroundManagedObjectContext]];

}
- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
    _syncData  = nil;
    _className = nil;
    _jsonArray = nil;
    _newManagedObject = nil;
}


#pragma mark Core Data Helpers



#pragma mark - Write plist(JSON) to disk
-(void)testApplicationCacheDirectory
{
    NSLog(@"##########################################");
    NSLog(@"NSURL of the location of the cache dir in the disk: \n%@", [_syncData applicationCacheDirectory]);
}
-(void)testJSONDataRecordsDirectory
{
    NSLog(@"##########################################");
    NSLog(@"NSURL of the location of the directory used to store plist with JSON data on the disk: \n%@", [_syncData JSONDataRecordsDirectory]);
}
-(void)testWriteJSONResponseToDiskForClassWithName
{
//    //1) be sure that is clean, no data stored on disk
    [_syncData deleteJSONDataRecordsForClassWithName:_className];
    _nsArrayJson = [_syncData JSONDictionaryForClassWithName:_className];
    //should be nil after deletion
    XCTAssertNil(_nsArrayJson, @"nsArrayJson is not nil, not deleted");

    //2) write data to the disk
    [_syncData writeJSONResponse:_jsonArray
          toDiskForClassWithName:_className];
    
    //3) verify that was writen
    _nsArrayJson = [_syncData JSONDictionaryForClassWithName:_className];
    XCTAssertNotNil(_nsArrayJson, @"nsArrayJson was nil, no data writed");
    
    //4) restore state, delete file
    [_syncData deleteJSONDataRecordsForClassWithName:_className];
    _nsArrayJson = [_syncData JSONDictionaryForClassWithName:_className];
    //should be nil after deletion
    XCTAssertNil(_nsArrayJson, @"nsArrayJson is not nil, not deleted");
}
#pragma mark Read plist(JSON) from disk
-(void)testJSONDictionaryForClassWithName
{
    //1) be sure there is data to read from disk
    [_syncData writeJSONResponse:_jsonArray
          toDiskForClassWithName:_className];
    
    //2) retrieve data form disk
    NSLog(@"##########################################");
    NSArray *  nsArrayJson = [_syncData JSONDictionaryForClassWithName:_className];
    XCTAssertNotNil(nsArrayJson, @"nsArrayJson was nil, no data stored on disk\n");
    for (NSDictionary* dict in nsArrayJson) {
        NSLog(@"ClassName: %@ NSDictionary:%@",_className, dict);
    }
    //3) restore state, delete file
    [_syncData deleteJSONDataRecordsForClassWithName:_className];
    _nsArrayJson = [_syncData JSONDictionaryForClassWithName:_className];
    //should be nil after deletion
    XCTAssertNil(_nsArrayJson, @"nsArrayJson is not nil, not deleted");

}
-(void)testJSONDataRecordsForClassSortedByKey
{
    NSArray * nsArraySorted = [_syncData JSONDataRecordsForClass:_className sortedByKey:@"createdAt"];
    for (NSDictionary* dict in nsArraySorted) {
        NSLog(@"ClassName: %@ NSDictionary:%@",_className, dict);
    }
}

#pragma mark Delete plist(JSON) on disk
-(void)testDeleteJSONDataRecordsForClassWithName
{
    NSLog(@"##########################################");
    //1) Set conditions - write data to the disk
    [_syncData writeJSONResponse:_jsonArray
          toDiskForClassWithName:_className];
    
    //2) verify that data was writen
    _nsArrayJson = [_syncData JSONDictionaryForClassWithName:_className];
    XCTAssertNotNil(_nsArrayJson, @"nsArrayJson was nil, no data writed");
    
    //3) delete data
    [_syncData deleteJSONDataRecordsForClassWithName:_className];
    _nsArrayJson = [_syncData JSONDictionaryForClassWithName:_className];
    //should be nil after deletion
    XCTAssertNil(_nsArrayJson, @"nsArrayJson is not nil, not deleted");
}

#pragma mark Date data manipulation
-(void)testCreateNSDateUsingString
{
    NSLog(@"##########################################");
    NSDate * nsDate = [_syncData dateUsingStringFromAPI:_strTestDate];
    NSLog(@"date from string: %@", nsDate);
}
-(void)testCreateDateStringUsingDate
{
    NSDate * nsDate = [_syncData dateUsingStringFromAPI:_strTestDate];
    NSLog(@"##########################################");
    NSString * nsStrDate = [_syncData dateStringForAPIUsingDate:nsDate];
    NSLog(@"date from date: %@", nsStrDate);
}

//////////////////////////////////////////////////////
#pragma mark - CoreData
//////////////////////////////////////////////////////
//to test I need
//1 managedObject

-(void)testSetValueForKeyForManagedObj
{
    
    [_jsonArray[0] enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [_syncData setValue:obj forKey:key forManagedObject:_newManagedObject];
    }];
    
    NSLog(@"\nnew NSManaged object: \n%@\n created from json(plist): \n%@\n",_newManagedObject,_jsonArray[0]);
}

#warning ToDo - how to assert? 
//a new nsmanagedObjt was created, not nil?
//but is not returned
//just added to the backgroundContext
-(void)testNewManagedObjWithClassNameForRecord
{
    [_syncData newManagedObjectWithClassName:_className
                                   forRecord:_jsonArray[0]];
}
//DONE
//
//- precondition
//
//none
//
//- parameters
//
//an Obj of type NSManagedObj to be sync
//
//- goal
//
//  to add the Name of the entities to be sync into the array
//  registeredClassesToSync
//1) instantiate a NSManagedObject
-(void)testRegisterNSManagedObjectClassToSync
{
//    [_syncData registerNSManagedObjectClassToSync:_newManagedObject];
}
//- precondition
//
//p1 _syncData.registeredClassesToSync must have at least one name of an entity to be sync
//p2 NSUserDefaults must have a key named kSDSyncEngineInitialCompleteKey with value YES or NO(import all downloaded)
//p3 plist with valid obj data most be stored on disk
//
//- parameters
//
//none
//
//- goal
//
//  to add the Name of the entities to be sync into the array
//  registeredClassesToSync
//1) instantiate a NSManagedObject
-(void)testProcessJSONDataRecordsIntoCoreData
{

    NSManagedObject * newManagedObject = [NSEntityDescription insertNewObjectForEntityForName:_className
                                                                         inManagedObjectContext:
                                            [[KCCoreDataStack shareCoreDataInstance] backgroundManagedObjectContext]];
    XCTAssertTrue([newManagedObject isKindOfClass:[NSManagedObject class]], @"%@ is not a nsmanagedObject",newManagedObject);
    
    //p1
//    [_syncData registerNSManagedObjectClassToSync:newManagedObject];
    [_syncData.registeredClassesToSync addObject:_className];
    XCTAssertTrue([[_syncData registeredClassesToSync] count] > 0 , @"registeredClassesToSync array is empty");
    
    
    //p2 //NO to test with imported data or data stored in the plist on the disk
    [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithBool:NO]
                                             forKey:@"SDSyncEngineInitialSyncCompleted"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    //p3
    [_syncData deleteJSONDataRecordsForClassWithName:_className];
    _nsArrayJson = [_syncData JSONDictionaryForClassWithName:_className];
    XCTAssertNil(_nsArrayJson, @"nsArrayJson is not nil, not deleted");
    [_syncData writeJSONResponse:_jsonArray
          toDiskForClassWithName:_className];
    _nsArrayJson = [_syncData JSONDictionaryForClassWithName:_className];
    XCTAssertNotNil(_nsArrayJson, @"nsArrayJson was nil, no data writed");
    [_syncData processJSONDataRecordsIntoCoreData];
}
@end
