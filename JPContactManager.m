//
//  JPContactManager.m
//  JPCertificationKit
//
//  Created by Damon Gao on 2018/8/24.
//  Copyright © 2018年 Damon. All rights reserved.
//

#import "JPContactManager.h"
//iOS9UI的库
#import <ContactsUI/ContactsUI.h>
#import "JPAddressBookController.h"
#import "JPAlertViewManager.h"
#import "JPBasicUtil.h"

@interface JPContactManager () <CNContactPickerDelegate>

@property (nonatomic, copy) completionBlock completion;

@end

@implementation JPContactManager

+ (instancetype)shareManager
{
    static JPContactManager *_instance;
    @synchronized(self) {
        if (!_instance) {
            _instance = [[JPContactManager alloc] init];
        }
    }
    return _instance;
}

- (void)dealloc
{
    self.completion = nil;
    self.selectBlock = nil;
}

- (void)showContactBook:(id)target
            contactInfo:(NSArray *)contactInfo
                 result:(JPAddressSelectBlock)block
                 finish:(completionBlock)completion
{
    self.target = target;
    self.selectBlock = block;
    self.addressArr = contactInfo;
    self.completion = completion;
    
    if (@available(iOS 9.0, *)) {
        // 系统通讯录
        CNContactPickerViewController *contactVC = [[CNContactPickerViewController alloc] init];
        contactVC.delegate = self;
        /**
         如果要在通讯录详情中展示具体信息,可配置如下属性
         contactVC.displayedPropertyKeys = @[CNContactPhoneNumbersKey];
         */
        [self.target presentViewController:contactVC animated:YES completion:nil];
    } else {
        // 自定义通讯录
        JPAddressBookController *addressBookVC = [[JPAddressBookController alloc] init];
        addressBookVC.addressArr = self.addressArr;
        addressBookVC.selectBlock = self.selectBlock;
        addressBookVC.completion = self.completion;
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:addressBookVC];
        [self.target presentViewController:nav animated:YES completion:nil];
    }
}

/** 获取通讯录权限 */
+ (void)getAddressBookAuth:(void (^)(BOOL hasAuth, JPAddressBookAuthStatus status))authResult {
    if (@available(iOS 9.0, *)) {
        CNAuthorizationStatus status = [CNContactStore authorizationStatusForEntityType:CNEntityTypeContacts];
        if (status == CNAuthorizationStatusNotDetermined) {
            CNContactStore *store = [[CNContactStore alloc] init];
            [store requestAccessForEntityType:CNEntityTypeContacts completionHandler:^(BOOL granted, NSError*  _Nullable error) {
                if (granted) {
                    NSLog(@"JPSDK: 通讯录成功授权");
                    if (authResult) {
                        authResult(YES, JPAddressBookAuthStatusAuthorized);
                    }
                } else {
                    NSLog(@"JPSDK: 通讯录授权失败");
                    if (authResult) {
                        authResult(NO, JPAddressBookAuthStatusDenied);
                    }
                }
            }];
        }
        else if(status == CNAuthorizationStatusRestricted)
        {
            NSLog(@"JPSDK: 通讯录用户拒绝");
            if (authResult) {
                authResult(NO, JPAddressBookAuthStatusDenied);
            }
        }
        else if (status == CNAuthorizationStatusDenied)
        {
            NSLog(@"JPSDK: 通讯录用户拒绝");
            if (authResult) {
                authResult(NO, JPAddressBookAuthStatusDenied);
            }
        }
        else if (status == CNAuthorizationStatusAuthorized) //已经授权
        {
            NSLog(@"JPSDK: 通讯录成功授权");
            if (authResult) {
                authResult(YES, JPAddressBookAuthStatusAuthorized);
            }
        }
    } else {
        // 用于记录访问通讯录授权是否成功 (iOS8.0及以上)
        ABAuthorizationStatus authorizationStatus = ABAddressBookGetAuthorizationStatus();
        if (authorizationStatus == kABAuthorizationStatusNotDetermined) {
            // 没有授权
            ABAddressBookRef addBook = ABAddressBookCreateWithOptions(NULL, NULL);
            ABAddressBookRequestAccessWithCompletion(addBook, ^(bool granted, CFErrorRef error) {
                // granted=YES表示用户允许, 否则为不允许
                if (granted) {
                    NSLog(@"JPSDK: 通讯录成功授权");
                    if (authResult) {
                        authResult(YES, JPAddressBookAuthStatusAuthorized);
                    }
                } else {
                    NSLog(@"JPSDK: 通讯录授权失败");
                    if (authResult) {
                        authResult(NO, JPAddressBookAuthStatusDenied);
                    }
                }
            });
        } else if (authorizationStatus == kABAuthorizationStatusAuthorized) {
             //已经授权
            NSLog(@"JPSDK: 通讯录成功授权");
            if (authResult) {
                authResult(YES, JPAddressBookAuthStatusAuthorized);
            }
        } else {
            NSLog(@"JPSDK: 通讯录用户拒绝");
            if (authResult) {
                authResult(NO, JPAddressBookAuthStatusDenied);
            }
        }
    }
}

