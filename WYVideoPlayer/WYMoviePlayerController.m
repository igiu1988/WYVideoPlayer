//
//  WYMoviePlayerController.m
//  paper
//
//  Created by wangyang on 14-4-1.
//  Copyright (c) 2014年 com.zkyj. All rights reserved.
//

#import "WYMoviePlayerController.h"
#import "WYVidoePlayerView.h"

// Define this constant for the key-value observation context.
static const NSString *ItemStatusContext;

@interface WYMoviePlayerController () <UIGestureRecognizerDelegate>
{
    UIView *controlBar;
//    UIButton *playButton;
    UISlider *slideBar;
    UIButton *fullScreenButton;
    
}
@end
// TODO: 在视频加载时，应该有一个默认图片显示，并且有一个小圈在转
@implementation WYMoviePlayerController

- (void)loadAssetFromFile{
    
    NSURL *url = [NSURL URLWithString:@"http://v.yingshibao.chuanke.com/cet4/CET4_listening_video/1_Zongshu/001_zongshu.mp4"];
    
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:url options:nil];
    NSString *tracksKey = @"tracks";
    
    [asset loadValuesAsynchronouslyForKeys:@[tracksKey] completionHandler:
     ^{
         // Completion handler block.
         dispatch_async(dispatch_get_main_queue(),
                        ^{
                            NSError *error;
                            AVKeyValueStatus status = [asset statusOfValueForKey:tracksKey error:&error];
                            
                            if (status == AVKeyValueStatusLoaded) {
                                self.playerItem = [AVPlayerItem playerItemWithAsset:asset];
                                // ensure that this is done before the playerItem is associated with the player
                                [self.playerItem addObserver:self forKeyPath:@"status"
                                                     options:NSKeyValueObservingOptionInitial context:&ItemStatusContext];
                                [[NSNotificationCenter defaultCenter] addObserver:self
                                                                         selector:@selector(playerItemDidReachEnd:)
                                                                             name:AVPlayerItemDidPlayToEndTimeNotification
                                                                           object:self.playerItem];
                                self.player = [AVPlayer playerWithPlayerItem:self.playerItem];
                                [self.playerView setPlayer:self.player];
                            }
                            else {
                                // You should deal with the error appropriately.
                                NSLog(@"The asset's tracks were not loaded:\n%@", [error localizedDescription]);
                            }
                        });

     }];
}

- (IBAction)play:sender
{
    if (self.player.rate == 0) {
        [self.player play];
    }else{
        [self.player pause];
    }
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self loadAssetFromFile];
    [self syncUI];
    
}

- (void)syncUI {
    if ((self.player.currentItem != nil) &&
        ([self.player.currentItem status] == AVPlayerItemStatusReadyToPlay)) {
        self.playButton.enabled = YES;
    }
    else {
        self.playButton.enabled = NO;
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                        change:(NSDictionary *)change context:(void *)context {
    
    if (context == &ItemStatusContext) {
        dispatch_async(dispatch_get_main_queue(),
                       ^{
                           [self syncUI];
                       });
        return;
    }
    [super observeValueForKeyPath:keyPath ofObject:object
                           change:change context:context];
    return;
}

- (void)playerItemDidReachEnd:(NSNotification *)notification {
    [self.player seekToTime:kCMTimeZero];
}

#pragma mark - 旋转、全屏控制


/*
 TODO:
 1. 搜狐视频只是把单独一个player横了过来。(这个我已经做到)
 2. 设备的自动旋转锁打开，在视频全屏播放时，播放器可以自动左横屏与右横屏，但不能Potrait模式。我猜这个地方没有用controller 的自动旋转做的，而是使用陀螺仪检测*/

/*经验，不使用系统管理旋转，全部不勾选。*/
// 因为在播放器界面我们要使用setStatusBarOrientation:animated方法，而这个方法有效的前提就是shouldAutorotate必须返回NO
- (BOOL)shouldAutorotate
{
    return NO;
}

- (IBAction)fullScreenAction:(id)sender {
    
    // 旋转 status bar
    // 旋转 palyer 并正确设置 player size
    if (UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
        [[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationPortrait animated:YES];
        [UIView animateWithDuration:[UIApplication sharedApplication].statusBarOrientationAnimationDuration animations:^{
            _playerView.transform = CGAffineTransformIdentity;
        }];

    }else{
        // setStatusBarOrientation 在文档里有说明，如果由设备来管理旋转，该方法不好使（not working）。所以shouldAutorotate应该返回NO，意思完全交由我们自己管理，同时要注意到shouldAutorotate是在ios6以后有的方法
        
        [[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationLandscapeRight animated:YES];
        [UIView animateWithDuration:[UIApplication sharedApplication].statusBarOrientationAnimationDuration animations:^{
            
            CGAffineTransform transform = CGAffineTransformMakeRotation(M_PI_2);
            
            float deviceHeight = [[UIScreen mainScreen] bounds].size.height;
            float devicewidth = [[UIScreen mainScreen] bounds].size.width;
            float heightScale = devicewidth / _playerView.height;
            float widthScale = deviceHeight / _playerView.width;
            
            transform = CGAffineTransformScale(transform, widthScale, heightScale);
            // TODO: 如果player view的坐标是 (30, 40)，那么在全屏后，player view必须做一个Translate，下面这个translate不对，需要修改
            transform = CGAffineTransformTranslate(transform, -_playerView.left, -_playerView.top);
            _playerView.transform = transform;

        } completion:^(BOOL finished) {
            
        }];

    }

    
}

@end
