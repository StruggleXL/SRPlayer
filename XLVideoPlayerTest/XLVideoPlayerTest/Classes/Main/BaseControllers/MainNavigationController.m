//
//  MainNavigationController.m
//  XLVideoPlayerTest
//
//  Created by xl on 16/10/8.
//  Copyright © 2016年 xl. All rights reserved.
//

#import "MainNavigationController.h"

@interface MainNavigationController ()

@end

@implementation MainNavigationController

+ (void)initialize {
    UINavigationBar *navBar=[UINavigationBar appearance];
    
    //导航栏背景颜色
    [navBar setBarTintColor:[UIColor grayColor]];
    //设置返回按钮颜色
    [navBar setTintColor:[UIColor whiteColor]];
}
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}


- (UIViewController *)childViewControllerForStatusBarStyle
{
    return self.topViewController;
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
