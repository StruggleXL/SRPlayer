//
//  SRPlayerControlView.m
//  XLVideoPlayerTest
//
//  Created by xl on 16/10/11.
//  Copyright © 2016年 xl. All rights reserved.
//

#import "SRPlayerControlView.h"
#import "SRPlayer.h"

@interface SRPlayerControlView ()
/** 大播放按钮*/
@property (weak, nonatomic) IBOutlet UIButton *startPlay;
/** 重播按钮*/
@property (weak, nonatomic) IBOutlet UIButton *repeatPlayBtn;
/** 菊花*/
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activity;

/** 顶部控制层*/
@property (weak, nonatomic) IBOutlet UIView *topControlView;
/** 返回按钮*/
@property (weak, nonatomic) IBOutlet UIButton *backBtn;
/** 标题*/
@property (weak, nonatomic) IBOutlet UILabel *videotTitle;

/** 底部控制层*/
@property (weak, nonatomic) IBOutlet UIView *bottomControlView;
/** 播放按钮*/
@property (weak, nonatomic) IBOutlet UIButton *playBtn;
/** 当前播放时长*/
@property (weak, nonatomic) IBOutlet UILabel *currentTimeLabel;
/** 播放总时长*/
@property (weak, nonatomic) IBOutlet UILabel *totalTimeLabel;
/** 全屏按钮*/
@property (weak, nonatomic) IBOutlet UIButton *fullScreenBtn;
/** 缓冲进度条*/
@property (weak, nonatomic) IBOutlet UIProgressView *bufferProgress;
/** 滑杆*/
@property (weak, nonatomic) IBOutlet UISlider *videoSlider;

/** 装有需要设置图片的控件*/
@property (nonatomic,strong) NSDictionary *imageUIDic;

@end

@implementation SRPlayerControlView

+ (instancetype)controlViewFromXib {
    SRPlayerControlView *control = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass(self) owner:nil options:nil] firstObject];
    [control setupUI];
    [control resetControlView];
    return control;
}
- (void)setupUI {
    [self.backBtn setImage:SRPlayerImage(@"SRPlayer_back") forState:UIControlStateNormal];
    [self.startPlay setImage:SRPlayerImage(@"SRVideoPlayer_play_big") forState:UIControlStateNormal];
    [self.repeatPlayBtn setImage:SRPlayerImage(@"SRPlayer_repeat_video") forState:UIControlStateNormal];
    [self.playBtn setImage:SRPlayerImage(@"SRPlayer_play") forState:UIControlStateNormal];
    [self.playBtn setImage:SRPlayerImage(@"SRVideoPlayer_pause") forState:UIControlStateSelected];
    [self.fullScreenBtn setImage:SRPlayerImage(@"SRVideoPlayer_zoom_in") forState:UIControlStateNormal];
    [self.fullScreenBtn setImage:SRPlayerImage(@"SRVideoPlayer_zoom_out") forState:UIControlStateSelected];
    [self.videoSlider setThumbImage:SRPlayerImage(@"SRPlayer_slider") forState:UIControlStateNormal];
    self.imageUIDic = @{SRPlayerBackBtnKey:self.backBtn,SRPlayerStartPlayKey:self.startPlay,SRPlayerRepeatPlayKey:self.repeatPlayBtn,SRPlayerplayKey:self.playBtn,SRPlayerPauseKey:self.playBtn,SRPlayerFullScreenKey:self.fullScreenBtn,SRPlayerSmallScreenKey:self.fullScreenBtn,SRPlayerSliderKey:self.videoSlider};
    UITapGestureRecognizer *sliderTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapSliderAction:)];
    [self.videoSlider addGestureRecognizer:sliderTap];
    // slider开始滑动事件
    [self.videoSlider addTarget:self action:@selector(progressSliderTouchBegan:) forControlEvents:UIControlEventTouchDown];
    // slider滑动中事件
    [self.videoSlider addTarget:self action:@selector(progressSliderValueChanged:) forControlEvents:UIControlEventValueChanged];
    // slider结束滑动事件
    [self.videoSlider addTarget:self action:@selector(progressSliderTouchEnded:) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchCancel | UIControlEventTouchUpOutside];
}

