//
//  SRPlayerView.m
//  XLVideoPlayerTest
//
//  Created by xl on 16/10/11.
//  Copyright © 2016年 xl. All rights reserved.
//

#import "SRPlayerView.h"
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import "SRPlayer.h"

#define widthAll MIN([UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)
#define heightAll MAX([UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)
// 隐藏控制层动画时间
static const CGFloat SRPlayerControlViewHiddenAnimationTimeInterval = 0.3f;
// 控制层的显示时间
static const CGFloat SRPlayerControlViewShowTimeInterval = 5.0f;

// 水平移动方向和垂直移动方向
typedef NS_ENUM(NSInteger, PanDirection){
    PanDirectionHorizontalMoved, // 横向移动
    PanDirectionVerticalMoved    // 纵向移动
};

@interface SRPlayerView ()<UIGestureRecognizerDelegate,SRPlayerControlViewDelegate>

/** 播放属性 */
@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) AVPlayerItem *playerItem;
@property (nonatomic, strong) AVURLAsset *urlAsset;
@property (nonatomic, strong) AVAssetImageGenerator *imageGenerator;
@property (nonatomic, strong) AVPlayerLayer *playerLayer;
@property (nonatomic,strong) id playerObserver;

@property (nonatomic, strong) UITapGestureRecognizer *tap;

/** 设备方向*/
@property (nonatomic) UIDeviceOrientation orientation;
/** 竖屏状态下的位置*/
@property (nonatomic,assign) CGRect portraitFrame;
/** 控制层*/
@property (nonatomic,strong) SRPlayerControlView *SR_controlView;
/** 音量滑杆 */
@property (nonatomic, strong) UISlider *volumeViewSlider;
/** 滑动方向*/
@property (nonatomic, assign) PanDirection panDirection;
/** 用来保存快进的总时长 */
@property (nonatomic, assign) CGFloat sumTime;
/** 是否在调节音量*/
@property (nonatomic, assign) BOOL isVolume;
/** 是否在缓冲*/
@property (nonatomic, assign) BOOL isBufferingState;

/** 是否是本地文件 */
@property (nonatomic, assign) BOOL isLocalVideo;
/** 控制层是否正在显示*/
@property (nonatomic,assign) BOOL isShowingControl;
/** 是否由用户暂停*/  //[若由用户暂停，进入前台，继续暂停，否则，自动播放]
@property (nonatomic,assign) BOOL isPauseByUser;
/** slider上次的值 */
@property (nonatomic, assign) CGFloat sliderLastValue;
/** slider是否还在改变状态 */
@property (nonatomic, assign) BOOL sliderIsValueChanging;
/** 视频是否播放完 */
@property (nonatomic, assign) BOOL videoDidEnd;



@end

@implementation SRPlayerView

#pragma mark -life Cycle
- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setupUI];
    }
    return self;
}
- (void)awakeFromNib
{
    [super awakeFromNib];
    [self setupUI];
    
}
- (void)setPortraitFrame:(CGRect)portraitFrame {
    
    if (CGRectEqualToRect(_portraitFrame,CGRectZero)) {
        _portraitFrame = portraitFrame;
    }
}

- (void)setupUI {
    self.autoresizesSubviews = NO;
    self.backgroundColor = [UIColor blackColor];
    self.SR_controlView = [SRPlayerControlView controlViewFromXib];
    self.SR_controlView.delegate = self;
    [self addSubview:self.SR_controlView];
    [self.SR_controlView hiddenAllControl];
    self.SR_controlView.hidden = YES;
    
}
- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    self.SR_controlView.frame = self.bounds;
    self.playerLayer.frame = self.bounds;
}
- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.frame = self.frame;
    self.portraitFrame = self.frame;
    
}

- (void)dealloc
{
    self.playerItem = nil;
    // 移除通知
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    // 移除time观察者
    if (self.playerObserver) {
        [self.player removeTimeObserver:self.playerObserver];
        self.playerObserver = nil;
    }
}
/** 重置播放器*/
- (void)resetPlayer
{
    // 改为为播放完
    self.videoDidEnd = NO;
    self.playerItem = nil;
    if (self.playerObserver) {
        [self.player removeTimeObserver:self.playerObserver];
        self.playerObserver = nil;
    }
    // 移除通知
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    // 暂停
    [self pause];
    // 移除原来的layer
    [self.playerLayer removeFromSuperlayer];
    self.imageGenerator = nil;
    // 替换PlayerItem为nil
    [self.player replaceCurrentItemWithPlayerItem:nil];
    // 把player置为nil
    self.player = nil;
    [self.SR_controlView resetControlView];

    
}
#pragma mark - Setter
/**
 *  根据playerItem，来添加移除观察者
 */
