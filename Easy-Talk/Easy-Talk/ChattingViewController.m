//
//  ChattingViewController.m
//  Easy-Talk
//
//  Created by tarena on 16/11/30.
//  Copyright © 2016年 tarena. All rights reserved.
//

#import "ChattingViewController.h"
#import "amrFileCodec.h"
#import <AVFoundation/AVFoundation.h>

@interface ChattingViewController () <UITableViewDataSource, UITableViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (nonatomic, strong) NSMutableArray *messages;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIView *bottomPad;
@property (nonatomic, strong) UITextField *messageTF;
@property (nonatomic, strong) NSLayoutConstraint *viewBottomCostraint;
@property (nonatomic, strong) AVAudioPlayer *player;

@end

@implementation ChattingViewController

- (NSMutableArray *)messages {
    if (_messages == nil) {
        _messages = [NSMutableArray array];
    }
    return _messages;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = self.toUsername;
    
    // 设置底部面板（与上面的tableView同一级别，方便弹出收回键盘用）
    self.bottomPad = [[UIView alloc] init];
    self.bottomPad.backgroundColor = kBottomPadColor;
    [self.view addSubview:self.bottomPad];
    [self.bottomPad mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(0);
        make.bottom.equalTo(0);
        make.width.equalTo(self.view.frame.size.width);
        make.height.equalTo(40);
    }];
    
    // 设置录音按钮
    UIButton *recordBtn = [[UIButton alloc] init];
    [recordBtn setBackgroundColor:kLoginButtonColor];
    [recordBtn setTitle:@"录音" forState:UIControlStateNormal];
    recordBtn.titleLabel.font = [UIFont systemFontOfSize:14];
    [recordBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [recordBtn setTitleColor:[UIColor lightTextColor] forState:UIControlStateHighlighted];
    recordBtn.layer.cornerRadius = 5;
    recordBtn.layer.masksToBounds = YES;
    [self.bottomPad addSubview:recordBtn];
    [recordBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(8);
        make.bottom.equalTo(-8);
        make.size.equalTo(CGSizeMake(35, 24));
    }];
    [recordBtn addTarget:self action:@selector(recordBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    
    // 设置文本发送按钮
    UIButton *sendBtn = [[UIButton alloc] init];
    [sendBtn setBackgroundColor:kLoginButtonColor];
    [sendBtn setTitle:@"发送" forState:UIControlStateNormal];
    sendBtn.titleLabel.font = [UIFont systemFontOfSize:14];
    [sendBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [sendBtn setTitleColor:[UIColor lightTextColor] forState:UIControlStateHighlighted];
    sendBtn.layer.cornerRadius = 5;
    sendBtn.layer.masksToBounds = YES;
    [self.bottomPad addSubview:sendBtn];
    [sendBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.bottom.equalTo(-8);
        make.size.equalTo(CGSizeMake(35, 24));
    }];
    [sendBtn addTarget:self action:@selector(sendBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    
    // 设置图片发送按钮
    UIButton *picBtn = [[UIButton alloc] init];
    [picBtn setBackgroundColor:kLoginButtonColor];
    [picBtn setTitle:@"图片" forState:UIControlStateNormal];
    picBtn.titleLabel.font = [UIFont systemFontOfSize:14];
    [picBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [picBtn setTitleColor:[UIColor lightTextColor] forState:UIControlStateHighlighted];
    picBtn.layer.cornerRadius = 5;
    picBtn.layer.masksToBounds = YES;
    [self.bottomPad addSubview:picBtn];
    [picBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(sendBtn.mas_left).equalTo(-8);
        make.bottom.equalTo(-8);
        make.size.equalTo(CGSizeMake(35, 24));
    }];
    [picBtn addTarget:self action:@selector(picBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    
    // 设置文本输入框
    self.messageTF = [[UITextField alloc] init];
    self.messageTF.backgroundColor = [UIColor whiteColor];
    self.messageTF.placeholder = @"输入正文";
    [self.bottomPad addSubview:self.messageTF];
    [self.messageTF mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(recordBtn.mas_right).offset(8);
        make.right.equalTo(picBtn.mas_left).offset(-8);
        make.top.equalTo(recordBtn.mas_top);
        make.bottom.equalTo(recordBtn.mas_bottom);
    }];
    
    // 设置tableView
    self.tableView = [[UITableView alloc] init];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.view addSubview:self.tableView];
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(64);
        make.left.equalTo(0);
        make.bottom.equalTo(self.bottomPad.mas_top);
        make.width.equalTo(self.view.frame.size.width);
  //      make.height.equalTo(self.view.frame.size.height - self.bottomPad.frame.size.height);
    }];
    //行高为自适应 一定要先设置 一个行高的预估值，后面才可以自适应
    self.tableView.estimatedRowHeight = 60;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    
    //创建或获取会话对象
    EMConversation *conversation = [[EaseMob sharedInstance].chatManager conversationForChatter:self.toUsername conversationType:eConversationTypeChat];
    NSArray *oldMessages = conversation.loadAllMessages;
    self.messages = [NSMutableArray arrayWithArray:oldMessages];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveMessageAction:) name:@"ReceiveMessageNotification" object:nil];
    
    //添加手势,用来收回键盘
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapGesture:)];
    tap.numberOfTapsRequired = 1; //点几次
    tap.numberOfTouchesRequired = 1; //几个触摸点
    [self.tableView addGestureRecognizer:tap];
    
    //让tableView 滚动到最后一样
    [self scrollToTableViewLastRow];
}

