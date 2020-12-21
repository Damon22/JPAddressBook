//
//  JPAddressBook.m
//  JPCertificationKit
//
//  Created by Damon Gao on 2018/8/8.
//  Copyright © 2018年 Damon. All rights reserved.
//

#import "JPAddressBook.h"
#import "pinyin.h"
#import <AddressBook/AddressBook.h>
#import "JPConfigHeader.h"

static JPAddressBook *instance;

@implementation JPAddressBook

- (instancetype)init
{
    if (self = [super init]) {
    }
    return self;
}

// 单列模式
+ (JPAddressBook *)shareControl{
    @synchronized(self) {
        if(!instance) {
            instance = [[JPAddressBook alloc] init];
        }
    }
    return instance;
}

#pragma mark 添加联系人
// 添加联系人（联系人名称、号码、号码备注标签）
- (BOOL)addContactName:(NSString *)name phoneNum:(NSString *)num withLabel:(NSString *)label {
    if (@available(iOS 9.0, *)) {
        //添加的联系人
        CNMutableContact *contact = [[CNMutableContact alloc] init];
        // contact.familyName = @"iOS9姓氏";
        contact.givenName = name;
        contact.phoneNumbers = @[[CNLabeledValue labeledValueWithLabel:CNLabelPhoneNumberiPhone value:[CNPhoneNumber phoneNumberWithStringValue:label]]];
        
        //设置一个请求
        CNSaveRequest *request = [[CNSaveRequest alloc] init];
        //添加这个联系人
        [request addContact:contact toContainerWithIdentifier:nil];
        //联系人写入
        CNContactStore *store = [[CNContactStore alloc] init];
        //返回成功与否
        return [store executeSaveRequest:request error:nil];
        
    } else {
        // 创建一条空的联系人
        ABRecordRef record = ABPersonCreate();
        CFErrorRef error;
        // 设置联系人的名字
        ABRecordSetValue(record, kABPersonFirstNameProperty, (__bridge CFTypeRef)name, &error);
        // 添加联系人电话号码以及该号码对应的标签名
        ABMutableMultiValueRef multi = ABMultiValueCreateMutable(kABPersonPhoneProperty);
        ABMultiValueAddValueAndLabel(multi, (__bridge CFTypeRef)num, (__bridge CFTypeRef)label, NULL);
        ABRecordSetValue(record, kABPersonPhoneProperty, multi, &error);
        ABAddressBookRef addressBook = nil;
        // 如果为iOS6以上系统，需要等待用户确认是否允许访问通讯录。
        if ([[UIDevice currentDevice].systemVersion floatValue] >= 6.0) {
            addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
            //等待同意后向下执行
            dispatch_semaphore_t sema = dispatch_semaphore_create(0);
            ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
                dispatch_semaphore_signal(sema);
            });
            dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
            dispatch_release(sema);
        } else {
            addressBook = ABAddressBookCreate();
        }
        // 将新建联系人记录添加如通讯录中
        BOOL success = ABAddressBookAddRecord(addressBook, record, &error);
        if (!success) {
            return NO;
        } else {
            // 如果添加记录成功，保存更新到通讯录数据库中
            success = ABAddressBookSave(addressBook, &error);
            return success ? YES : NO;
        }
    }
}

#pragma mark 指定号码是否已经存在
- (ABHelperCheckExistResultType)existPhone:(NSString *)phoneNum {
    ABAddressBookRef addressBook = nil;
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 6.0) {
        addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
        //等待同意后向下执行
        dispatch_semaphore_t sema = dispatch_semaphore_create(0);
        ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
            dispatch_semaphore_signal(sema);
        });
        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
        dispatch_release(sema);
    } else {
        addressBook = ABAddressBookCreate();
    }
    CFArrayRef records;
    if (addressBook) {
        // 获取通讯录中全部联系人
        records = ABAddressBookCopyArrayOfAllPeople(addressBook);
    } else {
        return ABHelperCanNotConncetToAddressBook;
    }
    // 遍历全部联系人，检查是否存在指定号码
    for (int i=0; i<CFArrayGetCount(records); i++) {
        ABRecordRef record = CFArrayGetValueAtIndex(records, i);
        CFTypeRef items = ABRecordCopyValue(record, kABPersonPhoneProperty);
        CFArrayRef phoneNums = ABMultiValueCopyArrayOfAllValues(items);
        if (phoneNums) {
            for (int j=0; j<CFArrayGetCount(phoneNums); j++) {
                NSString *phone = (NSString*)CFArrayGetValueAtIndex(phoneNums, j);
                if ([phone isEqualToString:phoneNum]) {
                    return ABHelperExistSpecificContact;
                }
            }
        }
    }
    CFRelease(addressBook);
    return ABHelperNotExistSpecificContact;
}