- (void)setPlayerItem:(AVPlayerItem *)playerItem
{
    if (_playerItem == playerItem) return;
    
    if (_playerItem) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:_playerItem];
        [_playerItem removeObserver:self forKeyPath:@"status"];
        [_playerItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
        [_playerItem removeObserver:self forKeyPath:@"playbackBufferEmpty"];
        [_playerItem removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
    }
    _playerItem = playerItem;
    if (playerItem) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moviePlayDidEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:playerItem];
        [playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
        [playerItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
        // 缓冲区空了，需要等待数据
        [playerItem addObserver:self forKeyPath:@"playbackBufferEmpty" options:NSKeyValueObservingOptionNew context:nil];
        // 缓冲区有足够数据可以播放了
        [playerItem addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:NSKeyValueObservingOptionNew context:nil];
    }
}

- (void)setIsBufferingState:(BOOL)isBufferingState {
    _isBufferingState = isBufferingState;
    if (!isBufferingState) {
        // 改为黑色的背景，不然站位图会显示
        UIImage *image = [self drawImageFromColor:[UIColor blackColor]];
        self.layer.contents = (id) image.CGImage;
    }
    // 控制菊花显示、隐藏
    isBufferingState ? ([self.SR_controlView.activity startAnimating]) : ([self.SR_controlView.activity stopAnimating]);
}
- (void)setImageMapping:(NSDictionary *)imageMapping {
    _imageMapping = imageMapping;
    self.SR_controlView.imagesMapping = imageMapping;
}
#pragma mark - Getter
- (AVAssetImageGenerator *)imageGenerator
{
    if (!_imageGenerator) {
        _imageGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:self.urlAsset];
    }
    return _imageGenerator;
}
#pragma mark -设置视频
- (void)setSR_playerItem:(SRPlayerItem *)SR_playerItem {
    _SR_playerItem = SR_playerItem;
    // 先重置player
    [self resetPlayer];
    [self playeVideoWithPlayerItem:SR_playerItem];
}
/** 播放视频*/
- (void)playeVideoWithPlayerItem:(SRPlayerItem *)playerItem {
    // 设置标题
    self.SR_controlView.videotTitle.text = playerItem.videoTitle;
   
    self.urlAsset = [AVURLAsset assetWithURL:self.SR_playerItem.videoURL];
    // 设置占位图片
    if (playerItem.videoImage) {
        self.layer.contents = (id) playerItem.videoImage.CGImage;
    } else { //默认显示第一帧图片
        dispatch_queue_t queue = dispatch_queue_create("com.playerVideoImage.queue", DISPATCH_QUEUE_CONCURRENT);
            dispatch_async(queue, ^{
                 UIImage *image = [self frameVideoImageAtTime:1];
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.layer.contents = (id)image.CGImage;
                });
            });
        
    }
    // 显示控制层整体view
    self.SR_controlView.hidden = NO;
    self.SR_controlView.startPlay.hidden = NO;
    [self setupEvent];
    if (playerItem.isAutoPlay) {
        [self configSRPlayer];
    }
}
- (void)setPlayerItems:(NSArray<SRPlayerItem *> *)playerItems {
    _playerItems = playerItems;
    SRPlayerItem *playerItem = playerItems[0];
    self.SR_playerItem = playerItem;
}
- (void)configSRPlayer {
    if (!self.SR_playerItem.videoURL) return;
    self.urlAsset = [AVURLAsset assetWithURL:self.SR_playerItem.videoURL];
    // 初始化playerItem
    self.playerItem = [AVPlayerItem playerItemWithAsset:self.urlAsset];
    self.player = [AVPlayer playerWithPlayerItem:self.playerItem];
    
    // 初始化playerLayer
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    
    // 此处为默认视频填充模式
//    self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    // 添加playerLayer到self.layer
    [self.layer insertSublayer:self.playerLayer atIndex:0];
    
    // 跟踪播放时间
    [self createTimer];
    // 添加手势
    [self creatGesture];
    // 获取系统音量
    [self configVolume];
    
    self.isShowingControl = NO;
    // 延迟隐藏controlView
    [self showControlView];
    
    if (![self.SR_playerItem.videoURL.scheme isEqualToString:@"file"]) { // 非本地文件
        self.isLocalVideo = NO;
        self.isBufferingState = YES;
    } else {
        self.isLocalVideo = YES;
    }
    // 播放
    [self play];
    // 隐藏大播放按钮
    self.SR_controlView.startPlay.hidden = YES;
   
}
/** 重播点击事件*/
- (void)repeatPlay:(UIButton *)sender
{
    // 没有播放完
    self.videoDidEnd = NO;

    // 准备显示控制层
    self.isShowingControl = NO;
    [self showControlView];
    // 重置控制层View
    [self.SR_controlView resetControlView];
    [self seekToTime:0 completionHandler:nil];
}
- (void)createTimer
{
    __weak typeof(self) weakSelf = self;
    self.playerObserver = [self.player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(1, 1) queue:NULL usingBlock:^(CMTime time){
        AVPlayerItem *currentItem = weakSelf.playerItem;
        NSArray *loadedRanges = currentItem.seekableTimeRanges;
        if (loadedRanges.count > 0 && currentItem.duration.timescale != 0) {
            NSInteger currentTime = (NSInteger)CMTimeGetSeconds([currentItem currentTime]);
            // 当前时长进度progress
            NSInteger proMin = currentTime / 60;//当前秒
            NSInteger proSec = currentTime % 60;//当前分钟
            CGFloat totalTime = (CGFloat)currentItem.duration.value / currentItem.duration.timescale;
            // duration 总时长
            NSInteger durMin = (NSInteger)totalTime / 60;//总秒
            NSInteger durSec = (NSInteger)totalTime % 60;//总分钟
            if (!weakSelf.sliderIsValueChanging) {
                // 更新slider
                weakSelf.SR_controlView.videoSlider.value = CMTimeGetSeconds([currentItem currentTime]) / totalTime;
                // 更新当前播放时间
                weakSelf.SR_controlView.currentTimeLabel.text = [NSString stringWithFormat:@"%02zd:%02zd", proMin, proSec];
                // 更新总时间
                weakSelf.SR_controlView.totalTimeLabel.text = [NSString stringWithFormat:@"%02zd:%02zd", durMin, durSec];
            }
        }
    }];
}


