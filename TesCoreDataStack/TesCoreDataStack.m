//
//  TesCoreDataStack.m
//  TesCoreDataStack
//
//  Created by Andres Kwan on 7/11/14.
//  Copyright (c) 2014 Kwan Castle. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "KCCoreDataStack.h"
#import "Holiday.h"

@interface TesCoreDataStack : XCTestCase
{
    KCCoreDataStack * _coreDataStack;
    
}
@end

@implementation TesCoreDataStack

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    _coreDataStack = [KCCoreDataStack shareCoreDataInstance];
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

-(void)testSaveMasterContext
{
    Holiday * holiday = [NSEntityDescription insertNewObjectForEntityForName:@"Holiday"
                                                      inManagedObjectContext:_coreDataStack.backgroundManagedObjectContext];
    holiday.details = @"details field";
    holiday.name    = @"Andres Kwan Orjuela";
    holiday.objectId= @"123456";
    
    [_coreDataStack backgroundManagedObjectContext];
    
}
@end
