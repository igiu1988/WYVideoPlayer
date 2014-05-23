//
//  WYMoviePlayerController.m
//  paper
//
//  Created by wangyang on 14-4-1.
//  Copyright (c) 2014年 com.zkyj. All rights reserved.
//

#import "WYMoviePlayerController.h"
#import "WYVideoPlayerView.h"



@interface WYMoviePlayerController () <UIGestureRecognizerDelegate>
{
    UIView *controlBar;
    __weak IBOutlet UIButton *playButton;
    __weak IBOutlet UISlider *slider;
    __weak IBOutlet UILabel *currentTimeLabel;
    __weak IBOutlet UIView *topControlView;
    __weak IBOutlet UIButton *backButton;
    __weak IBOutlet UIButton *downloadButton;
    
    UIButton *fullScreenButton;
    
    
    // for test
    __weak IBOutlet UILabel *loadingProgressLabel;
    
    UIActivityIndicatorView *activityIndicator;
}
@end

@implementation WYMoviePlayerController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    self.navigationController.navigationBarHidden = YES;
    self.view.backgroundColor = [UIColor blackColor];
    
    // 对于 ios6 要使用 wantsFullScreenLayout, 这样subview的layout就与ios7一样了
    if ([UIDevice currentDevice].systemVersion.floatValue < 7) {
        self.wantsFullScreenLayout = YES;
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackTranslucent];
    }else{
        [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleLightContent;
    }
    
    
    
    [slider setMaximumTrackImage:[UIImage imageNamed:@"缓存条"] forState:UIControlStateNormal];
    [slider setMinimumTrackImage:[UIImage imageNamed:@"播放进度条"] forState:UIControlStateNormal];
    [slider setThumbImage:[UIImage imageNamed:@"播放拖动钮"] forState:UIControlStateNormal];
    
    

    
    playButton.enabled = NO;
    slider.enabled = NO;
    fullScreenButton.enabled = NO;
    
    CAGradientLayer *gradientLayer = [[CAGradientLayer alloc] init];
    gradientLayer.colors = [NSArray arrayWithObjects:
                            (id)[[UIColor clearColor] CGColor],
                            (id)[[[UIColor blackColor] colorWithAlphaComponent:0.8] CGColor],
                            nil];
    gradientLayer.startPoint = CGPointMake(0.5,1);
    gradientLayer.endPoint = CGPointMake(0.5,0);
    gradientLayer.frame = topControlView.bounds;
    [topControlView.layer addSublayer: gradientLayer];
    
    [self setupPlayer];
}

- (void)setupPlayer
{
    // 1.设置视频缓冲时显示的activityIndicator
    [UIActivityIndicatorView appearance].color = [UIColor redColor];
    activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    activityIndicator.center = self.playerView.center;
    [self.playerView addSubview:activityIndicator];
    
    // 2.设置视频第一次加载时显示的默认图片
    UIImageView *loadingView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.playerView.width, self.playerView.height)];
    loadingView.image = [UIImage imageNamed:@"loadingImage"];
    self.playerView.loadingView = loadingView;
    
    // 3.设置播放器的背景
    self.playerView.backgroundColor = [UIColor blackColor];
    
    // 4.视频第一次缓冲并可以播放时的回调
    [self.playerView setPlayerItemStatusChangeBlock:^(AVPlayerItemStatus status, WYVideoPlayerView *playerView) {
        if (status == AVPlayerItemStatusReadyToPlay) {
            slider.maximumValue = playerView.duration;
            playButton.enabled = YES;
            slider.enabled = YES;
            fullScreenButton.enabled = YES;
            [playButton setTitle:@"暂停" forState:UIControlStateNormal];
        }else{
            NSLog(@"AVPlayerItemStatus 发生变化");
        }
    }];
    
    // 5.视频播放进度
    [self.playerView setCurrentTimeUpdateBlock:^(int64_t currentTime, WYVideoPlayerView *playerView) {
        slider.value = currentTime;
        currentTimeLabel.text = [NSString stringWithFormat:@"已播放%lld/%lld", currentTime, playerView.duration];
    }];
    
    // 6.播放器旋转时的回调
    [self.playerView setOrientationWillChangeBlock:^(float animationDuration, UIInterfaceOrientation orientationWillChangeTo, float angel, WYVideoPlayerView *playerView) {
        
        if (UIInterfaceOrientationIsLandscape(orientationWillChangeTo)) {
            
            [UIView animateWithDuration:animationDuration animations:^{
                if (topControlView.top == 0) {
                    topControlView.centerY += 20;
                }
                loadingProgressLabel.transform = CGAffineTransformRotate(loadingProgressLabel.transform, angel);
            }];
            
            
            // 全屏播放时，状态栏要设置成半透明的
//            if ([UIDevice currentDevice].systemVersion.floatValue < 7) {
//                [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackTranslucent];
//            }
            
        }else{
            [UIView animateWithDuration:animationDuration animations:^{
                topControlView.centerY -= 20;
                loadingProgressLabel.transform = CGAffineTransformIdentity;
            }];
            
//            if ([UIDevice currentDevice].systemVersion.floatValue < 7) {
//                [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
//            }
            
        }
    }];
    
    // 7.视频已加载时间的变化回调
    [self.playerView setLoadedTimeUpdateBlock:^(int64_t loadTime, WYVideoPlayerView *playerView) {
        loadingProgressLabel.text = [NSString stringWithFormat:@"已加载%lld / %lld", loadTime, playerView.duration];
    }];
    
    // 8.播放器是否需要显示activityIndicator
    [self.playerView setNeedShowActivityIndicatorViewBlock:^(BOOL shouldShow, WYVideoPlayerView *playerView) {
        if (shouldShow){
            [activityIndicator startAnimating];
        }else{
            [activityIndicator stopAnimating];
        }
    }];
    
    
    UITapGestureRecognizer *hideSubviewGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideSubviewGestureAction:)];
    hideSubviewGesture.numberOfTapsRequired = 1;
    hideSubviewGesture.delegate = self;
    
    [_playerView addGestureRecognizer:hideSubviewGesture];
    
    
    UITapGestureRecognizer *fullScreentGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(fullScreenAction:)];
    fullScreentGesture.numberOfTapsRequired = 2;
    [hideSubviewGesture requireGestureRecognizerToFail:fullScreentGesture];
    [_playerView addGestureRecognizer:fullScreentGesture];
    
    //    NSString *path = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/IMG_0313.MOV"];
    //    NSURL *url = [NSURL fileURLWithPath:path];
    // http://v.yingshibao.chuanke.com/CET4_video/4001_zongshu_I.mp4
    // http://devimages.apple.com/iphone/samples/bipbop/bipbopall.m3u8
    NSURL *url = [NSURL URLWithString:@"http://devimages.apple.com/iphone/samples/bipbop/bipbopall.m3u8"];
    [_playerView loadURL:url];
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
//    UIView *view = [gestureRecognizer locationInView:<#(UIView *)#>]
    return YES;
}