- (void)creatGesture {
    // 单击
    self.tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapAction:)];
    [self addGestureRecognizer:self.tap];
}
/**
 *  获取系统音量
 */
- (void)configVolume
{
    MPVolumeView *volumeView = [[MPVolumeView alloc] init];
    _volumeViewSlider = nil;
    for (UIView *view in [volumeView subviews]){
        if ([view.class.description isEqualToString:@"MPVolumeSlider"]){
            _volumeViewSlider = (UISlider *)view;
            break;
        }
    }
    
    // 使用这个category的应用不会随着手机静音键打开而静音，可在手机静音下播放声音
    NSError *setCategoryError = nil;
    BOOL success = [[AVAudioSession sharedInstance]
                    setCategory: AVAudioSessionCategoryPlayback
                    error: &setCategoryError];
    
    if (!success) {
    }
    
    // 监听耳机插入和拔掉通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioRouteChangeListenerCallback:) name:AVAudioSessionRouteChangeNotification object:nil];
}

/**
 *  耳机插入、拔出事件
 */
- (void)audioRouteChangeListenerCallback:(NSNotification*)notification
{
    NSDictionary *interuptionDict = notification.userInfo;
    
    NSInteger routeChangeReason = [[interuptionDict valueForKey:AVAudioSessionRouteChangeReasonKey] integerValue];
    
    switch (routeChangeReason) {
            
        case AVAudioSessionRouteChangeReasonNewDeviceAvailable:
            // 耳机插入
            break;
            
        case AVAudioSessionRouteChangeReasonOldDeviceUnavailable:
        {
            // 拔掉耳机暂停播放
            [self pause];
        }
            break;
            
        case AVAudioSessionRouteChangeReasonCategoryChange:
           
            break;
    }
}
/**
 *  播放
 */
- (void)play
{
    self.SR_controlView.isPlaying = YES;
    self.isPauseByUser = NO;
    [_player play];
}
/**
 * 暂停
 */
- (void)pause
{
    self.SR_controlView.isPlaying = NO;
    self.isPauseByUser = YES;
    [_player pause];
}
/**
 *  从xx秒开始播放视频跳转
 *
 *  @param dragedSeconds 视频跳转的秒数
 */
