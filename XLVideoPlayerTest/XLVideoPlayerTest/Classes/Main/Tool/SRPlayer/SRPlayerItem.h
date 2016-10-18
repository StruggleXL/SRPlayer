//
//  SRPlayerItem.h
//  XLVideoPlayerTest
//
//  Created by xl on 16/10/13.
//  Copyright © 2016年 xl. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface SRPlayerItem : NSObject

/** 视频源*/
@property (nonatomic,strong) NSURL * videoURL;

/** 视频标题*/
@property (nonatomic,copy) NSString *videoTitle;

/** 视频默认图片*/  //若不设置，会取视频第一帧图片,建议自己设置，获取视频中帧非常耗时
@property (nonatomic,strong) UIImage *videoImage;

/** 从xx秒开始播放视频*/
@property (nonatomic,assign) NSInteger seekTime;

/** 是否自动播放*/
@property (nonatomic,assign) BOOL isAutoPlay;

// TODO 后面会增加清晰度选择等


+ (instancetype)SR_playerItemWithVideoURL:(NSURL *)videoURL videoTitle:(NSString *)videoTitle;
@end