- (void)setImagesMapping:(NSDictionary *)imagesMapping {
    _imagesMapping = imagesMapping;
    for (NSString *imageKye in imagesMapping) {
        UIImage *image = imagesMapping[imageKye];
        if (image && [image isKindOfClass:[UIImage class]]) {
            UIView *imageUI = self.imageUIDic[imageKye];
            if ([imageUI isKindOfClass:[UISlider class]]) {
                [self.videoSlider setThumbImage:image forState:UIControlStateNormal];
            } else if ([imageUI isKindOfClass:[UIButton class]]) {
                if ([imageKye isEqualToString:SRPlayerPauseKey] || [imageKye isEqualToString:SRPlayerSmallScreenKey]) {
                    [(UIButton *)imageUI setImage:image forState:UIControlStateSelected];
                } else {
                    [(UIButton *)imageUI setImage:image forState:UIControlStateNormal];
                }
            }
        }
    }
}
#pragma mark - Public
/**
 重置视图
 */
- (void)resetControlView {
    self.videoSlider.value      = 0;
    self.bufferProgress.progress  = 0;
    self.currentTimeLabel.text  = @"00:00";
    self.totalTimeLabel.text    = @"00:00";
    self.startPlay.hidden = YES;
    self.repeatPlayBtn.hidden = YES;
//    self.repeatBtn.hidden       = YES;
    [self.activity stopAnimating];
    self.backgroundColor        = [UIColor clearColor];
}

/**
 隐藏顶部控制层
 */
- (void)hiddenTopControl {
    self.topControlView.alpha = 0;
}

/**
 显示顶部控制层
 */
- (void)showTopControl {
    self.topControlView.alpha = 1;
}

/**
 隐藏底部控制层
 */
- (void)hiddenBottomControl {
    self.bottomControlView.alpha = 0;
}
/**
 显示底部控制层
 */
- (void)showBottomControl {
    self.bottomControlView.alpha = 1;
}
/**
 隐藏控制层
 */
- (void)hiddenAllControl {
    [self hiddenTopControl];
    [self hiddenBottomControl];
}
/**
 显示控制层
 */
- (void)showAllControl {
    [self showTopControl];
    [self showBottomControl];
}
#pragma mark -Setter 
- (void)setIsPlaying:(BOOL)isPlaying {
    _isPlaying = isPlaying;
    self.playBtn.selected = isPlaying;
}
- (void)setIsFullScreen:(BOOL)isFullScreen {
    _isFullScreen = isFullScreen;
    self.fullScreenBtn.selected = isFullScreen;
}
#pragma mark -Event


/**
 播放／暂停 点击事件

 @param sender UIButton
 */
- (IBAction)playerOrPauseClick:(UIButton *)sender {
    sender.selected = !sender.selected;
    self.isPlaying = sender.selected;
    if (self.delegate && [self.delegate respondsToSelector:@selector(playerControl:playBtnPlayerOrPause:)]) {
        [self.delegate playerControl:self playBtnPlayerOrPause:sender.selected];
    }
}

/**
 滑杆点击事件
 */
- (void)tapSliderAction:(UITapGestureRecognizer *)tap {
    if ([tap.view isKindOfClass:[UISlider class]] && self.delegate && [self.delegate respondsToSelector:@selector(playerControl:sliderTapValue:)]) {
        UISlider *slider = (UISlider *)tap.view;
        CGPoint point = [tap locationInView:slider];
        CGFloat length = slider.frame.size.width;
        // 视频跳转的value
        CGFloat tapValue = point.x / length;
        [self.delegate playerControl:self sliderTapValue:tapValue];
    }
}
- (void)progressSliderTouchBegan:(UISlider *)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(playerControlSliderStartSlide:)]) {
        [self.delegate playerControlSliderStartSlide:self];
    }

}
/** 滑杆滑动中事件*/
- (void)progressSliderValueChanged:(UISlider *)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(playerControl:sliderValueChange:)]) {
        [self.delegate playerControl:self sliderValueChange:sender.value];
    }
}
/** 滑杆结束滑动事件*/
- (void)progressSliderTouchEnded:(UISlider *)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(playerControl:sliderTapValue:)]) {
        [self.delegate playerControl:self sliderTapValue:sender.value];
    }
}
/** 全屏点击事件*/
- (IBAction)fullScreenClick:(UIButton *)sender {
    sender.selected = !sender.selected;
    self.isFullScreen = sender.selected;
    if (self.delegate && [self.delegate respondsToSelector:@selector(playerControl:fullScreenBtnClick:)]) {
        [self.delegate playerControl:self fullScreenBtnClick:sender.selected];
    }
}
/** 返回按钮点击事件*/
- (IBAction)backClick:(UIButton *)sender {
    if (self.isFullScreen) {
        [self fullScreenClick:self.fullScreenBtn];
    } else {
        if (self.delegate && [self.delegate respondsToSelector:@selector(playerControlBackBtnClick:)]) {
            [self.delegate playerControlBackBtnClick:self];
        }
    }
}

@end
