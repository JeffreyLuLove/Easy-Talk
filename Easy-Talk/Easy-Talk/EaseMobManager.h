//
//  EaseMobManager.h
//  Easy-Talk
//
//  Created by tarena on 16/11/29.
//  Copyright © 2016年 tarena. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EaseMobManager : NSObject <EMChatManagerDelegate>

@property (nonatomic, strong) NSMutableArray *requests;

+ (EaseMobManager *) sharedManager;

@end