#pragma mark 获取通讯录内容
- (NSMutableDictionary *)getPersonInfo {
    
    self.dataArray = [NSMutableArray arrayWithCapacity:0];
    self.dataArrayDic = [NSMutableArray arrayWithCapacity:0];
    
    if (@available(iOS 9.0, *)) {
        CNContactStore *store = [[CNContactStore alloc] init];
        //检索的数据
        CNContactFetchRequest *fetch = [[CNContactFetchRequest alloc] initWithKeysToFetch:@[CNContactFamilyNameKey,CNContactGivenNameKey,CNContactPhoneNumbersKey]];
        //检索条件，检索所有名字中有zhang的联系人
        // NSPredicate *predicate = [CNContact predicateForContactsMatchingName:@"zhang"];
        //提取数据
        // NSArray*contacts = [store unifiedContactsMatchingPredicate:nil keysToFetch:@[CNContactGivenNameKey] error:nil];
        
        [store enumerateContactsWithFetchRequest:fetch error:nil usingBlock:^(CNContact * _Nonnull contact, BOOL * _Nonnull stop) {
            //需要注意搜索条件里面需要带3个key才可以,读取电话号码时候用以下方法
            //[[[contact.phoneNumbers firstObject] value] stringValue]
            //NSLog(@"%@~%@~%@",contact.familyName,contact.givenName,[[[contact.phoneNumbers firstObject] value] stringValue]);
            NSString *first = contact.givenName;
            if (first == nil) {
                first = @"";
            }
            NSString *last = contact.familyName;
            if (last == nil) {
                last = @"";
            }
            //组装数据
            for (CNLabeledValue *label in contact.phoneNumbers) {
                NSString *phoneLabel = [[label value] stringValue];
                if (phoneLabel.length > 1 && phoneLabel.length < 50) {
                    NSDictionary *dic = @{
                                          @"first":first,
                                          @"last":last,
                                          @"telphone":phoneLabel
                                          };
                    if (![first isEqualToString:@""] || ![last isEqualToString:@""]) {
                        [self.dataArrayDic addObject:dic];
                    }
                }
            }
        }];
        //排序
        //建立一个字典，字典保存key是A-Z  值是数组
        NSMutableDictionary *index = [NSMutableDictionary dictionaryWithCapacity:0];
        
        for (NSDictionary*dic in self.dataArrayDic) {
            
            NSString* str = [dic objectForKey:@"first"];
            //获得中文拼音首字母，如果是英文或数字则#
            if ([str isEqualToString:@""]) {
                str = [dic objectForKey:@"last"];
            }
            NSString *strFirLetter = [NSString stringWithFormat:@"%c",pinyinFirstLetter([str characterAtIndex:0])];
            
            if ([strFirLetter isEqualToString:@"#"]) {
                //转换为小写
                strFirLetter = [self upperStr:[str substringToIndex:1]];
            }
            if ([[index allKeys] containsObject:strFirLetter]) {
                //判断index字典中，是否有这个key如果有，取出值进行追加操作
                [[index objectForKey:strFirLetter] addObject:dic];
            } else {
                NSMutableArray *tempArray = [NSMutableArray arrayWithCapacity:0];
                [tempArray addObject:dic];
                [index setObject:tempArray forKey:strFirLetter];
            }
        }
        [self.dataArray addObjectsFromArray:[index allKeys]];
        
        return index;
        
    } else {
        //取得本地通信录名柄
        ABAddressBookRef addressBook;
        
        if ([[UIDevice currentDevice].systemVersion floatValue] >= 6.0) {
            addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
            ABAuthorizationStatus authorizationStatus = ABAddressBookGetAuthorizationStatus();
            if (authorizationStatus == kABAuthorizationStatusNotDetermined) {
                //等待同意后向下执行
                dispatch_semaphore_t sema = dispatch_semaphore_create(0);
                ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
                    dispatch_semaphore_signal(sema);
                });
                dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
                dispatch_release(sema);
            } else if (authorizationStatus == kABAuthorizationStatusDenied ||
                       authorizationStatus == kABAuthorizationStatusRestricted) {
                return nil;
            }
        } else {
            addressBook = ABAddressBookCreate();
        }
        
        //取得本地所有联系人记录
        CFArrayRef results = ABAddressBookCopyArrayOfAllPeople(addressBook);
        if (results == nil) {
            return nil;
        }
        // NSLog(@"-----%d",(int)CFArrayGetCount(results));
        // NSLog(@"in %s %d",__func__,__LINE__);
        for (int i = 0; i < CFArrayGetCount(results); i++) {
            
            ABRecordRef person = CFArrayGetValueAtIndex(results, i);
            //读取firstname
            NSString *first = (__bridge NSString*)ABRecordCopyValue(person, kABPersonFirstNameProperty);
            if (first == nil) {
                first = @"";
            }
            
            NSString *last = (__bridge NSString *)ABRecordCopyValue(person, kABPersonLastNameProperty);
            if (last == nil) {
                last = @"";
            }
            
            ABMultiValueRef tmlphone = ABRecordCopyValue(person, kABPersonPhoneProperty);
            /**
             NSString* telphone = (NSString *)ABMultiValueCopyValueAtIndex(tmlphone, 0);
             if (telphone == nil) {
                telphone = @"";
             }
             [dicInfoLocal setObject:telphone forKey:@"telphone"];
             CFRelease(tmlphone);
             */
            NSArray *telphoneArray = (__bridge NSArray*)ABMultiValueCopyArrayOfAllValues(tmlphone);
            
            /*
             //获取的联系人单一属性:Email(s)
             
             ABMultiValueRef tmpEmails = ABRecordCopyValue(person, kABPersonEmailProperty);
             
             NSString *email = (NSString*)ABMultiValueCopyValueAtIndex(tmpEmails, 0);
             [dicInfoLocal setObject:email forKey:@"email"];
             
             CFRelease(tmpEmails);
             if (email) {
                email = @"";
             }
             [dicInfoLocal setObject:email forKey:@"email"];
             */
            //修改
            /*
             if (first&&![first isEqualToString:@""]) {
             //不全的 多信息 多信息
             [self.dataArraydic addObject:dicInfoLocal];
             } */
            
            for (NSString *telphone in telphoneArray) {
                if (telphone != nil && telphone.length > 1 && telphone.length < 50) {
                    NSDictionary *dicInfoLocal = @{
                                                   @"first":first,
                                                   @"last":last,
                                                   @"telphone":telphone
                                                   };
                    if (![first isEqualToString:@""] || ![last isEqualToString:@""]) {
                        [self.dataArrayDic addObject:dicInfoLocal];
                    }
                }
            }
            CFRelease(tmlphone);
        }
        CFRelease(results);//new
        CFRelease(addressBook);//new
        
        //排序
        //建立一个字典，字典保存key是A-Z  值是数组
        NSMutableDictionary *index = [NSMutableDictionary dictionaryWithCapacity:0];
        
        for (NSDictionary *dic in self.dataArrayDic) {
            
            NSString *str = [dic objectForKey:@"first"];
            //获得中文拼音首字母，如果是英文或数字则#
            if ([str isEqualToString:@""]) {
                str = [dic objectForKey:@"last"];
            }
            NSString *strFirLetter = [NSString stringWithFormat:@"%c",pinyinFirstLetter([str characterAtIndex:0])];
            
            if ([strFirLetter isEqualToString:@"#"]) {
                //转换为小写
                strFirLetter = [self upperStr:[str substringToIndex:1]];
            }
            if ([[index allKeys] containsObject:strFirLetter]) {
                //判断index字典中，是否有这个key如果有，取出值进行追加操作
                [[index objectForKey:strFirLetter] addObject:dic];
            } else {
                NSMutableArray *tempArray = [NSMutableArray arrayWithCapacity:0];
                [tempArray addObject:dic];
                [index setObject:tempArray forKey:strFirLetter];
            }
        }
        [self.dataArray addObjectsFromArray:[index allKeys]];
        
        return index;
    }
}

