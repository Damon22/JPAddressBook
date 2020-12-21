//
//  JPAddressBookController.m
//  JuziSDKDemo
//
//  Created by Damon Gao on 2018/6/6.
//  Copyright © 2018年 Damon. All rights reserved.
//

#import "JPAddressBookController.h"
//iOS9UI的库
#import <ContactsUI/ContactsUI.h>
#import "ChineseString.h"
#import "UIColor+JPAdd.h"
#import "JPConfigHeader.h"
#import "JPBasicUtil.h"

#pragma mark JPAddressBookHeader
/** 通讯录sectionHeader */
@interface JPAddressBookHeader : UIView

/** 标题 */
@property (nonatomic, strong) UILabel *headerTitleLabel;

@end

@implementation JPAddressBookHeader

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setupUI];
    }
    return self;
}

#pragma mark UI
- (void)setupUI {
    self.backgroundColor = JP_COLOR_Gray_BG;
    [self addSubview:self.headerTitleLabel];
    
    NSLayoutConstraint *headL = [NSLayoutConstraint constraintWithItem:self.headerTitleLabel attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeft multiplier:1.0 constant:15];
    NSLayoutConstraint *headR = [NSLayoutConstraint constraintWithItem:self.headerTitleLabel attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeRight multiplier:1.0 constant:-15];
    NSLayoutConstraint *headH = [NSLayoutConstraint constraintWithItem:self.headerTitleLabel attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:30];
    NSLayoutConstraint *headY = [NSLayoutConstraint constraintWithItem:self.headerTitleLabel attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0];
    headL.active = YES;
    headR.active = YES;
    headH.active = YES;
    headY.active = YES;
    [self addConstraints:@[headL,headR,headH,headY]];
}

#pragma mark Lazy
- (UILabel *)headerTitleLabel {
    if (!_headerTitleLabel) {
        _headerTitleLabel = [[UILabel alloc] init];
        _headerTitleLabel.font = [UIFont systemFontOfSize:16];
        _headerTitleLabel.textColor = JP_COLOR_Gray_Title;
        _headerTitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _headerTitleLabel.text = @"";
    }
    return _headerTitleLabel;
}

@end




















#pragma mark - JPAddressBookController

@interface JPAddressBookController () <UITableViewDelegate, UITableViewDataSource>

/** 展示列表 */
@property (nonatomic, strong) UITableView *tableView;
/** 索引数组 */
@property (nonatomic, strong) NSMutableArray *indexArray;
/** 索引字母数组 */
@property (nonatomic, strong) NSMutableArray *letterArray;
/** 个人信息字典 */
@property (nonatomic, strong) NSDictionary *personDic;

@end

@implementation JPAddressBookController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    // 自定义通讯录
    self.navigationItem.title = @"通讯录";
    [self.view addSubview:self.tableView];
    UIBarButtonItem *rightBarItem = [[UIBarButtonItem alloc] initWithTitle:@"取消" style:UIBarButtonItemStyleDone target:self action:@selector(rightAction)];
    self.navigationItem.rightBarButtonItem = rightBarItem;
    [self loadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark Private
// 加载数据
- (void)loadData {
    self.indexArray = [ChineseString IndexArray:self.addressArr];
    self.letterArray = [ChineseString LetterSortArray:self.addressArr];
    self.personDic = [ChineseString LetterSortWithArray:self.addressArr];
    [self.tableView reloadData];
}

#pragma mark Func
// 返回
- (void)rightAction {
    [self.navigationController dismissViewControllerAnimated:YES completion:^{
        if (self.completion) {
            self.completion();
        }
    }];
}

#pragma mark Delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *phone = self.personDic[@"phone"][indexPath.section][indexPath.row];
    NSString *name = self.personDic[@"Name"][indexPath.section][indexPath.row];
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
    [self rightAction];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"JPAddressBookController"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"JPAddressBookController"];
    }
    cell.textLabel.text = self.letterArray[indexPath.section][indexPath.row];
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.letterArray[section] count];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [self.indexArray count];
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
    return index;
}

- (NSArray<NSString *> *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    return self.indexArray;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    JPAddressBookHeader *header = [[JPAddressBookHeader alloc] init];
    header.headerTitleLabel.text = self.indexArray[section];
    return header;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    return [UIView new];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 30;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 0.0001f;
}

#pragma mark Lazy
- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, JP_UISCREENWIDTH, JP_UISCREENHEIGHT) style:UITableViewStylePlain];
        _tableView.showsVerticalScrollIndicator = NO;
        _tableView.showsHorizontalScrollIndicator = NO;
        _tableView.delegate = self;
        _tableView.dataSource = self;
    }
    return _tableView;
}

- (NSMutableArray *)indexArray {
    if (!_indexArray) {
        _indexArray = [NSMutableArray arrayWithCapacity:26];
    }
    return _indexArray;
}

- (NSMutableArray *)letterArray {
    if (!_letterArray) {
        _letterArray = [NSMutableArray arrayWithCapacity:26];
    }
    return _letterArray;
}

@end