- (void)seekToTime:(NSInteger)dragedSeconds completionHandler:(void (^)(BOOL finished))completionHandler
{
    if (self.player.currentItem.status == AVPlayerItemStatusReadyToPlay) {
        // seekTime:completionHandler:不能精确定位
        // 如果需要精确定位，可以使用seekToTime:toleranceBefore:toleranceAfter:completionHandler:
        // 转换成CMTime才能给player来控制播放进度
        CMTime dragedCMTime = CMTimeMake(dragedSeconds, 1);
        [self.player seekToTime:dragedCMTime toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero completionHandler:^(BOOL finished) {
            // 视频跳转回调
            if (completionHandler) {
                completionHandler(finished);
            }
            
            [self play];
            self.sliderIsValueChanging = NO;
//            self.seekTime = 0;
            if (!self.playerItem.isPlaybackLikelyToKeepUp && !self.isLocalVideo) {
                self.isBufferingState = YES;
            }
        }];
    }
}
#pragma mark -设置事件
- (void)setupEvent {
    // app退到后台
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterBackground) name:UIApplicationWillResignActiveNotification object:nil];
    // app进入前台
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterPlayGround) name:UIApplicationDidBecomeActiveNotification object:nil];
    // 设备方向改变
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientChange:) name:UIDeviceOrientationDidChangeNotification object:nil];
    // 中间按钮播放
    [self.SR_controlView.startPlay addTarget:self action:@selector(configSRPlayer) forControlEvents:UIControlEventTouchUpInside];
    // 重播
    [self.SR_controlView.repeatPlayBtn addTarget:self action:@selector(repeatPlay:) forControlEvents:UIControlEventTouchUpInside];
}
#pragma mark -kvo、监听
/** 播放完了*/
- (void)moviePlayDidEnd:(NSNotification *)notification
{
    self.videoDidEnd = YES;
    NSUInteger index = [self.playerItems indexOfObject:self.SR_playerItem];
    if (self.playerItems && self.playerItems.count > index+1) {
        // 视频数组中还存在未播放的视频item，继续播放
        [self setSR_playerItem:self.playerItems[index+1]];
    } else {
        if (self.SR_controlView.isFullScreen) {
            // 全屏状态，退出全屏
            self.SR_controlView.isFullScreen = NO;
            [self playerControl:self.SR_controlView fullScreenBtnClick:NO];
        }
        self.SR_controlView.repeatPlayBtn.hidden = NO;
        self.isShowingControl = NO;
       
    }
     [self showControlView];
    
}
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (object == self.player.currentItem) {
        if ([keyPath isEqualToString:@"status"]) {
            
            if (self.player.currentItem.status == AVPlayerItemStatusReadyToPlay) {
                
                self.isBufferingState = NO;
                // 加载完成后，再添加平移手势
                // 添加平移手势，用来控制音量、亮度、快进快退
                UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(panDirection:)];
                pan.delegate = self;
                [self addGestureRecognizer:pan];
                
                // 跳到xx秒播放视频
                if (self.SR_playerItem.seekTime) {
                    [self seekToTime:self.SR_playerItem.seekTime completionHandler:nil];
                }
                
            } else if (self.player.currentItem.status == AVPlayerItemStatusFailed){
                NSLog(@"视频加载失败");
               
            }
        }
        else if ([keyPath isEqualToString:@"loadedTimeRanges"]) {
            
            // 计算缓冲进度
            NSTimeInterval timeInterval = [self availableDuration];
            CMTime duration             = self.playerItem.duration;
            CGFloat totalDuration       = CMTimeGetSeconds(duration);
            [self.SR_controlView.bufferProgress setProgress:timeInterval / totalDuration animated:NO];
            
            // 如果缓冲和当前slider的差值超过0.1,自动播放，解决弱网情况下不会自动播放问题
            if (!self.isPauseByUser && (self.SR_controlView.bufferProgress.progress-self.SR_controlView.videoSlider.value > 0.05)) {
                [self play];
            }
            
        } else if ([keyPath isEqualToString:@"playbackBufferEmpty"]) {
            
            // 当缓冲是空的时候
            if (self.playerItem.playbackBufferEmpty) {
                self.isBufferingState = YES;
                [self bufferingSomeSecond];
            }
            
        } else if ([keyPath isEqualToString:@"playbackLikelyToKeepUp"]) {
            
            // 当缓冲好的时候
            if (self.playerItem.playbackLikelyToKeepUp && self.isBufferingState == YES){
                self.isBufferingState = NO;
            }
            
        }
    }
    
}
/**
 *  应用退到后台
 */
- (void)appDidEnterBackground
{
    
    if (self.playerItem) {
        if (self.SR_controlView.isFullScreen) {
             UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
            if (orientation == UIDeviceOrientationPortrait || orientation == UIDeviceOrientationFaceUp) {
                self.orientation = UIDeviceOrientationLandscapeLeft;
            } else{
                self.orientation = orientation;
            }
            
        }
        [_player pause];
        [self cancelAutoDelayHiddenControlView];
        self.SR_controlView.isPlaying = NO;
    }

}

