//
//  ChineseString.m
//  YUChineseSorting
//
//  Created by Gaojipeng on 15-11-3.
//  Copyright (c) 2014年 Damon. All rights reserved.
//

#import "ChineseString.h"
#import "Person.h"

@implementation ChineseString
@synthesize string;
@synthesize pinYin;

#pragma mark - 返回tableview右方 indexArray
+ (NSMutableArray*)IndexArray:(NSArray*)stringArr
{
    
    NSMutableArray *tempArray = [self ReturnSortChineseArray:stringArr];
    NSMutableArray *A_Result=[NSMutableArray array];
    NSString *tempString ;
    
    for (NSString* object in tempArray)
    {
        NSString *pinyin = [((ChineseString*)object).pinYin substringToIndex:1];
        //不同
        if(![tempString isEqualToString:pinyin])
        {
            // NSLog(@"IndexArray----->%@",pinyin);
            [A_Result addObject:pinyin];
            tempString = pinyin;
        }
    }
    return A_Result;
}

#pragma mark - 返回联系人
+ (NSMutableArray*)LetterSortArray:(NSArray*)stringArr
{
    NSMutableArray *tempArray = [self ReturnSortChineseArray:stringArr];
    NSMutableArray *LetterResult=[NSMutableArray array];
    NSMutableArray *item = [NSMutableArray array];
    NSString *tempString ;
    //拼音分组
    for (ChineseString* object in tempArray) {
        
        NSString *pinyin = [((ChineseString*)object).pinYin substringToIndex:1];
        NSString *string = ((ChineseString*)object).string;
        //不同
        if(![tempString isEqualToString:pinyin])
        {
            //分组
            item = [NSMutableArray array];
            [item  addObject:string];
            [LetterResult addObject:item];
            //遍历
            tempString = pinyin;
        }else//相同
        {
            [item  addObject:string];
        }
    }
    return LetterResult;
}

//-----  返回联系人字典
+ (NSMutableDictionary*)LetterSortWithArray:(NSArray*)stringArr
{
    NSMutableDictionary *resultDic = [[NSMutableDictionary alloc] init];
    NSMutableArray *tempArray = [self ReturnSortChineseArray:stringArr];
    NSMutableArray *LetterResult=[NSMutableArray array];    //姓名
    NSMutableArray *TelphoResult=[NSMutableArray array];    //电话
    NSMutableArray *item = [NSMutableArray array];      //姓名
    NSMutableArray *telItem = [NSMutableArray array];   //电话
    NSString *tempString ;
    //拼音分组
    for (ChineseString* object in tempArray) {
        
        NSString *pinyin = [((ChineseString*)object).pinYin substringToIndex:1];
        NSString *string = ((ChineseString*)object).string;
        long length = [object.telphone length];
        NSString *telphone = [((ChineseString*)object).telphone substringToIndex:length];
        //不同
        if(![tempString isEqualToString:pinyin])
        {
            //分组
            item        = [NSMutableArray array];
            telItem     = [NSMutableArray array];
            
            [item  addObject:string];
            [telItem addObject:telphone];
            [TelphoResult addObject:telItem];
            [LetterResult addObject:item];
            //遍历
            tempString = pinyin;
        }else//相同
        {
            [telItem addObject:telphone];
            [item  addObject:string];
        }
    }
    [resultDic setObject:LetterResult forKey:@"Name"];
    [resultDic setObject:TelphoResult forKey:@"phone"];
    return resultDic;
}


//过滤指定字符串   里面的指定字符根据自己的需要添加
+ (NSString*)RemoveSpecialCharacter: (NSString *)str {
    NSRange urgentRange = [str rangeOfCharacterFromSet: [NSCharacterSet characterSetWithCharactersInString: @",.？、 ~￥#&<>《》()[]{}【】^@/￡¤|§¨「」『』￠￢￣~@#&*（）——+|《》$_€"]];
    if (urgentRange.location != NSNotFound)
    {
        return [self RemoveSpecialCharacter:[str stringByReplacingCharactersInRange:urgentRange withString:@""]];
    }
    return str;
}

