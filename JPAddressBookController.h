//
//  JPAddressBookController.h
//  JuziSDKDemo
//
//  Created by Damon Gao on 2018/6/6.
//  Copyright © 2018年 Damon. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 选择的通讯录信息
 
 @param name            选择的通讯录姓名
 @param phone           选择的通讯录手机号
 @param namePhoneJson   姓名手机号json
 */
typedef void(^JPAddressSelectBlock)(NSString *name, NSString *phone, NSString *namePhoneJson);
/** 完成回调 */
typedef void(^completionBlock)(void);


/**
 自定义通讯录界面
 */
@interface JPAddressBookController : UIViewController

/** 通讯录 */
@property (nonatomic, strong) NSArray *addressArr;
@property (nonatomic, copy) JPAddressSelectBlock selectBlock;
@property (nonatomic, copy) completionBlock completion;

@end
