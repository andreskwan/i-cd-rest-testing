//
//  Holiday.h
//  TestApiRest
//
//  Created by Andres Kwan on 7/7/14.
//  Copyright (c) 2014 Kwan Castle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Holiday : NSManagedObject

@property (nonatomic) NSTimeInterval createdAt;
@property (nonatomic) NSTimeInterval date;
@property (nonatomic, retain) NSString * details;
@property (nonatomic, retain) NSString * image;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * objectId;
@property (nonatomic, retain) id observedBy;
@property (nonatomic) int16_t syncStatus;
@property (nonatomic) NSTimeInterval updatedAt;
@property (nonatomic, retain) NSString * wikipediaLink;

@end
