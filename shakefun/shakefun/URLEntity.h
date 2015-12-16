//
//  URLEntity.h
//  shakefun
//
//  Created by zm on 15/9/9.
//  Copyright (c) 2015年 zm. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface URLEntity : NSManagedObject

@property (nonatomic, retain) NSString * fullurl;
@property (nonatomic, retain) NSString * filename;

@end
