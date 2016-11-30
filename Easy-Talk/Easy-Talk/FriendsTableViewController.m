//
//  FriendsTableViewController.m
//  Easy-Talk
//
//  Created by tarena on 16/11/29.
//  Copyright © 2016年 tarena. All rights reserved.
//

#import "FriendsTableViewController.h"
#import "EaseMobManager.h"

@interface FriendsTableViewController () <EMChatManagerDelegate>

@property (nonatomic, strong)NSMutableArray *friends;

@end

@implementation FriendsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"好友列表";
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"登出" style:UIBarButtonItemStyleDone target:self action:@selector(logOut)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addAction)];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(updateFriendsAndRequestsAction) name:@"FriendStatusChangeNotification" object:nil];
}

- (void)logOut {
    //退出登录
    [[EaseMob sharedInstance].chatManager asyncLogoffWithUnbindDeviceToken:YES completion:^(NSDictionary *info, EMError *error) {
        if (! error) {
            NSLog(@"退出成功");
            [self dismissViewControllerAnimated:YES completion:nil];
        }
    } onQueue:nil];
}

- (void)addAction {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示" message:@"请输入好友用户名" preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"好友账号";
    }];
    
    UIAlertAction *action1 = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    UIAlertAction *action2 = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        EMError *error = nil;
        BOOL isSuccess = [[EaseMob sharedInstance].chatManager addBuddy:alert.textFields[0].text message:@"我想加您为好友" error:&error];
        if (isSuccess && !error) {
            [SVProgressHUD showInfoWithStatus:@"已发出好友请求等待对方确认"];
        }
    }];
    [alert addAction:action1];
    [alert addAction:action2];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)updateFriendsAndRequestsAction {
    //获取好友列表
    [[EaseMob sharedInstance].chatManager asyncFetchBuddyListWithCompletion:^(NSArray *buddyList, EMError *error) {
        if (! error) {
            self.friends = [NSMutableArray array];
            for (EMBuddy *buddy in buddyList) {
                [self.friends addObject:buddy.username];
            }
            [self.tableView reloadData];
        }
    } onQueue:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self updateFriendsAndRequestsAction];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section==0) {//好友请求
        return [EaseMobManager sharedManager].requests.count;
    }
    return self.friends.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (! cell) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"cell"];
    }
    if (indexPath.section==0) {
        NSArray *infoArr = [EaseMobManager sharedManager].requests[indexPath.row];
        cell.textLabel.text = infoArr[0];
        cell.detailTextLabel.text = infoArr[1];
    }else {
        cell.textLabel.text = self.friends[indexPath.row];
        cell.detailTextLabel.text = @"";
    }
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        NSArray *infoArr = [EaseMobManager sharedManager].requests[indexPath.row];
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示" message:[NSString stringWithFormat:@"您确认添加%@为好友吗?",infoArr[0]] preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *action1 = [UIAlertAction actionWithTitle:@"同意" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            EMError *error = nil;
            BOOL isSuccess = [[EaseMob sharedInstance].chatManager acceptBuddyRequest:infoArr[0] error:&error];
            if (isSuccess && ! error) {
                [SVProgressHUD showInfoWithStatus:@"已经同意加对方为好友!"];
                [[EaseMobManager sharedManager].requests removeObject:infoArr];
                //更新本地好友
                [self updateFriendsAndRequestsAction];
            }
        }];
        UIAlertAction *action2 = [UIAlertAction actionWithTitle:@"拒绝" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            EMError *error = nil;
            BOOL isSuccess = [[EaseMob sharedInstance].chatManager rejectBuddyRequest:infoArr[0] reason:nil error:&error];
            if (isSuccess && !error) {
                [SVProgressHUD showInfoWithStatus:@"已经拒绝对方!"];
                [[EaseMobManager sharedManager].requests removeObject:infoArr];
                [self.tableView reloadData];
            }
        }];
        
        [alert addAction:action1];
        [alert addAction:action2];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        return NO;
    }
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        EMError *error = nil;
        // 从环信删除好友
        BOOL isSuccess = [[EaseMob sharedInstance].chatManager removeBuddy:self.friends[indexPath.row] removeFromRemote:YES error:&error];
        if (isSuccess && !error) {
            [SVProgressHUD showInfoWithStatus:@"删除成功"];
        }
        // 从本地tableView删除好友
        [self.friends removeObjectAtIndex:indexPath.row];
        
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}


/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