- (void)sendBtnAction:(id)sender {
    EMChatText *txtChat = [[EMChatText alloc] initWithText:self.messageTF.text];
    EMTextMessageBody *body = [[EMTextMessageBody alloc] initWithChatObject:txtChat];
    // 生成message
    EMMessage *message = [[EMMessage alloc] initWithReceiver:self.toUsername bodies:@[body]];
    // 设置为单聊消息
    message.messageType = eMessageTypeChat;
    [[EaseMob sharedInstance].chatManager asyncSendMessage:message progress:nil];
    [self.messages addObject:message];
    [self.tableView reloadData];
}

- (void)picBtnAction:(id)sender {
    UIImagePickerController *ipc = [[UIImagePickerController alloc] init];
    ipc.delegate = self;
    [self presentViewController:ipc animated:YES completion:nil];
}

- (void)recordBtnAction:(id)sender {
    
}

- (void)didReceiveMessageAction:(NSNotification *)notification {
    EMMessage *message = notification.object;
    if ([message.from isEqualToString:self.toUsername]) {
        [self.messages addObject:message];
        [self.tableView reloadData];
    }
}

- (void)tapGesture:(id)sender {
    [self.view endEditing:YES];
}


#pragma mark - KeyBoard Control

-(void)viewWillAppear:(BOOL)animated {
    //注册接收键盘弹起的通知
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(openKeyBoard:) name:UIKeyboardWillShowNotification object:nil];
    //注册接收键盘收起的通知
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(closeKeyBoard:) name:UIKeyboardWillHideNotification object:nil];
}

//键盘将要弹起
-(void)openKeyBoard:(NSNotification*)notification {
    //获取键盘高度
    CGFloat keyBoardHeight = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue].size.height;
    //动画持续时间
    NSTimeInterval duration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    //动画选项
    NSInteger option = [notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue];
    
    [self.bottomPad mas_updateConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(-keyBoardHeight);
    }];
    [UIView animateWithDuration:duration delay:0 options:option animations:^{
        //不断更新约束
        [self.view layoutIfNeeded];
    } completion:nil];
    //让tableView 滚动到最后一样
    [self scrollToTableViewLastRow];
}

-(void)scrollToTableViewLastRow {
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.messages.count-1 inSection:0];
//    [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:NO];
}

