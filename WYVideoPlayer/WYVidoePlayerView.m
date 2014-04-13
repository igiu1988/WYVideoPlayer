//
//  WYVidoePlayerView.m
//  paper
//
//  Created by wangyang on 14-4-2.
//  Copyright (c) 2014年 com.wy. All rights reserved.
//

#import "WYVidoePlayerView.h"
@interface WYVidoePlayerView ()
{
    AVPlayer *player;
    AVPlayerItem *playerItem;
    
    CGPoint playerOriginalCenter;
    CGRect playerOriginalBounds;
    
    
    void (^playerItemStatusChangeBlock)(AVPlayerItemStatus status, WYVidoePlayerView *playerView);
    void(^currentTimeUpdateBlock)(int64_t currentTime, WYVidoePlayerView *playerView);
    void(^orientationWillChangeBlock)(float animationDuration, UIInterfaceOrientation orientationWillChangeTo, float angle, WYVidoePlayerView *playerView);
    void(^loadedTimeUpdateBlock)(int64_t loadTime, WYVidoePlayerView *playerView);
    id periodicTimeObserver;
    
//    BOOL subViewHide;
}


@end

// Define this constant for the key-value observation context.
static const NSString *ItemStatusContext;
static const NSString *ItemLoadedTimeContext;
static const NSString *ItemDurationContext;
static const NSString *PlayerViewFrameContext;
static const NSString *ReadyForDisplayContext;
@implementation WYVidoePlayerView

#pragma mark - 初始化
- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self doInit];
    }
    
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self doInit];
    }
    return self;
}

- (void)doInit
{
    [self addObserver:self forKeyPath:@"frame" options:NSKeyValueObservingOptionNew context:&PlayerViewFrameContext];
    playerOriginalBounds = self.bounds;
    playerOriginalCenter = self.center;
    
//    [self loadAssetFromFile];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationDidChange:) name:UIDeviceOrientationDidChangeNotification object:nil];
}

+ (Class)layerClass {
    return [AVPlayerLayer class];
}

- (AVPlayer*)player {
    return [(AVPlayerLayer *)[self layer] player];
}

- (void)setPlayer:(AVPlayer *)__player {
    [(AVPlayerLayer *)[self layer] setPlayer:__player];
    
}
#pragma mark - 视频载入
- (void)showLoadingView
{
    if (_loadingView) {
        [self addSubview:_loadingView];
    }
}

- (void)loadURL:(NSURL *)url
{
    [self loadAssetWithURL:url];
}
- (void)loadAssetWithURL:(NSURL *)url{
 
    
    [self showLoadingView];
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
                                
                                playerItem = [AVPlayerItem playerItemWithAsset:asset];
                                // ensure that this is done before the playerItem is associated with the player
                                [playerItem addObserver:self forKeyPath:@"status"
                                                options:NSKeyValueObservingOptionInitial context:&ItemStatusContext];
                                [playerItem addObserver:self forKeyPath:@"loadedTimeRanges"
                                                options:NSKeyValueObservingOptionNew context:&ItemLoadedTimeContext];
                                [playerItem addObserver:self forKeyPath:@"duration"
                                                options:NSKeyValueObservingOptionNew context:&ItemDurationContext];
                                
                                // 播放结束时的通知
                                
                                [[NSNotificationCenter defaultCenter] addObserver:self
                                                                         selector:@selector(playerItemDidReachEnd:)
                                                                             name:AVPlayerItemDidPlayToEndTimeNotification
                                                                           object:playerItem];
                                player = [AVPlayer playerWithPlayerItem:playerItem];
                                [self setPlayer:player];
                                [self.layer addObserver:self forKeyPath:@"readyForDisplay" options:NSKeyValueObservingOptionNew context:&ReadyForDisplayContext];
                                
                                
                                // 每0.1秒更新一次
                                periodicTimeObserver = [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1, 50) queue:NULL usingBlock:^(CMTime time) {
                                    if (currentTimeUpdateBlock) {
                                        currentTimeUpdateBlock((time.value)/time.timescale, self);
                                    }
                                }];
                                
                            }
                            else {
                                // You should deal with the error appropriately.
                                NSLog(@"The asset's tracks were not loaded:\n%@", [error localizedDescription]);
                            }
                        });
         
     }];
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                        change:(NSDictionary *)change context:(void *)context {
    
    
    if (context == &ItemStatusContext) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (playerItemStatusChangeBlock) {
                playerItemStatusChangeBlock(playerItem.status, self);
            }
            if (playerItem.status == AVPlayerItemStatusReadyToPlay) {
                if (_loadingView) {
                    [_loadingView removeFromSuperview];
                }
            }
        });
        
        return;
    }else if (context == &ItemLoadedTimeContext){
        dispatch_async(dispatch_get_main_queue(), ^{
            NSArray *loadedTimeRanges = [[self.player currentItem] loadedTimeRanges];
            
            CMTimeRange timeRange = [[loadedTimeRanges objectAtIndex:0] CMTimeRangeValue];
            float startSeconds = CMTimeGetSeconds(timeRange.start);
            float durationSeconds = CMTimeGetSeconds(timeRange.duration);
            NSTimeInterval result = startSeconds + durationSeconds;
            if (loadedTimeUpdateBlock) {
                loadedTimeUpdateBlock(result, self);
            }

        });
        return;
    }else if (context == &ItemDurationContext){
        dispatch_async(dispatch_get_main_queue(), ^{
            //            NSLog(@"presentationSize %@", NSStringFromCGSize([[self.player currentItem] presentationSize]));
            _duration = playerItem.duration.value/playerItem.duration.timescale;
            if (currentTimeUpdateBlock) {
                currentTimeUpdateBlock(0, self);
            }
            
        });
        return;
    }else if (context == &PlayerViewFrameContext){
        playerOriginalBounds = self.bounds;
        playerOriginalCenter = self.center;
        
        return;
    }else if (context == &ReadyForDisplayContext){
        
        return;
    }
    
    [super observeValueForKeyPath:keyPath ofObject:object
                           change:change context:context];
    return;
}

