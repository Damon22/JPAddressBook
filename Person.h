//
//  Person.h
//  AddressBookTest
//
//  Created by 高继鹏 on 15/11/3.
//  Copyright © 2015年 GaoJipeng. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Person : NSObject

@property (nonatomic, copy) NSString *first;
@property (nonatomic, copy) NSString *last;
@property (nonatomic, copy) NSString *telphone;
@property (nonatomic, copy) NSString *name;

+ (NSArray *)getAllPersonVcard:(NSDictionary *)vcardDic andShot:(NSArray *)shortArr;

@end
