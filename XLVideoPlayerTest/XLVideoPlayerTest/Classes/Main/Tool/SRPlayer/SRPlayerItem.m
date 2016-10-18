//
//  SRPlayerItem.m
//  XLVideoPlayerTest
//
//  Created by xl on 16/10/13.
//  Copyright © 2016年 xl. All rights reserved.
//

#import "SRPlayerItem.h"

@implementation SRPlayerItem

- (instancetype)init {
    if (self = [super init]) {
        // 默认从第0秒开始播放
        _seekTime = 0;
    }
    return self;
}
- (instancetype)initWithVideoURL:(NSURL *)videoURL videoTitle:(NSString *)videoTitle {
    if (self = [super init]) {
        // 默认从第0秒开始播放
        _seekTime = 0;
        _videoURL = videoURL;
        _videoTitle = videoTitle;
    }
    return self;
}
+ (instancetype)SR_playerItemWithVideoURL:(NSURL *)videoURL videoTitle:(NSString *)videoTitle {
    return [[SRPlayerItem alloc]initWithVideoURL:videoURL videoTitle:videoTitle];
}
@end