#pragma mark - 控制
- (float)rate{
    return player.rate;
}
- (void)setRate:(float)rate
{
    player.rate = rate;
}

- (void)play
{
    [player play];
}
- (void)pause
{
    [player pause];
}

- (void)stop
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
    [player pause];
    [player removeTimeObserver:periodicTimeObserver];

    [playerItem removeObserver:self forKeyPath:@"status" context:&ItemStatusContext];
    [playerItem removeObserver:self forKeyPath:@"loadedTimeRanges" context:&ItemLoadedTimeContext];
    [playerItem removeObserver:self forKeyPath:@"duration" context:&ItemDurationContext];
    [self removeObserver:self forKeyPath:@"frame" context:&PlayerViewFrameContext];
    [self.layer removeObserver:self forKeyPath:@"readyForDisplay" context:&ReadyForDisplayContext];
    playerItem = nil;
    
    player = nil;
}

- (void)playerItemDidReachEnd:(NSNotification *)notification {
    [self.player seekToTime:kCMTimeZero];
}

#pragma mark - 全屏、旋转相关
- (void)fullScreen{
    
    // 旋转 status bar
    // 旋转 palyer 并正确设置 player size
    
    if (UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
        if (orientationWillChangeBlock) {
            orientationWillChangeBlock([UIApplication sharedApplication].statusBarOrientationAnimationDuration,  UIInterfaceOrientationPortrait, 0,self);
        }
        [[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationPortrait animated:YES];
        
        [UIView animateWithDuration:[UIApplication sharedApplication].statusBarOrientationAnimationDuration animations:^{
            self.transform = CGAffineTransformIdentity;
            self.center = playerOriginalCenter;
            self.bounds = playerOriginalBounds;
        }];
        
    }else{
        [self changeOrientationTo:UIInterfaceOrientationLandscapeRight rotationAngle:M_PI_2];
    }
    
    
}

- (void)changeOrientationTo:(UIInterfaceOrientation)orientation rotationAngle:(double_t)angle
{
    
    if (orientation == [UIApplication sharedApplication].statusBarOrientation) {
        return;
    }
    
    // 根据statusBarOrientationAnimationDuration的文档描述，就分情况采取不同的时间
    float duration = 0;
    if (angle - M_PI_2 < 0.0001) {
        duration = [UIApplication sharedApplication].statusBarOrientationAnimationDuration;
    }else{
        duration = [UIApplication sharedApplication].statusBarOrientationAnimationDuration * 2;
    }
    
    if (orientationWillChangeBlock) {
        orientationWillChangeBlock(duration, orientation, angle, self);
    }
    
    [UIView animateWithDuration:duration animations:^{
        // setStatusBarOrientation 在文档里有说明，如果由设备来管理旋转，该方法不好使（not working）。所以shouldAutorotate应该返回NO，意思完全交由我们自己管理，同时要注意到shouldAutorotate是在ios6以后有的方法
        [[UIApplication sharedApplication] setStatusBarOrientation:orientation];
        // 将center移动到屏幕的中间
        float deviceHeight = [[UIScreen mainScreen] bounds].size.height;
        float deviceWidth = [[UIScreen mainScreen] bounds].size.width;
        
        self.bounds = CGRectMake(0, 0, deviceHeight, deviceWidth);
        self.center = CGPointMake(deviceWidth/2, deviceHeight/2);
        
        self.transform = CGAffineTransformRotate(self.transform, angle);
        
    }];
}

/**
 *  只有在全屏的情况下才响应左横屏、右横屏操作
 */
- (void)deviceOrientationDidChange:(NSNotification *)notification
{
    if (!CGAffineTransformIsIdentity(self.transform)) {
        UIDeviceOrientation deviceOrientation = [UIDevice currentDevice].orientation;
        if ( deviceOrientation == UIDeviceOrientationLandscapeRight) {
            [self changeOrientationTo:UIInterfaceOrientationLandscapeLeft rotationAngle:M_PI];
        }else if ( deviceOrientation == UIDeviceOrientationLandscapeLeft){
            [self changeOrientationTo:UIInterfaceOrientationLandscapeRight rotationAngle:M_PI];
        }
    }

}


#pragma mark - Block

- (void)setPlayerItemStatusChangeBlock:(void (^)(AVPlayerItemStatus status, WYVidoePlayerView *playerView))block
{
    playerItemStatusChangeBlock = block;
}

- (void)setCurrentTimeUpdateBlock:(void(^)(int64_t currentTime, WYVidoePlayerView *playerView))block
{
    currentTimeUpdateBlock = block;
}

- (void)setOrientationWillChangeBlock:(void(^)(float animationDuration, UIInterfaceOrientation orientationWillChangeTo, float angle, WYVidoePlayerView *playerView))block
{
    orientationWillChangeBlock = block;
}

- (void)setLoadedTimeUpdateBlock:(void(^)(int64_t loadTime, WYVidoePlayerView *playerView))block
{
    loadedTimeUpdateBlock = block;
}


@end
