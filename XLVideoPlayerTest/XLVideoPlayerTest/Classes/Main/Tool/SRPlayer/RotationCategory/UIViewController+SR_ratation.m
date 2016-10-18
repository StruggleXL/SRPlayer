//
//  UIViewController+SR_ratation.m
//  XLVideoPlayerTest
//
//  Created by xl on 16/10/12.
//  Copyright © 2016年 xl. All rights reserved.
//

#import "UIViewController+SR_ratation.h"

@implementation UIViewController (SR_ratation)

- (BOOL)shouldAutorotate
{
    if (!self.navigationController) return NO;
    
    for (UIView *view in self.navigationController.navigationBar.subviews) {
        
        if ([view isKindOfClass:NSClassFromString(@"_UINavigationBarBackground")]) {
            CGRect frame = view.frame;
            
            frame.origin.y = -20;
            
            frame.size.height = 64;
            view.frame = frame;
        }
    }
    
    CGRect frame = self.navigationController.navigationBar.frame;
    
    frame.origin.y = 20;
    
    frame.size.height = 44;
    
    self.navigationController.navigationBar.frame = frame;
    
    return NO;

}
@end
