//
//  LoadingViewController.m
//  Easy-Talk
//
//  Created by tarena on 16/11/29.
//  Copyright © 2016年 tarena. All rights reserved.
//

#import "LoadingViewController.h"
#import "FriendsTableViewController.h"

@interface LoadingViewController ()

@property (nonatomic, strong) UITextField *usernameTF;
@property (nonatomic, strong) UITextField *passwordTF;

@end

@implementation LoadingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor colorWithRed:205/255.0 green:245/255.0 blue:245/255.0 alpha:1];
    
    self.usernameTF = [[UITextField alloc] init];
    self.usernameTF.placeholder = @"请输入账号";
    self.usernameTF.layer.cornerRadius = 5;
    self.usernameTF.layer.masksToBounds = YES;
    self.usernameTF.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.usernameTF];
    [self.usernameTF mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(0);
        make.centerY.equalTo(-100);
        make.size.equalTo(CGSizeMake(200, 30));
    }];
    
    self.passwordTF = [[UITextField alloc] init];
    self.passwordTF.placeholder = @"请输入密码";
    self.passwordTF.layer.cornerRadius = 5;
    self.passwordTF.layer.masksToBounds = YES;
    self.passwordTF.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.passwordTF];
    [self.passwordTF mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(0);
        make.top.equalTo(self.usernameTF.mas_bottom).offset(20);
        make.size.equalTo(CGSizeMake(200, 30));
    }];
    
    UIButton *loadBtn = [[UIButton alloc] init];
    [loadBtn setTitle:@"登录" forState:UIControlStateNormal];
    [loadBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [loadBtn setTitleColor:[UIColor lightTextColor] forState:UIControlStateHighlighted];
    loadBtn.layer.cornerRadius = 5;
    loadBtn.layer.masksToBounds = YES;
    loadBtn.backgroundColor = kLoginButtonColor;
    [self.view addSubview:loadBtn];
    [loadBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(0);
        make.top.equalTo(self.passwordTF.mas_bottom).offset(20);
        make.size.equalTo(CGSizeMake(150, 30));
    }];
    [loadBtn addTarget:self action:@selector(loadBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *registerBtn = [[UIButton alloc] init];
    [registerBtn setTitle:@"注册" forState:UIControlStateNormal];
    registerBtn.titleLabel.font = [UIFont systemFontOfSize:14];
    [registerBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [registerBtn setTitleColor:[UIColor lightTextColor] forState:UIControlStateHighlighted];
    registerBtn.layer.cornerRadius = 5;
    registerBtn.layer.masksToBounds = YES;
    registerBtn.backgroundColor = kLoginButtonColor;
    [self.view addSubview:registerBtn];
    [registerBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(20);
        make.bottom.equalTo(-20);
        make.size.equalTo(CGSizeMake(50, 20));
    }];
    [registerBtn addTarget:self action:@selector(registerBtnAction:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)loadBtnAction:(UIButton *)sender {
    [[EaseMob sharedInstance].chatManager asyncLoginWithUsername:self.usernameTF.text password:self.passwordTF.text completion:^(NSDictionary *loginInfo, EMError *error) {
        if (! error && loginInfo) {
            [SVProgressHUD showInfoWithStatus:@"登录成功"];
            [[EaseMob sharedInstance].chatManager setIsAutoLoginEnabled:YES];
            FriendsTableViewController *tvc = [[FriendsTableViewController alloc] init];
            [self presentViewController:[[UINavigationController alloc]initWithRootViewController:tvc] animated:YES completion:nil];
        }else {
            [SVProgressHUD showInfoWithStatus:[NSString stringWithFormat:@"%@",error]];
        }
    } onQueue:nil];
}

- (void)registerBtnAction:(UIButton *)sender {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示" message:@"注册新账户" preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"创建账户";
    }];
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"创建密码";
    }];
    
    UIAlertAction *action1 = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    UIAlertAction *action2 = [UIAlertAction actionWithTitle:@"注册" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
        [[EaseMob sharedInstance].chatManager asyncRegisterNewAccount:alert.textFields[0].text password:alert.textFields[1].text withCompletion:^(NSString *username, NSString *password, EMError *error) {
            if (! error) {
                [SVProgressHUD showInfoWithStatus:@"注册成功"];
            }else {
                [SVProgressHUD showInfoWithStatus:[NSString stringWithFormat:@"%@", error]];
            }
        } onQueue:nil];
    }];
    [alert addAction:action1];
    [alert addAction:action2];

    [self presentViewController:alert animated:YES completion:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    //判断是否自动登录了，如果自动登录，就跳转到登录界面
    if ([[EaseMob sharedInstance].chatManager isAutoLoginEnabled]) {
        FriendsTableViewController *tvc = [[FriendsTableViewController alloc] init];
        [self presentViewController:[[UINavigationController alloc] initWithRootViewController:tvc] animated:YES completion:nil];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