#pragma mark 字母转换大小写--6.0
- (NSString *)upperStr:(NSString *)str {
    
    //全部转换为大写
    // NSString *upperStr = [str uppercaseStringWithLocale:[NSLocale currentLocale]];
    // NSLog(@"upperStr: %@", upperStr);
    //首字母转换大写
    // NSString *capStr = [str capitalizedStringWithLocale:[NSLocale currentLocale]];
    // NSLog(@"capStr: %@", capStr);
    // 全部转换为小写
    NSString *lowerStr = [str lowercaseStringWithLocale:[NSLocale currentLocale]];
    // NSLog(@"lowerStr: %@", lowerStr);
    return lowerStr;
}

#pragma mark 排序
- (NSArray *)sortMethod
{
    return [self.dataArray sortedArrayUsingFunction:cmp context:NULL];;
}

#pragma mark 构建数组排序方法SEL
//NSInteger cmp(id, id, void *);
NSInteger cmp(NSString *a, NSString *b, void *p)
{
    if ([a compare:b] == 1) {
        return NSOrderedDescending;//(1)
    } else
        return NSOrderedAscending;//(-1)
}

#pragma mark 使用系统方式进行发送短信，但是短信内容无法规定
+ (void)sendMessage:(NSString *)phoneNum
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"sms:%@",phoneNum]]];
}

