//
//  SRPlayerView.h
//  XLVideoPlayerTest
//
//  Created by xl on 16/10/11.
//  Copyright © 2016年 xl. All rights reserved.
//

#import <UIKit/UIKit.h>
@class SRPlayerView,SRPlayerItem;

@protocol SRPlayerViewDelegate <NSObject>

/** 播放器方向发生改变 回调*/
- (void)playerView:(SRPlayerView *)player OrientationChange:(BOOL)isFullScreen;
/** 返回 回调*/
- (void)playerViewBackVC:(SRPlayerView *)player;
@end

@interface SRPlayerView : UIView


@property (nonatomic,weak) id<SRPlayerViewDelegate> delegate;

/** 视频相关对象*/  // 播放单个视频
@property (nonatomic,strong) SRPlayerItem *SR_playerItem;
/** 视频相关对象数组*/   // 播放多个视频
@property (nonatomic,strong) NSArray <SRPlayerItem *>*playerItems;

/** 自定义图片映射*/
@property (nonatomic,strong) NSDictionary *imageMapping;
/**
 *  取消延时方法，释放内存
 */
- (void)cancelAutoDelayHiddenControlView;
/** 播放*/
- (void)play;
/** 暂停*/
- (void)pause;

@end
