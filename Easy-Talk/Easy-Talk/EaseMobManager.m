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

-(NSMutableArray *)requests {
    if (! _requests) {
        _requests = [NSMutableArray array];
    }
    return _requests;
}

+(EaseMobManager *)sharedManager {
    @synchronized(self) {
        if (!_manager) {
            _manager = [[EaseMobManager alloc]init];
            [[EaseMob sharedInstance].chatManager addDelegate:_manager delegateQueue:nil];
        }
    }
    return _manager;
}

- (void)didReceiveBuddyRequest:(NSString *)username message:(NSString *)message {
    [self.requests addObject:@[username, message]];
    //开启通知，通知界面刷新
    [[NSNotificationCenter defaultCenter] postNotificationName:@"FriendStatusChangeNotification" object:nil];
}

/*!
 @method
 @brief 好友请求被接受时的回调
 @discussion
 @param username 之前发出的好友请求被用户username接受了
 */
- (void)didAcceptedByBuddy:(NSString *)username {
    [SVProgressHUD showInfoWithStatus:[NSString stringWithFormat:@"%@已经接受好友请求,你们已经是好友了!", username]];
    //通知界面刷新
    [[NSNotificationCenter defaultCenter] postNotificationName:@"FriendStatusChangeNotification" object:nil];
}

/*!
 @method
 @brief 好友请求被拒绝时的回调
 @discussion
 @param username 之前发出的好友请求被用户username拒绝了
 */
- (void)didRejectedByBuddy:(NSString *)username {
       [SVProgressHUD showInfoWithStatus:[NSString stringWithFormat:@"%@拒绝了您的好友请求!", username]];
}

@end
