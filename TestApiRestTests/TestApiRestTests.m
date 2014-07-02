//
//  TestApiRestTests.m
//  TestApiRestTests
//
//  Created by Andres Kwan on 6/19/14.
//  Copyright (c) 2014 Kwan Castle. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "KCSyncData.h"

@interface TestApiRestTests : XCTestCase

@end

@implementation TestApiRestTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.

}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

//- (void)testExample
//{
//    XCTFail(@"No implementation for \"%s\"", __PRETTY_FUNCTION__);
//    
//}

-(void)testDateUsingStringFromServer
{
    KCSyncData * syncData = [[KCSyncData alloc]init];
    NSString * strTestDate = @"2012-12-25T00:00:00.000Z";
    NSLog(@"##########################################");
    NSDate * nsDate = [syncData dateUsingStringFromAPI:strTestDate];
    NSLog(@"date string: %@", nsDate);
    NSLog(@"##########################################");
    NSString * nsStrDate = [syncData dateStringForAPIUsingDate:nsDate];
    NSLog(@"date string: %@", nsStrDate);
}

//-(void)test

@end
