//
//  UINavigationController+SR_rotation.m
//  XLVideoPlayerTest
//
//  Created by xl on 16/10/12.
//  Copyright © 2016年 xl. All rights reserved.
//

#import "UINavigationController+SR_rotation.h"

@implementation UINavigationController (SR_rotation)

- (BOOL)shouldAutorotate
{
    return [[self.viewControllers lastObject] shouldAutorotate];
}
@end