///////////////////
//
//返回排序好的字符拼音
//
///////////////////
+ (NSMutableArray*)ReturnSortChineseArray:(NSArray*)stringArr
{
    //获取字符串中文字的拼音首字母并与字符串共同存放
    NSMutableArray *chineseStringsArray=[NSMutableArray array];
    for(int i=0; i<[stringArr count]; i++)
    {
        ChineseString *chineseString = [[ChineseString alloc] init];
        Person *person = [stringArr objectAtIndex:i];
        chineseString.string = person.name;
        chineseString.telphone = person.telphone;
        if ([chineseString.telphone isEqualToString:@""] || [chineseString.telphone isEqualToString:@" "]) {
            continue;
        }
//        chineseString.string=[NSString stringWithString:[stringArr objectAtIndex:i]];
        
        if(chineseString.string == nil){
            chineseString.string = @"";
        }
        //去除两端空格和回车
        chineseString.string = [chineseString.string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        
        //此方法存在一些问题 有些字符过滤不了
        //NSCharacterSet *set = [NSCharacterSet characterSetWithCharactersInString:@"@／：；（）¥「」＂、[]{}#%-*+=_\\|~＜＞$€^•'@#$%^&*()_+'\""];
        //chineseString.string = [chineseString.string stringByTrimmingCharactersInSet:set];
        
        
        //这里我自己写了一个递归过滤指定字符串   RemoveSpecialCharacter
        chineseString.string =[ChineseString RemoveSpecialCharacter:chineseString.string];
        // NSLog(@"string====%@",chineseString.string);
        
        
        //判断首字符是否为字母
        NSString *regex = @"[A-Za-z]+";
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@",regex];
        NSString *initialStr = [chineseString.string length]?[chineseString.string substringToIndex:1]:@"";
        if ([predicate evaluateWithObject:initialStr])
        {
            //NSLog(@"chineseString.string== %@",chineseString.string);
            //首字母大写
            chineseString.pinYin = [chineseString.string capitalizedString] ;
        }else{
            if(![chineseString.string isEqualToString:@""]){
                NSString *pinYinResult = [NSString string];
                for(int j=0; j<chineseString.string.length; j++){
                    NSString *singlePinyinLetter = [[NSString stringWithFormat:@"%c", pinyinFirstLetter([chineseString.string characterAtIndex:j])] uppercaseString];
                    //NSLog(@"singlePinyinLetter ==%@",singlePinyinLetter);
                    pinYinResult = [pinYinResult stringByAppendingString:singlePinyinLetter];
                }
                chineseString.pinYin = pinYinResult;
            }else{
                chineseString.pinYin = @"";
                if ([chineseString.string isEqualToString:@""]) {
                    continue;
                }
            }
        }
        
        [chineseStringsArray addObject:chineseString];
    }
    //按照拼音首字母对这些Strings进行排序
    NSArray *sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"pinYin" ascending:YES]];
    [chineseStringsArray sortUsingDescriptors:sortDescriptors];
    
    /**
    for(int i=0;i<[chineseStringsArray count];i++){
        NSLog(@"chineseStringsArray====%@",((ChineseString*)[chineseStringsArray objectAtIndex:i]).pinYin);
    }
     */
    
    return chineseStringsArray;
    
}

#pragma mark - 返回一组字母排序数组
+ (NSMutableArray*)SortArray:(NSArray*)stringArr
{
    NSMutableArray *tempArray = [self ReturnSortChineseArray:stringArr];
    
    //把排序好的内容从ChineseString类中提取出来
    NSMutableArray *result = [NSMutableArray array];
    for(int i=0; i<[stringArr count]; i++){
        [result addObject:((ChineseString*)[tempArray objectAtIndex:i]).string];
        //NSLog(@"SortArray----->%@",((ChineseString*)[tempArray objectAtIndex:i]).string);
    }
    return result;
}

@end
