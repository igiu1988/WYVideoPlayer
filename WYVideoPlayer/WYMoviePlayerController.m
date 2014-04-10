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
    __weak IBOutlet UIButton *playButton;
    __weak IBOutlet UISlider *slider;
    __weak IBOutlet UILabel *currentTimeLabel;
    
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
    
    [slider setMaximumTrackImage:[UIImage imageNamed:@"播放进度条"] forState:UIControlStateNormal];
    [slider setMinimumTrackImage:[UIImage imageNamed:@"缓存条"] forState:UIControlStateNormal];
    [slider setThumbImage:[UIImage imageNamed:@"播放拖动钮"] forState:UIControlStateNormal];
    
    [self.playerView setPlayerItemStatusChangeBlock:^(AVPlayerItemStatus status, WYVidoePlayerView *playerView) {
        if (status == AVPlayerItemStatusReadyToPlay) {
            slider.maximumValue = playerView.duration;
            playButton.enabled = YES;
        }else{
            playButton.enabled = NO;
        }
    }];
    
    [self.playerView setCurrentTimeUpdateBlock:^(int64_t currentTime, WYVidoePlayerView *playerView) {
        slider.value = currentTime;
        currentTimeLabel.text = [NSString stringWithFormat:@"%lld/%lld", currentTime, playerView.duration];
    }];

    
    [self.playerView setOrientationWillChangeBlock:^(float animationDuration, WYVidoePlayerView *playerView) {
        if (UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
            
            [UIView animateWithDuration:animationDuration animations:^{
                
            }];
        }else{
            [UIView animateWithDuration:animationDuration animations:^{
            
            }];
        }
    }];
    
    playerOriginalBounds = _playerView.bounds;
    playerOriginalCenter = _playerView.center;
    
}


#pragma mark - 控制
- (IBAction)fullScreenAction:(id)sender {
    [_playerView fullScreen];
}

- (IBAction)play:sender
{
    if (_playerView.rate == 0) {
        [_playerView play];
    }else{
        [_playerView pause];
    }
}
- (IBAction)popAction:(id)sender {
    
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - 旋转
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
@end


// 反正状态栏能不能旋转，要看这个viewcontroller在不在UINavigationController。如果在，那么就要像下面这样，如何不在，直接旋转状态栏就可以
@implementation UINavigationController (Rotation)
- (BOOL)shouldAutorotate
{
    return [[self.viewControllers lastObject] shouldAutorotate];
}


- (NSUInteger)supportedInterfaceOrientations
{
    return [[self.viewControllers lastObject] supportedInterfaceOrientations];
}


- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return [[self.viewControllers lastObject] preferredInterfaceOrientationForPresentation];
}
@end