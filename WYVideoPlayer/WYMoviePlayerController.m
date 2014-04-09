//
//  WYMoviePlayerController.m
//  paper
//
//  Created by wangyang on 14-4-1.
//  Copyright (c) 2014年 com.zkyj. All rights reserved.
//

#import "WYMoviePlayerController.h"
#import "WYVidoePlayerView.h"



@interface WYMoviePlayerController () <UIGestureRecognizerDelegate>
{
    UIView *controlBar;
//    UIButton *playButton;
    __weak IBOutlet UISlider *slider;
    
    UIButton *fullScreenButton;
    
    CGPoint playerOriginalCenter;
    CGRect playerOriginalBounds;
}
@end
// TODO: 在视频加载时，应该有一个默认图片显示，并且有一个小圈在转
@implementation WYMoviePlayerController


- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationController.navigationBarHidden = YES;
    
    [self.playerView setPlayerItemStatusChangeBlock:^(AVPlayerItemStatus status, WYVidoePlayerView *playerView) {
        if (status == AVPlayerItemStatusReadyToPlay) {
            slider.maximumValue = playerView.duration;
            self.playButton.enabled = YES;
        }else{
            self.playButton.enabled = NO;
        }
    }];
    
    [self.playerView setCurrentTimeUpdateBlock:^(float currentTime, WYVidoePlayerView *playerView) {
        slider.value = currentTime;
    }];

//    [self.playerView setOrientationWillChangeBlock:^(float animationDuration, WYVidoePlayerView *playerView) {
//        if (UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
//            
//            [UIView animateWithDuration:animationDuration animations:^{
//                slider.center = CGPointMake(slider.width/2, 0);
//                float deviceHeight = [[UIScreen mainScreen] bounds].size.height;
//                slider.bounds = CGRectMake(0, 0, deviceHeight, slider.height);
//                slider.transform = CGAffineTransformMakeRotation(M_PI_2);
//            }];
//        }else{
//            [UIView animateWithDuration:animationDuration animations:^{
//                slider.center = CGPointMake(slider.width/2, 0);
//                float deviceHeight = [[UIScreen mainScreen] bounds].size.height;
//                slider.bounds = CGRectMake(0, 0, deviceHeight, slider.height);
//                slider.transform = CGAffineTransformMakeRotation(M_PI_2);
//            }];
//        }
//    }];
    
    playerOriginalBounds = _playerView.bounds;
    playerOriginalCenter = _playerView.center;
    
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
    [_playerView fullScreen];
}

- (IBAction)play:sender
{
//    if (self.player.rate == 0) {
//        [self.player play];
//    }else{
//        [self.player pause];
//    }
    if (_playerView.rate == 0) {
        [_playerView play];
    }else{
        [_playerView pause];
    }
}

@end
