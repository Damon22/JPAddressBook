//
//  Person.m
//  AddressBookTest
//
//  Created by 高继鹏 on 15/11/3.
//  Copyright © 2015年 GaoJipeng. All rights reserved.
//

#import "Person.h"
#import "JPDebugMacro.h"

@implementation Person

- (id)valueForUndefinedKey:(NSString *)key
{
    JPLog(@"JPSDK -> Person 找不到对应的key:%@",key);
    return @"";
}

- (NSString *)last
{
    if (_last == nil) {
        return @"";
    }
    return _last;
}

- (NSString *)first
{
    if (_first == nil) {
        return @"";
    }
    return _first;
}

+ (NSArray *)getAllPersonVcard:(NSDictionary *)vcardDic andShot:(NSArray *)shortArr
{
    NSMutableArray *mutableArr = [[NSMutableArray alloc] init];
    for (NSString *shortStr in shortArr) {
        NSArray *groupArr = [vcardDic objectForKey:shortStr];
        for (NSDictionary *personDic in groupArr) {
            Person *person = [[Person alloc] init];
            [person setValuesForKeysWithDictionary:personDic];
            NSString *name = [NSString stringWithFormat:@"%@%@",person.last,person.first];
            person.name = name;
            [mutableArr addObject:person];
        }
    }
    return (NSArray *)mutableArr;
}


@end