/**
 *  应用进入前台
 */
- (void)appDidEnterPlayGround
{

    if (self.playerItem) {
        //    self.didEnterBackground = NO;
        self.isShowingControl = NO;
        // 延迟隐藏controlView
        [self showControlView];
        if (!self.isPauseByUser) {
            self.SR_controlView.isPlaying = YES;
            [self play];
        }
    }

}
#pragma mark - 缓冲较差时候

/**
 *  缓冲较差时候回调这里
 */
- (void)bufferingSomeSecond
{
    self.isBufferingState = YES;
    // playbackBufferEmpty会反复进入，因此在bufferingOneSecond延时播放执行完之前再调用bufferingSomeSecond都忽略
    __block BOOL isBuffering = NO;
    if (isBuffering) return;
    isBuffering = YES;
    
    // 需要先暂停一小会之后再播放，否则网络状况不好的时候时间在走，声音播放不出来
    [self.player pause];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        // 如果此时用户已经暂停了，则不再需要开启播放了
        if (self.isPauseByUser) {
            isBuffering = NO;
            return;
        }
        
        [self play];
        // 如果执行了play还是没有播放则说明还没有缓存好，则再次缓存一段时间
        isBuffering = NO;
        if (!self.playerItem.isPlaybackLikelyToKeepUp) {
            [self bufferingSomeSecond];
        }
        
    });
}
#pragma mark - 计算缓冲进度

/**
 *  计算缓冲进度
 *
 *  @return 缓冲进度
 */
- (NSTimeInterval)availableDuration {
    NSArray *loadedTimeRanges = [[_player currentItem] loadedTimeRanges];
    CMTimeRange timeRange     = [loadedTimeRanges.firstObject CMTimeRangeValue];// 获取缓冲区域
    float startSeconds        = CMTimeGetSeconds(timeRange.start);
    float durationSeconds     = CMTimeGetSeconds(timeRange.duration);
    NSTimeInterval result     = startSeconds + durationSeconds;// 计算缓冲总进度
    return result;
}
#pragma mark -手势

/**
 *   tap方法
 *
 */
- (void)tapAction:(UITapGestureRecognizer *)gesture
{
    if (gesture.state == UIGestureRecognizerStateRecognized) {
       
        self.isShowingControl? [self hiddenControlView]:[self showControlView];
    }
}
/**
 *  pan手势事件
 *
 *  @param pan UIPanGestureRecognizer
 */
- (void)panDirection:(UIPanGestureRecognizer *)pan
{
    //根据在view上Pan的位置，确定是调音量还是亮度
    CGPoint locationPoint = [pan locationInView:self];
    
    // 我们要响应水平移动和垂直移动
    // 根据上次和本次移动的位置，算出一个速率的point
    CGPoint veloctyPoint = [pan velocityInView:self];
    
    // 判断是垂直移动还是水平移动
    switch (pan.state) {
        case UIGestureRecognizerStateBegan:{ // 开始移动
            // 使用绝对值来判断移动的方向
            CGFloat x = fabs(veloctyPoint.x);
            CGFloat y = fabs(veloctyPoint.y);
            if (x > y) { // 水平移动
                
                self.panDirection = PanDirectionHorizontalMoved;
                // 给sumTime初值
                CMTime time       = self.player.currentTime;
                self.sumTime      = time.value/time.timescale;
                
                self.sliderIsValueChanging = YES;
                [self cancelAutoDelayHiddenControlView];

            }
            else if (x < y){ // 垂直移动
                self.panDirection = PanDirectionVerticalMoved;
                // 开始滑动的时候,状态改为正在控制音量
                if (locationPoint.x > self.bounds.size.width / 2) {
                    self.isVolume = YES;
                }else { // 状态改为显示亮度调节
                    self.isVolume = NO;
                }
            }
            break;
        }
        case UIGestureRecognizerStateChanged:{ // 正在移动
            switch (self.panDirection) {
                case PanDirectionHorizontalMoved:{
                    [self horizontalMoved:veloctyPoint.x]; // 水平移动的方法只要x方向的值
                    break;
                }
                case PanDirectionVerticalMoved:{
                    [self verticalMoved:veloctyPoint.y]; // 垂直移动方法只要y方向的值
                    break;
                }
                default:
                    break;
            }
            break;
        }
        case UIGestureRecognizerStateEnded:{ // 移动停止
            // 移动结束也需要判断垂直或者平移
            // 比如水平移动结束时，要快进到指定位置，如果这里没有判断，当我们调节音量完之后，会出现屏幕跳动的bug
            switch (self.panDirection) {
                case PanDirectionHorizontalMoved:{
                    
//                    // 继续播放
//                    [self play];
//                    
//                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//                        // 隐藏视图
//                        self.controlView.horizontalLabel.hidden = YES;
//                    });
                    // 快进、快退时候把开始播放按钮改为播放状态
//                    self.controlView.startBtn.selected = YES;
//                    self.isPauseByUser                 = NO;
                    
                    [self seekToTime:self.sumTime completionHandler:nil];
                    // 把sumTime置空，不然会越加越多
                    self.sumTime = 0;
                    break;
                }
                case PanDirectionVerticalMoved:{
                    // 垂直移动结束后，把状态改为不再控制音量
                    self.isVolume = NO;
//                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//                        self.controlView.horizontalLabel.hidden = YES;
//                    });
                    break;
                }
                default:
                    break;
            }
            break;
        }
        default:
            break;
    }
}

