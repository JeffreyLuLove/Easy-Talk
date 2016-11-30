//
//  EaseMobManager.m
//  Easy-Talk
//
//  Created by tarena on 16/11/29.
//  Copyright © 2016年 tarena. All rights reserved.
//

#import "EaseMobManager.h"

static EaseMobManager *_manager;

@implementation EaseMobManager

- (NSMutableArray *)requests {
    if (! _requests) {
        _requests = [NSMutableArray array];
    }
    return _requests;
}

+ (EaseMobManager *)sharedManager {
    @synchronized(self) {
        if (!_manager) {
            _manager = [[EaseMobManager alloc]init];
            [[EaseMob sharedInstance].chatManager addDelegate:_manager delegateQueue:nil];
        }
    }
    return _manager;
}

- (void)didReceiveBuddyRequest:(NSString *)username message:(NSString *)message {
    message = message ? message : @""; //如果有message内容就给内容；如果是nil，就给个空字符串。但是无论如何不能给nil
    [self.requests addObject:@[username, message]];
    //开启通知，通知界面刷新
    [[NSNotificationCenter defaultCenter] postNotificationName:@"FriendStatusChangeNotification" object:nil];
}

- (void)didAcceptedByBuddy:(NSString *)username {
    [SVProgressHUD showInfoWithStatus:[NSString stringWithFormat:@"%@已经接受好友请求,你们已经是好友了!", username]];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"FriendStatusChangeNotification" object:nil];
}

- (void)didRejectedByBuddy:(NSString *)username {
       [SVProgressHUD showInfoWithStatus:[NSString stringWithFormat:@"%@拒绝了您的好友请求!", username]];
}

- (void)didLoginWithInfo:(NSDictionary *)loginInfo error:(EMError *)error {
    [self.requests removeAllObjects];
    NSLog(@"登录成功");
    [[NSNotificationCenter defaultCenter] postNotificationName:@"FriendStatusChangeNotification" object:nil];
    
}

// 自动登录
- (void)didAutoLoginWithInfo:(NSDictionary *)loginInfo error:(EMError *)error {
    NSLog(@"自动登录成功");
    [self.requests removeAllObjects];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"FriendStatusChangeNotification" object:nil];
    
}

// 接收到消息时响应
- (void)didReceiveMessage:(EMMessage *)message {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ReceiveMessageNotification" object:message];
}

// 接收到离线消息时响应
-(void)didReceiveOfflineMessages:(NSArray *)offlineMessages {
    for (EMMessage *message in offlineMessages) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ReceiveMessageNotification" object:message];
    }
}

@end