- (void)viewWillDisappear:(BOOL)animated{
    
    [super viewWillDisappear:animated];
    [_playerView userPause];
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleDefault;
}



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    NSLog(@"我X，内存爆了");
}

#pragma mark - 控制
- (IBAction)fullScreenAction:(id)sender {
    [_playerView fullScreen];
}


- (IBAction)play:sender
{
    if (_playerView.rate == 0) {
        [_playerView play];
        [playButton setTitle:@"暂停" forState:UIControlStateNormal];
    }else{
        [_playerView userPause];
        [playButton setTitle:@"播放" forState:UIControlStateNormal];
    }
}
- (IBAction)popAction:(id)sender {
    if (UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
        [self fullScreenAction:nil];
    }else{
        [self.playerView stop];
        
        [self.navigationController popViewControllerAnimated:YES];
    }
    
}


- (void)hideSubviewGestureAction:(UITapGestureRecognizer *)tap
{
    
    CGPoint point = [tap locationInView:_playerView];
    if (CGRectContainsPoint(backButton.frame, point)) {
        [self popAction:nil];
        return;
    }
    
    if (UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
        if ([UIApplication sharedApplication].statusBarHidden) {
            [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
            [UIView animateWithDuration:0.15 animations:^{
                slider.alpha = 1;
                topControlView.alpha = 1;
                downloadButton.alpha = 1;
                backButton.alpha = 1;
            }];
        }else{
            [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
            [UIView animateWithDuration:0.15 animations:^{
                slider.alpha = 0;
                topControlView.alpha = 0;
                downloadButton.alpha = 0;
                backButton.alpha = 0;
            }];
        }
        
    }else{
        
        if (_playerView.subviews.count > 0) {
            UIView *view = _playerView.subviews[0];
            if (view.alpha) {
                [UIView animateWithDuration:0.15 animations:^{
                    slider.alpha = 0;
                    topControlView.alpha = 0;
                    downloadButton.alpha = 0;
                    backButton.alpha = 1;
                }];
            }else{
                [UIView animateWithDuration:0.15 animations:^{
                    slider.alpha = 1;
                    topControlView.alpha = 1;
                    downloadButton.alpha = 1;
                    backButton.alpha = 1;
                }];
            }
        }
    }
}

// 滑动块在滑动时要先暂停，然后改变时间，结束时要播放。如果不先暂停，slider会有乱串的现象
- (IBAction)sliderChangeBegin:(id)sender {
//    [_playerView pause];
}

- (IBAction)sliderChange:(UISlider *)sender {
    _playerView.currentTime = sender.value;
}
- (IBAction)sliderChangeFinish:(id)sender {
//    if (!_playerView.isPauseByUser) {
//        [_playerView play];
//    }
    
}

#pragma mark - 旋转
/*经验，不使用系统管理旋转，全部不勾选。*/
// 因为在播放器界面我们要使用setStatusBarOrientation:animated方法，而这个方法有效的前提就是shouldAutorotate必须返回NO
- (BOOL)shouldAutorotate
{
    return NO;
}

#pragma mark - 其它操作
- (IBAction)downloadAction:(id)sender {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"其它操作" message:nil delegate:nil cancelButtonTitle:@"好的" otherButtonTitles:nil];
    [alert show];
}
@end


// 反正状态栏能不能旋转，要看这个viewcontroller在不在UINavigationController。如果在，那么就要像下面这样，如果不在，直接旋转状态栏就可以
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