/**
 *  pan垂直移动的方法
 *
 *  @param value void
 */
- (void)verticalMoved:(CGFloat)value
{
    self.isVolume ? (self.volumeViewSlider.value -= value / 10000) : ([UIScreen mainScreen].brightness -= value / 10000);
}

/**
 *  pan水平移动的方法
 *
 *  @param value void
 */
- (void)horizontalMoved:(CGFloat)value
{
    // 快进快退的方法
    NSString *style = @"";
    if (value < 0) { style = @"<<"; }
    if (value > 0) { style = @">>"; }
    if (value == 0) { return; }
    
    // 每次滑动需要叠加时间
    self.sumTime += value / 200;
    
    // 需要限定sumTime的范围
    CMTime totalTime           = self.playerItem.duration;
    CGFloat totalMovieDuration = (CGFloat)totalTime.value/totalTime.timescale;
    if (self.sumTime > totalMovieDuration) { self.sumTime = totalMovieDuration;}
    if (self.sumTime < 0) { self.sumTime = 0; }
    
    // 当前快进的时间
    NSString *nowTime         = [self durationStringWithTime:(int)self.sumTime];
    // 总时间
    NSString *durationTime    = [self durationStringWithTime:(int)totalMovieDuration];
    
   
    // 更新slider的进度
    self.SR_controlView.videoSlider.value     = self.sumTime/totalMovieDuration;
    // 更新现在播放的时间
    self.SR_controlView.currentTimeLabel.text = nowTime;
}

/**
 *  根据时长求出字符串
 *
 *  @param time 时长
 *
 *  @return 时长字符串
 */
- (NSString *)durationStringWithTime:(int)time
{
    // 获取分钟
    NSString *min = [NSString stringWithFormat:@"%02d",time / 60];
    // 获取秒数
    NSString *sec = [NSString stringWithFormat:@"%02d",time % 60];
    return [NSString stringWithFormat:@"%@:%@", min, sec];
}
#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if ([gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]]) {
        CGPoint point = [touch locationInView:self.SR_controlView];
        // （屏幕下方slider区域） || (播放完了) =====>  不响应pan手势
        if ((point.y > self.bounds.size.height-40) || self.videoDidEnd) {
            return NO;
        }
        return YES;
    }
    return YES;
}
#pragma mark -控制层
/**
 *  隐藏控制层
 */
- (void)hiddenControlView {
    if (!self.isShowingControl) return;
    [UIView animateWithDuration:SRPlayerControlViewHiddenAnimationTimeInterval animations:^{
        [self.SR_controlView hiddenAllControl];
        if (self.SR_controlView.isFullScreen) { //全屏状态
            [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
        }
    }completion:^(BOOL finished) {
        self.isShowingControl = NO;
    }];
}
/**
 *  显示控制层
 */
- (void)showControlView
{
    if (self.isShowingControl)  return;
    [UIView animateWithDuration:SRPlayerControlViewHiddenAnimationTimeInterval animations:^{
    
        if (self.videoDidEnd) { // 播放结束
            [self.SR_controlView hiddenAllControl];
        } else {
            if (self.SR_controlView.isFullScreen) {
                [self.SR_controlView showAllControl];
            } else {
                [self.SR_controlView showBottomControl];
                [self.SR_controlView hiddenTopControl];
            }
        }
        if ([UIApplication sharedApplication].statusBarHidden) {
            [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
        }
    } completion:^(BOOL finished) {
        self.isShowingControl = YES;
        [self autoDelayHiddenControlView];
    }];
}
/** 经过一定时间后自动隐藏控制层*/
- (void)autoDelayHiddenControlView {
    if (!self.isShowingControl) return;
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hiddenControlView) object:nil];
    [self performSelector:@selector(hiddenControlView) withObject:nil afterDelay:SRPlayerControlViewShowTimeInterval];
}
/**
 *  取消延时隐藏controlView的方法
 */
