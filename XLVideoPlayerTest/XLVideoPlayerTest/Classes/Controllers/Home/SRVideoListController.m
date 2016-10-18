//
//  SRVideoListController.m
//  XLVideoPlayerTest
//
//  Created by xl on 16/10/8.
//  Copyright © 2016年 xl. All rights reserved.
//

#import "SRVideoListController.h"
#import "SRVideoPlayerController.h"

@interface SRVideoListController ()

@property (weak, nonatomic) IBOutlet UITableView *videoListTable;
@property (nonatomic, strong) NSArray *dataSource;

@end

@implementation SRVideoListController


- (void)viewDidLoad {
    [super viewDidLoad];
    [[UIApplication sharedApplication]setStatusBarStyle:UIStatusBarStyleLightContent];
    self.automaticallyAdjustsScrollViewInsets = NO;
    NSURL *LocalUrl= [[NSBundle mainBundle]URLForResource:@"SampleVideo_640x360_1mb" withExtension:@"mp4"];
    
    self.dataSource = @[LocalUrl,
                        @"http://baobab.wdjcdn.com/1455888619273255747085_x264.mp4",
                        @"http://baobab.wdjcdn.com/1455968234865481297704.mp4",
                        @"http://www.itinge.com/music/16064.mp4",
                        @"http://www.itinge.com/music/16065.mp4",
                        @"http://www.itinge.com/music/16066.mp4",
                        @"http://www.itinge.com/music/16362.mp4",
                        @"http://www.itinge.com/music/16359.mp4",
                        @"http://baobab.wdjcdn.com/1455782903700jy.mp4",
                        @"http://baobab.wdjcdn.com/14564977406580.mp4",
                        @"http://baobab.wdjcdn.com/1456316686552The.mp4",
                        @"http://baobab.wdjcdn.com/1456480115661mtl.mp4",
                        @"http://baobab.wdjcdn.com/1456665467509qingshu.mp4",
                        @"http://baobab.wdjcdn.com/1455614108256t(2).mp4",
                        @"http://baobab.wdjcdn.com/1456317490140jiyiyuetai_x264.mp4",
                        @"http://baobab.wdjcdn.com/1456734464766B(13).mp4",
                        @"http://baobab.wdjcdn.com/1456653443902B.mp4",
                        @"http://baobab.wdjcdn.com/1456231710844S(24).mp4"];


}

#pragma mark -UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.dataSource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"srvideoListCell"];
    if (indexPath.row == 0) {
        cell.textLabel.text = @"本地视频";
    } else {
        cell.textLabel.text   = [NSString stringWithFormat:@"网络视频%zd",indexPath.row];
    }
    
    return cell;
}



#pragma mark - Navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    SRVideoPlayerController *movie = (SRVideoPlayerController *)[segue destinationViewController];
    UITableViewCell * cell = (UITableViewCell *)sender;
    NSIndexPath * indexPath = [self.videoListTable indexPathForCell:cell];
    [self.videoListTable deselectRowAtIndexPath:indexPath animated:YES];
    if ([self.dataSource[indexPath.row] isKindOfClass:[NSURL class]]) {
        movie.videoURL = self.dataSource[indexPath.row];
    } else {
        // 处理中文url
//        NSString *encodedString = (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,(CFStringRef)self.dataSource[indexPath.row],(CFStringRef)@"!$&'()*+,-./:;=?@_~%#[]",NULL,kCFStringEncodingUTF8));
//        NSURL * URL = [NSURL URLWithString:encodedString];
        
        NSURL * URL = [NSURL URLWithString:self.dataSource[indexPath.row]];
        movie.videoURL = URL;
    }
    
}


@end