#pragma mark - CNContactPickerDelegate
- (void)contactPickerDidCancel:(CNContactPickerViewController *)picker  API_AVAILABLE(ios(9.0)) {
    [picker dismissViewControllerAnimated:YES completion:^{
        if (self.completion) {
            self.completion();
        }
    }];
}

- (void)contactPicker:(CNContactPickerViewController *)picker didSelectContact:(CNContact *)contact  API_AVAILABLE(ios(9.0)){
    
    NSMutableArray *phones = [NSMutableArray array];
    for (CNLabeledValue *label in contact.phoneNumbers) {
        NSString *phoneLabel = [[label value] stringValue];
        if (phoneLabel.length > 1) {
            [phones addObject:phoneLabel];
        }
    }
    if (contact.phoneNumbers == nil ||
        [contact.phoneNumbers count] == 0 ||
        [phones count] == 0) {
        [phones addObject:@""];
    }
    
    NSString *first = contact.givenName;
    if (first == nil) {
        first = @"";
    }
    NSString *last = contact.familyName;
    if (last == nil) {
        last = @"";
    }
    
    NSString *phone = [phones firstObject];
    NSString *name = [NSString stringWithFormat:@"%@%@", last, first];
    phone = [phone stringByReplacingOccurrencesOfString:@" " withString:@""];
    phone = [phone stringByReplacingOccurrencesOfString:@"-" withString:@""];
    phone = [phone stringByReplacingOccurrencesOfString:@"+86" withString:@""];
    phone = [phone stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if ([phone hasPrefix:@"86"]) {
        phone = [phone substringFromIndex:2];
    }
    if (![JPBasicUtil validateNumber:phone]) {
        phone = @"";
    }
    name = [JPBasicUtil dealWithNameDeleteEmoji:name];
    phone = [JPBasicUtil dealWithPhoneFromAddressBook:phone];
    NSString *json = [JPBasicUtil jsonStringFromObject:@{@"contactsName":name,@"contactsPhone":phone}];
    if (self.selectBlock) {
        self.selectBlock(name, phone, json);
    }
    [picker dismissViewControllerAnimated:YES completion:^{
        if (self.completion) {
            self.completion();
        }
    }];
}

/**
 获取通讯录联系人信息
 
 @param content 联系人信息(vcard:原始通讯录信息, addressBookRec:处理后的通讯录信息)
 */
- (void)getAddressBookContent:(void (^)(NSArray *vcard, NSArray *addressBookRec))content
{
    NSArray *vcardArr = [self getAddressBook];
    
    NSMutableArray *jsonArr = [NSMutableArray array];
    for (Person *person in vcardArr) {
        NSString *name = [JPBasicUtil dealWithNameWhetherContainEmoji:person.name];
        NSString *phone = [JPBasicUtil dealWithPhoneFromAddressBook:person.telphone];
        [jsonArr addObject:@{@"contactsName":name,@"contactsPhone":phone}];
    }
    NSArray *addressBookRecArr = [jsonArr copy];
    content(vcardArr, addressBookRecArr);
}

#pragma mark - 获取通讯录
- (NSArray *)getAddressBook {
    // 获取通讯录
    NSMutableDictionary *dic = [[JPAddressBook shareControl] getPersonInfo];
    // 获得序列索引
    NSArray *array = [[JPAddressBook shareControl] sortMethod];
    // 所有通讯录信息
    NSArray *vcardArr = [Person getAllPersonVcard:dic andShot:array];
    return vcardArr;
}

#pragma mark - 废弃
- (BOOL)getAuthWithAddressBook {
    /**
     if (@available(iOS 9.0, *)) {
     CNAuthorizationStatus status = [CNContactStore authorizationStatusForEntityType:CNEntityTypeContacts];
     if (status == CNAuthorizationStatusAuthorized) { //有权限时
     }
     } */
    
    // 用于记录访问通讯录授权是否成功 (iOS8.0及以上)
    int __block tip = 0;
    ABAddressBookRef addBook = ABAddressBookCreateWithOptions(NULL, NULL);
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    ABAddressBookRequestAccessWithCompletion(addBook, ^(bool granted, CFErrorRef error) {
        // granted=YES表示用户允许, 否则为不允许
        if (!granted) {
            tip = 1;
        }
        // 发送一次信号
        dispatch_semaphore_signal(sema);
    });
    // 等待信号触发
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    if (tip) {
        [JPAlertViewManager showAuthAlertViewOn:self.target alertType:JPAlertAuthTypeAddressBook cancleButtonEvent:^{}];
        return NO;
    }
    return YES;
}

@end
