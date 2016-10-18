//
//  SRPlayer.h
//
//


#import "SRPlayerView.h"
#import "SRPlayerControlView.h"
#import "SRPlayerItem.h"
#import "UITabBarController+SR_rotation.h"
#import "UINavigationController+SR_rotation.h"
#import "UIViewController+SR_ratation.h"

// 设置返回按钮图片对应的key
#define SRPlayerBackBtnKey   @"SRPlayerControlBackBtnKey"
// 设置大播放按钮图片对应的key
#define SRPlayerStartPlayKey   @"SRPlayerStartPlayKey"
// 设置重播按钮图片对应的key
#define SRPlayerRepeatPlayKey   @"SRPlayerRepeatPlayKey"
// 设置底部栏中播放按钮图片对应的key
#define SRPlayerplayKey   @"SRPlayerplayKey"
// 设置底部栏中暂停按钮图片对应的key
#define SRPlayerPauseKey   @"SRPlayerPauseKey"
// 设置全屏按钮图片对应的key
#define SRPlayerFullScreenKey   @"SRPlayerFullScreenKey"
// 设置小屏按钮图片对应的key
#define SRPlayerSmallScreenKey   @"SRPlayerSmallScreenKey"
// 设置滑杆图片对应的key
#define SRPlayerSliderKey   @"SRPlayerSliderKey"


// bundle中图片路径
#define SRPlayerImagePath(imageName)   [@"SRPlayer.bundle" stringByAppendingPathComponent:imageName]

// image
#define SRPlayerImage(imageName)   [UIImage imageNamed:SRPlayerImagePath(imageName)]