- (void)cancelAutoDelayHiddenControlView
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
}
#pragma mark -横竖屏坐标事件
/** 设备方向变化的通知*/
- (void)orientChange:(NSNotification *)noti {
    UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
    if (self.SR_controlView.isFullScreen && self.orientation == UIDeviceOrientationLandscapeLeft ) {
        self.orientation = orientation;
        return;
    }
    switch (orientation)
    {
        case UIDeviceOrientationPortrait: {
            self.SR_controlView.isFullScreen = NO;
        }
            break;
        case UIDeviceOrientationLandscapeLeft: {
            
            self.SR_controlView.isFullScreen = YES;
        }
            break;
        case UIDeviceOrientationLandscapeRight: {
            self.SR_controlView.isFullScreen = YES;
        }
            break;
        default:
            break;
    }
    if (self.delegate && [self.delegate respondsToSelector:@selector(playerView:OrientationChange:)]) {
        [self.delegate playerView:self OrientationChange:self.SR_controlView.isFullScreen];
    }
    [self screenOrientationWithDeviceOrientation:orientation];
}

- (void)screenOrientationWithDeviceOrientation:(UIDeviceOrientation)orientation {
    switch (orientation)
    {
        case UIDeviceOrientationPortrait: {
            [self portraitScreenAction];
        }
            break;
            
        case UIDeviceOrientationLandscapeLeft: {
            [self rightScreenAction];
        }
            break;
        case UIDeviceOrientationLandscapeRight: {
            [self leftScreenAction];
            
        }
            break;
        default:
            break;
    }
}
-(void)portraitScreenAction
{
    
    [UIView animateWithDuration:[[UIApplication sharedApplication] statusBarOrientationAnimationDuration] animations:^{
        self.transform = CGAffineTransformMakeRotation(0);
        self.frame = self.portraitFrame;
        // 只要屏幕旋转就显示控制层
        self.isShowingControl = NO;
        // 延迟隐藏controlView
        [self showControlView];
    }];
    [[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationPortrait animated:YES];
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    
}

-(void)rightScreenAction
{
    [UIView animateWithDuration:[[UIApplication sharedApplication] statusBarOrientationAnimationDuration] animations:^{
        self.transform = CGAffineTransformMakeRotation(M_PI*0.5);
        self.frame = CGRectMake(0, 0, widthAll,heightAll);
        // 只要屏幕旋转就显示控制层
        self.isShowingControl = NO;
        // 延迟隐藏controlView
        [self showControlView];
    }];
    [[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationLandscapeRight animated:YES];
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    
}
-(void)leftScreenAction
{
    [UIView animateWithDuration:[[UIApplication sharedApplication] statusBarOrientationAnimationDuration] animations:^{
        self.transform = CGAffineTransformMakeRotation(-M_PI*0.5);
        self.frame = CGRectMake(0, 0, widthAll,heightAll);
        // 只要屏幕旋转就显示控制层
        self.isShowingControl = NO;
        // 延迟隐藏controlView
        [self showControlView];
    }];
    [[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationLandscapeLeft animated:YES];
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    
}
#pragma mark - Others

/**
 *  通过颜色来生成一个纯色图片
 */
- (UIImage *)drawImageFromColor:(UIColor *)color
{
    CGRect rect = self.bounds;
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return img;
}
/** 获取视频第xx秒的帧图片*/
- (UIImage *)frameVideoImageAtTime:(NSTimeInterval)time {
    NSError *error;
    CMTime actualTime;
    CMTime dragedCMTime = CMTimeMake(time, 1);
    CGImageRef cgImage = [self.imageGenerator copyCGImageAtTime:dragedCMTime actualTime:&actualTime error:&error];
    CMTimeShow(actualTime);
    UIImage *image = [UIImage imageWithCGImage:cgImage];
    CGImageRelease(cgImage);
    return image;
}
#pragma mark -SRPlayerControlViewDelegate
/** 播放／暂停 按钮回调*/
- (void)playerControl:(SRPlayerControlView *)control playBtnPlayerOrPause:(BOOL)play {
    if (play) {
        [self play];
    } else {
        [self pause];
    }
}
/** 滑杆开始滑动 回调*/
- (void)playerControlSliderStartSlide:(SRPlayerControlView *)control{
    // 关闭controlView的延迟隐藏，防止滑动时，controlView自动隐藏
    self.sliderIsValueChanging = YES;
    [self cancelAutoDelayHiddenControlView];
}
/** 滑杆点击、滑动结束 回调*/
- (void)playerControl:(SRPlayerControlView *)control sliderTapValue:(CGFloat)tapValue{
    
    if (self.player.currentItem.status == AVPlayerItemStatusReadyToPlay) {
        
//        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//            self.controlView.horizontalLabel.hidden = YES;
//        });
        
        // 滑动结束延时隐藏controlView
        [self autoDelayHiddenControlView];
        // 视频总时间长度
        CGFloat total = (CGFloat)_playerItem.duration.value / _playerItem.duration.timescale;
        
        //计算出拖动的当前秒数
        NSInteger dragedSeconds = floorf(total * tapValue);
        
        [self seekToTime:dragedSeconds completionHandler:nil];
    }
    
}

/** 滑杆滑动中 回调*/
- (void)playerControl:(SRPlayerControlView *)control sliderValueChange:(CGFloat)changeValue {
    
    if (self.player.currentItem.status == AVPlayerItemStatusReadyToPlay) {
        NSString *style = @"";
        CGFloat value   = changeValue - self.sliderLastValue;
        if (value > 0) { style = @">>"; }
        if (value < 0) { style = @"<<"; }
        if (value == 0) { return; }
        
        self.sliderLastValue    = changeValue;
        
        CGFloat total           = (CGFloat)_playerItem.duration.value / _playerItem.duration.timescale;
        
        //计算出拖动的当前秒数
        NSInteger dragedSeconds = floorf(total * changeValue);
        
        //转换成CMTime才能给player来控制播放进度
        
        CMTime dragedCMTime     = CMTimeMake(dragedSeconds, 1);
        // 拖拽的时长
        NSInteger proMin        = (NSInteger)CMTimeGetSeconds(dragedCMTime) / 60;//当前秒
        NSInteger proSec        = (NSInteger)CMTimeGetSeconds(dragedCMTime) % 60;//当前分钟
        
        //duration 总时长
        NSInteger durMin        = (NSInteger)total / 60;//总秒
        NSInteger durSec        = (NSInteger)total % 60;//总分钟
        
        NSString *currentTime   = [NSString stringWithFormat:@"%02zd:%02zd", proMin, proSec];
        NSString *totalTime     = [NSString stringWithFormat:@"%02zd:%02zd", durMin, durSec];
        
        if (total > 0) { // 当总时长 > 0时候才能拖动slider
            self.SR_controlView.currentTimeLabel.text  = currentTime;
            if (self.SR_controlView.isFullScreen) {
//                [self.SR_controlView.videoSlider setText:currentTime];
//                dispatch_queue_t queue = dispatch_queue_create("com.playerPic.queue", DISPATCH_QUEUE_CONCURRENT);
//                dispatch_async(queue, ^{
//                    [self frameVideoImageAtTime:dragedSeconds];
//                    dispatch_async(dispatch_get_main_queue(), ^{
//                        [self.SR_controlView.videoSlider setImage:image ? : ZFPlayerImage(@"ZFPlayer_loading_bgView")];
//                    });
//                });
                
            } else {
//                self.controlView.horizontalLabel.hidden = NO;
//                self.controlView.horizontalLabel.text   = [NSString stringWithFormat:@"%@ %@ / %@",style, currentTime, totalTime];
            }
        }else {
            // 此时设置slider值为0
            self.SR_controlView.videoSlider.value = 0;
        }
        
    }else { // player状态加载失败
        // 此时设置slider值为0
        self.SR_controlView.videoSlider.value = 0;
    }
}
/** 全屏按钮 回调*/
- (void)playerControl:(SRPlayerControlView *)control fullScreenBtnClick:(BOOL)fullScreen {
    if (self.delegate && [self.delegate respondsToSelector:@selector(playerView:OrientationChange:)]) {
        [self.delegate playerView:self OrientationChange:fullScreen];
    }
    if (fullScreen) {
        [self rightScreenAction];
    } else {
        [self portraitScreenAction];
    }
}
/** 返回按钮 回调*/
- (void)playerControlBackBtnClick:(SRPlayerControlView *)control {
    if (self.delegate && [self.delegate respondsToSelector:@selector(playerViewBackVC:)]) {
        [self.delegate playerViewBackVC:self];
    }
}
@end
