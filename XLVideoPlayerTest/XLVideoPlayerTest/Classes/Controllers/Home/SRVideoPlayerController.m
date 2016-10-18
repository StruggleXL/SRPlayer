//
//  SRVideoPlayerController.m
//  XLVideoPlayerTest
//
//  Created by xl on 16/10/8.
//  Copyright © 2016年 xl. All rights reserved.
//

#import "SRVideoPlayerController.h"
#import "SRPlayer.h"

#define viewwidth self.view.frame.size.width
#define viewheight self.view.frame.size.height
@interface SRVideoPlayerController ()<SRPlayerViewDelegate>


@property (nonatomic, weak) IBOutlet SRPlayerView *srp;
@end

@implementation SRVideoPlayerController
//- (UIStatusBarStyle)preferredStatusBarStyle
//{
//    return UIStatusBarStyleLightContent;
//}
- (void)dealloc {
    NSLog(@"vc释放");
    // 在页面释放的时候取消延迟加载方法，以便及时释放SRPlayerView；若不掉用此方法，对内存释放不会有影响，系统会在延迟方法（视频会播放0～SRPlayerControlViewShowTimeInterval秒）执行结束后自动释放内存
    [self.srp cancelAutoDelayHiddenControlView];
}
- (void)viewDidLoad {
    
    [super viewDidLoad];
    [[UIApplication sharedApplication]setStatusBarStyle:UIStatusBarStyleLightContent];
    
    self.srp.delegate = self;
    
    // 设置自定义图片，key可在SRPlayer.h中查看 ，若不设置，会使用默认图片
//    self.srp.imageMapping = @{SRPlayerBackBtnKey:[UIImage imageNamed:@"Player_back_full"],SRPlayerFullScreenKey:[UIImage imageNamed:@"Player_fullscreen"],SRPlayerSmallScreenKey:[UIImage imageNamed:@"Player_shrinkscreen"]};
    // 设置单个视频
    SRPlayerItem *item = [SRPlayerItem SR_playerItemWithVideoURL:self.videoURL videoTitle:@"测试标题"];
    item.isAutoPlay = NO;
    self.srp.SR_playerItem = item;
    
    
//    // 设置多个视频
//    NSMutableArray *items = [NSMutableArray array];
//    
//    NSURL *LocalUrl= [[NSBundle mainBundle]URLForResource:@"SampleVideo_640x360_1mb" withExtension:@"mp4"];
//    SRPlayerItem *item1 = [SRPlayerItem SR_playerItemWithVideoURL:LocalUrl videoTitle:@"测试标题1"];
//    item1.isAutoPlay = NO;
//    [items addObject:item1];
//    
//    SRPlayerItem *item2 = [SRPlayerItem SR_playerItemWithVideoURL:self.videoURL videoTitle:@"测试标题2"];
//    item2.isAutoPlay = YES;
//    [items addObject:item2];
//    self.srp.playerItems = items;


    
}



#pragma mark -SRPlayerViewDelegate 
/** 播放器方向发生改变 回调*/
- (void)playerView:(SRPlayerView *)player OrientationChange:(BOOL)isFullScreen {
    // 全屏，隐藏导航栏  // 小屏，显示导航栏
    [self.navigationController setNavigationBarHidden:isFullScreen animated:NO];
}
/** 返回 回调*/
- (void)playerViewBackVC:(SRPlayerView *)player{
    [self.navigationController popViewControllerAnimated:YES];
}
@end
