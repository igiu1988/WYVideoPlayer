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
    __weak IBOutlet UIView *topControlView;
    __weak IBOutlet UIButton *backButton;
    __weak IBOutlet UIButton *downloadButton;
    
    UIButton *fullScreenButton;
    
    CGPoint playerOriginalCenter;
    CGRect playerOriginalBounds;
    
    
    // for test
    __weak IBOutlet UILabel *loadingProgressLabel;
    
    UIActivityIndicatorView *activityIndicator;
}
@end
// TODO: 在视频加载时，应该有一个默认图片显示，并且有一个小圈在转

@implementation WYMoviePlayerController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationController.navigationBarHidden = YES;
    self.view.backgroundColor = [UIColor blackColor];
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleLightContent;
    
    [slider setMaximumTrackImage:[UIImage imageNamed:@"缓存条"] forState:UIControlStateNormal];
    [slider setMinimumTrackImage:[UIImage imageNamed:@"播放进度条"] forState:UIControlStateNormal];
    [slider setThumbImage:[UIImage imageNamed:@"播放拖动钮"] forState:UIControlStateNormal];
    
    // 对于 ios6 要使用 wantsFullScreenLayout, 这样subview的layout就与ios7一样了
    if ([UIDevice currentDevice].systemVersion.floatValue < 7 ) {
        self.wantsFullScreenLayout = YES;
    }
    
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
    
    [UIActivityIndicatorView appearance].color = [UIColor redColor];
    activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    activityIndicator.center = self.playerView.center;
    [self.playerView addSubview:activityIndicator];
    
    UIImageView *loadingView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.playerView.width, self.playerView.height)];
    loadingView.image = [UIImage imageNamed:@"loadingImage"];
    self.playerView.loadingView = loadingView;
    self.playerView.backgroundColor = [UIColor blackColor];
    
    [self.playerView setPlayerItemStatusChangeBlock:^(AVPlayerItemStatus status, WYVidoePlayerView *playerView) {
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
    
    [self.playerView setCurrentTimeUpdateBlock:^(int64_t currentTime, WYVidoePlayerView *playerView) {
        slider.value = currentTime;
        currentTimeLabel.text = [NSString stringWithFormat:@"已播放%lld/%lld", currentTime, playerView.duration];
    }];
    
    
    [self.playerView setOrientationWillChangeBlock:^(float animationDuration, UIInterfaceOrientation orientationWillChangeTo, float angel, WYVidoePlayerView *playerView) {
        
        if (UIInterfaceOrientationIsLandscape(orientationWillChangeTo)) {
            
            [UIView animateWithDuration:animationDuration animations:^{
                if (topControlView.top == 0) {
                    topControlView.centerY += 20;
                }
                loadingProgressLabel.transform = CGAffineTransformRotate(loadingProgressLabel.transform, angel);
            }];
            
            
            // 全屏播放时，状态栏要设置成半透明的
            if ([UIDevice currentDevice].systemVersion.floatValue < 7) {
                [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackTranslucent];
            }else{
                [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
            }
            
        }else{
            [UIView animateWithDuration:animationDuration animations:^{
                topControlView.centerY -= 20;
                loadingProgressLabel.transform = CGAffineTransformIdentity;
            }];
            
            
            [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
        }
    }];
    
    [self.playerView setLoadedTimeUpdateBlock:^(int64_t loadTime, WYVidoePlayerView *playerView) {
        loadingProgressLabel.text = [NSString stringWithFormat:@"已加载%lld / %lld", loadTime, playerView.duration];
    }];
    
    [self.playerView setNeedShowActivityIndicatorViewBlock:^(BOOL shouldShow, WYVidoePlayerView *playerView) {
        if (shouldShow){
            [activityIndicator startAnimating];
        }else{
            [activityIndicator stopAnimating];
        }
    }];
    
    playerOriginalBounds = _playerView.bounds;
    playerOriginalCenter = _playerView.center;
    
    
    UITapGestureRecognizer *hideSubviewGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideSubviewGestureAction:)];
    hideSubviewGesture.numberOfTapsRequired = 1;
    
    [_playerView addGestureRecognizer:hideSubviewGesture];
    UITapGestureRecognizer *fullScreentGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(fullScreenAction:)];
    fullScreentGesture.numberOfTapsRequired = 2;
    [hideSubviewGesture requireGestureRecognizerToFail:fullScreentGesture];
    [_playerView addGestureRecognizer:fullScreentGesture];
    
    //    NSString *path = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/IMG_0313.MOV"];
    //    NSURL *url = [NSURL fileURLWithPath:path];
    // http://v.yingshibao.chuanke.com/CET4_video/4001_zongshu_I.mp4
    // http://devimages.apple.com/iphone/samples/bipbop/bipbopall.m3u8
    NSURL *url = [NSURL URLWithString:@"http://v.yingshibao.chuanke.com/CET4_video/4001_zongshu_I.mp4"];
    [_playerView loadURL:url];
}

- (void)viewWillDisappear:(BOOL)animated{
    
    [super viewWillDisappear:animated];
    [_playerView pause];
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
        [_playerView pause];
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