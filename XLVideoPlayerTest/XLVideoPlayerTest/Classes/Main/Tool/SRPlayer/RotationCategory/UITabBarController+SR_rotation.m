//
//  UITabBarController+SR_rotation.m
//  XLVideoPlayerTest
//
//  Created by xl on 16/10/12.
//  Copyright © 2016年 xl. All rights reserved.
//

#import "UITabBarController+SR_rotation.h"

@implementation UITabBarController (SR_rotation)

- (BOOL)shouldAutorotate
{
    return [self.selectedViewController shouldAutorotate];
}
@end
