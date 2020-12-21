//
//  JPContactManager.h
//  JPCertificationKit
//
//  Created by Damon Gao on 2018/8/24.
//  Copyright © 2018年 Damon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JPAddressBook.h"
#import "Person.h"

/**
 选择的通讯录信息

 @param name            选择的通讯录姓名
 @param phone           选择的通讯录手机号
 @param namePhoneJson   姓名手机号json
 */
typedef void(^JPAddressSelectBlock)(NSString *name, NSString *phone, NSString *namePhoneJson);
/** 完成回调 */
typedef void(^completionBlock)(void);

/** 通讯录权限 */
typedef NS_ENUM(NSInteger, JPAddressBookAuthStatus) {
    /** 未授权 */
    JPAddressBookAuthStatusNotDetermined,
    /** 已授权 */
    JPAddressBookAuthStatusAuthorized,
    /** 已拒绝 */
    JPAddressBookAuthStatusDenied
};


/**
 通讯录管理
 */
@interface JPContactManager : NSObject

@property (nonatomic, weak) id target;
@property (nonatomic, copy) JPAddressSelectBlock selectBlock;
/** 通讯录 */
@property (nonatomic, strong) NSArray *addressArr;

+ (instancetype)shareManager;

/**
 获取通讯录权限

 @param authResult 授权信息
 */
+ (void)getAddressBookAuth:(void (^)(BOOL hasAuth, JPAddressBookAuthStatus status))authResult;


/**
 展示通讯录

 @param target 目标控制器
 @param contactInfo 通讯录
 @param block 结果block
 @param completion 完成block
 */
- (void)showContactBook:(id)target
            contactInfo:(NSArray *)contactInfo
                 result:(JPAddressSelectBlock)block
                 finish:(completionBlock)completion;


/**
 获取通讯录联系人信息

 @param content 联系人信息(vcard:原始通讯录信息, addressBookRec:处理后的通讯录信息)
 */
- (void)getAddressBookContent:(void (^)(NSArray *vcard, NSArray *addressBookRec))content;


@end