- (instancetype)initWithTarget:(id)target MessageNameArray:(NSArray *)array Message:(NSString *)str Block:(void (^)(int))a
{
    if (self = [super init]) {
        self.target = target;
        self.MessageBlock = a;
        [self showViewMessageNameArray:array Message:str];
    }
    return self;
}

- (void)showViewMessageNameArray:(NSArray *)array Message:(NSString *)str
{
    //判断当前设备是否可以发送信息
    if ([MFMessageComposeViewController canSendText]) {
        
        MFMessageComposeViewController *messageViewController = [[MFMessageComposeViewController alloc] init];
        
        //委托到本类
        messageViewController.messageComposeDelegate = self;
        
        //设置收件人, 需要一个数组, 可以群发短信
        messageViewController.recipients = array;
        
        //短信的内容
        messageViewController.body = str;
        
        //打开短信视图控制器
        [self.target presentViewController:messageViewController animated:YES completion:nil];
        
        [messageViewController release];
    }
}

#pragma mark MFMessageComposeViewController 代理方法
- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result
{
    //0取消 1是成功 2是失败
    self.MessageBlock(result);
    [controller dismissViewControllerAnimated:YES completion:nil];
}

- (instancetype)initWithTarget:(id)target PhoneView:(void (^)(BOOL, NSDictionary *))a
{
    if (self = [super init]) {
        self.target = target;
        self.PhoneBlock = a;
        ABPeoplePickerNavigationController *peoplePicker = [[ABPeoplePickerNavigationController alloc] init];
        peoplePicker.peoplePickerDelegate = self;
        [self.target presentViewController:peoplePicker animated:YES completion:nil];
        [peoplePicker release];
    }
    
    return self;
}

- (void)peoplePickerNavigationControllerDidCancel:(ABPeoplePickerNavigationController *)peoplePicker
{
    self.PhoneBlock(NO,nil);
    [peoplePicker dismissViewControllerAnimated:YES completion:nil];
}

@end
