//
//  SRPlayerControlView.h
//  XLVideoPlayerTest
//
//  Created by xl on 16/10/11.
//  Copyright © 2016年 xl. All rights reserved.
//

#import <UIKit/UIKit.h>
@class SRPlayerControlView;

@protocol SRPlayerControlViewDelegate <NSObject>

/** 播放／暂停 按钮回调*/
- (void)playerControl:(SRPlayerControlView *)control playBtnPlayerOrPause:(BOOL)play;
/** 滑杆开始滑动 回调*/
- (void)playerControlSliderStartSlide:(SRPlayerControlView *)control;
/** 滑杆点击、滑动结束 回调*/
- (void)playerControl:(SRPlayerControlView *)control sliderTapValue:(CGFloat)tapValue;
/** 滑杆滑动中 回调*/
- (void)playerControl:(SRPlayerControlView *)control sliderValueChange:(CGFloat)changeValue;
/** 全屏按钮 回调*/
- (void)playerControl:(SRPlayerControlView *)control fullScreenBtnClick:(BOOL)fullScreen;
/** 返回按钮 回调*/
- (void)playerControlBackBtnClick:(SRPlayerControlView *)control;
@end

@interface SRPlayerControlView : UIView


/** 大播放按钮*/
@property (weak, nonatomic,readonly) UIButton *startPlay;
/** 重播按钮*/
@property (weak, nonatomic,readonly) UIButton *repeatPlayBtn;
/** 菊花*/
@property (weak, nonatomic,readonly) UIActivityIndicatorView *activity;

/** 标题*/
@property (weak, nonatomic,readonly) UILabel *videotTitle;
/** 缓冲进度条*/
@property (weak, nonatomic,readonly) UIProgressView *bufferProgress;
/** 滑杆*/
@property (weak, nonatomic,readonly) UISlider *videoSlider;
/** 当前播放时长*/
@property (weak, nonatomic,readonly) UILabel *currentTimeLabel;
/** 播放总时长*/
@property (weak, nonatomic,readonly) UILabel *totalTimeLabel;
/** 是否正在播放*/
@property (nonatomic,assign) BOOL isPlaying;
/** 是否全屏*/
@property (nonatomic,assign) BOOL isFullScreen;
/** 图片映射*/
@property (nonatomic,strong) NSDictionary *imagesMapping;
@property (nonatomic,weak) id<SRPlayerControlViewDelegate> delegate;
+ (instancetype)controlViewFromXib;


/**
 重置视图
 */
- (void)resetControlView;
/**
 隐藏顶部控制层
 */
- (void)hiddenTopControl;

/**
 显示底部控制层
 */
- (void)showBottomControl;
/**
 隐藏控制层
 */
- (void)hiddenAllControl;

/**
 显示控制层
 */
- (void)showAllControl;
@end