//键盘将要收回
-(void)closeKeyBoard:(NSNotification*)notification {
    //动画持续时间
    NSTimeInterval duration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    //动画选项
    NSInteger option = [notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue];
    [self.bottomPad mas_updateConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(0);
    }];
    [UIView animateWithDuration:duration delay:0 options:option animations:^{
        //不断更新约束
        [self.view layoutIfNeeded];
    } completion:nil];
}

-(void)viewDidDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - UIImagePickerController delegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    UIImage *image = info[UIImagePickerControllerOriginalImage];
    [self dismissViewControllerAnimated:YES completion:^{
        EMChatImage *imgChat = [[EMChatImage alloc] initWithUIImage:image displayName:@"a.jpg"];
        EMImageMessageBody *imageBody = [[EMImageMessageBody alloc] initWithChatObject:imgChat];
        // 生成message
        EMMessage *message = [[EMMessage alloc] initWithReceiver:self.toUsername bodies:@[imageBody]];
        message.messageType = eMessageTypeChat;
        [[EaseMob sharedInstance].chatManager asyncSendMessage:message progress:nil];
        [self.messages addObject:message];
        [self.tableView reloadData];
    }];
}


#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.messages.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (! cell) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
    }
    EMMessage *message = self.messages[indexPath.row];
    //得到消息里面的内容展示
    id<IEMMessageBody> msgBody = message.messageBodies.firstObject;
    
    switch ((int)msgBody.messageBodyType) {
            
        case eMessageBodyType_Text: {
            // 收到文字消息
            EMTextMessageBody *textBody = ((EMTextMessageBody *)msgBody);
            
            cell.textLabel.text = [NSString stringWithFormat:@"%@说:%@", message.from, textBody.text];
        }break;
    
        case eMessageBodyType_Image: {
            // 收到图片消息
            EMImageMessageBody *imageBody = ((EMImageMessageBody *)msgBody);
            
            if ([message.from isEqualToString:self.toUsername]) {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:imageBody.remotePath]];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        cell.imageView.image = [UIImage imageWithData:data];
                        [cell setNeedsLayout];
                    });
                });
                cell.textLabel.text = [NSString stringWithFormat:@"来自%@的图片",message.from];
            }else {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    NSData *data = [NSData dataWithContentsOfURL:[NSURL fileURLWithPath:imageBody.localPath]];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        cell.imageView.image = [UIImage imageWithData:data];
                        [cell setNeedsLayout];
                    });
                });
                cell.textLabel.text = @"我发送了一张图片";
            }
        }break;
            
        case eMessageBodyType_Voice: {
            // 如果是语音消息，先发个文本通知用户，当用户点击该行时跳转到语音播放
            if ([message.from isEqualToString:self.toUsername]) {
                cell.textLabel.text = [NSString stringWithFormat:@"来自%@的语音消息",message.from];
                
            }else {
                cell.textLabel.text = @"我发送了一条语音消息";
            }
        }break;
    }
    cell.textLabel.textAlignment = [message.from isEqualToString:self.toUsername] ? NSTextAlignmentLeft : NSTextAlignmentRight;
    return cell;
}


#pragma mark - Table view delegate

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    EMMessage *message = self.messages[indexPath.row];
    //得到消息里面的内容展示
    id<IEMMessageBody> msgBody = message.messageBodies.firstObject;
    
    switch ((int)msgBody.messageBodyType) {
        case eMessageBodyType_Voice: {
            EMVoiceMessageBody *voiceBody = (EMVoiceMessageBody *)msgBody;
            NSData *data = nil;
            if ([message.from isEqualToString:self.toUsername]) {
                data = [NSData dataWithContentsOfURL:[NSURL URLWithString:voiceBody.remotePath]];
            }else {
                data = [NSData dataWithContentsOfFile:voiceBody.localPath];
            }
            data = DecodeAMRToWAVE(data);
            self.player = [[AVAudioPlayer alloc]initWithData:data error:nil];
            [self.player play];
        }
    }
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
