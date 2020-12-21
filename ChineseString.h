//
//  ChineseString.h
//  YUChineseSorting
//
//  Created by Gaojipeng on 15-11-3.
//  Copyright (c) 2014年 Damon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "pinyin.h"

@interface ChineseString : NSObject

@property (nonatomic, retain) NSString *string;
@property (nonatomic, retain) NSString *pinYin;
@property (nonatomic, retain) NSString *telphone;

//-----  返回tableview右方indexArray
+ (NSMutableArray*)IndexArray:(NSArray*)stringArr;

//-----  返回联系人
+ (NSMutableArray*)LetterSortArray:(NSArray*)stringArr;

//-----  返回联系人字典
+ (NSMutableDictionary*)LetterSortWithArray:(NSArray*)stringArr;
/*
 返回字典为
 Name:所有名字数组
 phone:所有电话数组
 */

///----------------------
//返回一组字母排序数组(中英混排)
+ (NSMutableArray*)SortArray:(NSArray*)stringArr;

@end
