//
//  WYVidoePlayerView.m
//  paper
//
//  Created by wangyang on 14-4-2.
//  Copyright (c) 2014年 com.wy. All rights reserved.
//

#import "WYVideoPlayerView.h"
#import "AFNetworkReachabilityManager.h"
#import <CommonCrypto/CommonDigest.h>


@interface WYVideoPlayerView () <UIAlertViewDelegate>
{
    NSURL *videoURL;
    
    AVPlayerItem *playerItem;
    AVURLAsset *asset;
    
    CGPoint playerOriginalCenter;
    CGRect playerOriginalBounds;
    
    
    void (^playerItemStatusChangeBlock)(AVPlayerItemStatus status, WYVideoPlayerView *playerView);
    void(^currentTimeUpdateBlock)(int64_t currentTime, WYVideoPlayerView *playerView);
    void(^orientationWillChangeBlock)(float animationDuration, UIInterfaceOrientation orientationWillChangeTo, float angle, WYVideoPlayerView *playerView);
    void(^loadedTimeUpdateBlock)(int64_t loadTime, WYVideoPlayerView *playerView);
    void (^needShowActivityIndicatorViewBlock)(BOOL shouldShow, WYVideoPlayerView *playerView);
    
    id periodicTimeObserver;
    
//    BOOL subViewHide;
    AFNetworkReachabilityManager *networkReachabilityManager;
    
    
    BOOL isBuffering;
}

@property (nonatomic, strong) AVQueuePlayer *queuePlayer;
@end

// Define this constant for the key-value observation context.
static const NSString *ItemStatusContext;
static const NSString *ItemLoadedTimeContext;
static const NSString *ItemDurationContext;
static const NSString *PlayerViewFrameContext;
static const NSString *ReadyForDisplayContext;
static const NSString *ItemPlaybackLikelyToKeepUpContext;
static const NSString *ItemPlaybackBufferEmptyContext;
@implementation WYVideoPlayerView

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

- (void)ApplicationWillResignActive
{
    [[self player] pause];
}

- (void)ApplicationDidBecomeActive
{
    if (!_isPauseByUser) {
        [self play];
    }
}

- (void)doInit
{
    self.backgroundColor = [UIColor blackColor];
    
    [self addObserver:self forKeyPath:@"frame" options:NSKeyValueObservingOptionNew context:&PlayerViewFrameContext];
    playerOriginalBounds = self.bounds;
    playerOriginalCenter = self.center;
    
    // 监听设备旋转。如果旋转被用户锁定，系统就不再会发该通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationDidChange:) name:UIDeviceOrientationDidChangeNotification object:nil];
    
    // 监听应用程序ResignActive通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(ApplicationWillResignActive) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(ApplicationDidBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
    
    // 监听网络状态
    networkReachabilityManager = [AFNetworkReachabilityManager managerForDomain:@"www.baidu.com"];
    
    _useLastPlayedTime = YES;
}


+ (Class)layerClass {
    return [AVPlayerLayer class];
}

- (AVQueuePlayer*)player {
    return (AVQueuePlayer*)[(AVPlayerLayer *)[self layer] player];
}

- (void)setPlayer:(AVQueuePlayer *)__player {
    [(AVPlayerLayer *)[self layer] setPlayer:__player];
    
}
#pragma mark - 视频载入
- (void)showLoadingView
{
    if (_loadingView) {
        [self insertSubview:_loadingView atIndex:1];
    }
}

- (void)loadURL:(NSURL *)url
{
    videoURL = url;
    
    [networkReachabilityManager startMonitoring];
    
    // 变为3G网络时，给个暂停，但是其实还是在继续加载的，这个控制不了。提示用户选择继续播放，或者停止，停止了，那就真停止了，显示loadingView
    __weak WYVideoPlayerView *weakSelf = self;
    [networkReachabilityManager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        if (status == AFNetworkReachabilityStatusReachableViaWWAN) {
            // TODO: 变为手机蜂窝网络，停止加载
            //            playerItem = nil;
        }else if  ( status == AFNetworkReachabilityStatusReachableViaWiFi ){
            // TODO: 从 last time 处开始播放
            dispatch_async(dispatch_get_main_queue(), ^{
                AVPlayer *weakPlayer = [weakSelf valueForKey:@"player"];
                if (!weakPlayer) {
                    [weakSelf loadAssetWithURL:[weakSelf valueForKey:@"videoURL"]];
                }else{
                    [weakPlayer play];
                }
            });
            
        }else{
            NSLog(@"AFNetworkReachabilityStatusReachable failed");
            
        }
    }];
}

- (void)loadAssetWithURL:(NSURL *)url{

    [self showLoadingView];
    if (needShowActivityIndicatorViewBlock) {
        needShowActivityIndicatorViewBlock(YES, self);
    }
    asset = [AVURLAsset URLAssetWithURL:url options:nil];
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
                                [playerItem addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:NSKeyValueObservingOptionNew context:&ItemPlaybackLikelyToKeepUpContext];
                                [playerItem addObserver:self forKeyPath:@"playbackBufferEmpty" options:NSKeyValueObservingOptionNew context:&ItemPlaybackBufferEmptyContext];
                                
                                if (_useLastPlayedTime) {
                                    [playerItem seekToTime:CMTimeMakeWithSeconds(self.lastPlayedTime, 1)];
                                }
                                
                                // 播放结束时的通知
                                
                                [[NSNotificationCenter defaultCenter] addObserver:self
                                                                         selector:@selector(playerItemDidReachEnd:)
                                                                             name:AVPlayerItemDidPlayToEndTimeNotification
                                                                           object:playerItem];
                                [self setPlayer:[AVQueuePlayer queuePlayerWithItems:@[playerItem]]];
//                                [self setPlayer:player];
                                [self.layer addObserver:self forKeyPath:@"readyForDisplay" options:NSKeyValueObservingOptionNew context:&ReadyForDisplayContext];
                                
                                
                                // 每0.1秒更新一次
                                periodicTimeObserver = [[self player] addPeriodicTimeObserverForInterval:CMTimeMake(1, 50) queue:NULL usingBlock:^(CMTime time) {
                                    _currentTime = time.value / time.timescale;
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
                if (needShowActivityIndicatorViewBlock){
                    needShowActivityIndicatorViewBlock(NO, self);
                }
                [UIView animateWithDuration:0.2 animations:^{
                    _loadingView.transform = CGAffineTransformMakeScale(3, 3);
                    _loadingView.alpha = 0;
                } completion:^(BOOL finished) {
                    if (_loadingView) {
                        [_loadingView removeFromSuperview];
                    }
                    
                }];
                
                if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive){
                    [self play];
                }
                
            }
        });
        
        return;
    }else if (context == &ItemLoadedTimeContext){
        dispatch_async(dispatch_get_main_queue(), ^{
            NSArray *loadedTimeRanges = [[[self player] currentItem] loadedTimeRanges];
            
            CMTimeRange timeRange = [[loadedTimeRanges objectAtIndex:0] CMTimeRangeValue];
            float startSeconds = CMTimeGetSeconds(timeRange.start);
            float durationSeconds = CMTimeGetSeconds(timeRange.duration);
            NSTimeInterval result = startSeconds + durationSeconds;
            NSLog(@"已载入 %f", result);
            if (loadedTimeUpdateBlock) {
                loadedTimeUpdateBlock(result, self);
            }

        });
        return;
    }else if (context == &ItemDurationContext){
        dispatch_async(dispatch_get_main_queue(), ^{
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
    }else if (context == &ItemPlaybackBufferEmptyContext){
        NSLog(@"ItemPlaybackBufferEmptyContext %@", playerItem.playbackBufferEmpty ? @"YES":@"NO");
        if( playerItem.playbackBufferEmpty ){
            isBuffering = YES;
            dispatch_async(dispatch_get_main_queue(), ^{
                if (needShowActivityIndicatorViewBlock){
                    needShowActivityIndicatorViewBlock(YES, self);
                }
            });
        }
        return;
    }else if (context == &ItemPlaybackLikelyToKeepUpContext){
        NSLog(@"ItemPlaybackLikelyToKeepUpContext %@", playerItem.playbackLikelyToKeepUp ? @"YES":@"NO");
        if(playerItem.playbackLikelyToKeepUp){
            dispatch_async(dispatch_get_main_queue(), ^{
                // TODO: ItemPlaybackLikelyToKeepUpContext这个observer的执行事件有问题

                if (isBuffering) {
                    isBuffering = NO;
                    [[self player] play];
                }
                if (needShowActivityIndicatorViewBlock){
                    needShowActivityIndicatorViewBlock(NO, self);
                }
            });
        }
        return;
    }
    
    [super observeValueForKeyPath:keyPath ofObject:object
                           change:change context:context];
    return;
}

#pragma mark - 控制
- (float)rate{
    return [self player].rate;
}
- (void)setRate:(float)rate
{
    [self player].rate = rate;
}

- (void)play
{
    if (!playerItem){
        [self loadAssetWithURL:videoURL];
    }else{
        // if seeking and isPauseByUser, then return
        [[self player] play];
        _isPauseByUser = NO;
    }
    
    
}
- (void)pause
{
    [[self player] pause];
    _isPauseByUser = YES;
    // 记录播放位置
    [self saveLastPlayTime];
}

- (void)stop
{
    
    [networkReachabilityManager stopMonitoring];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
    [self pause];
    
    [asset cancelLoading];
    asset = nil;
    // 如果asset没有成功载入，这个监听肯定都没有注册，也就不需要remove，强制remove会导致程序崩溃
    if (playerItem){
        [[self player] removeTimeObserver:periodicTimeObserver];
        [playerItem removeObserver:self forKeyPath:@"status" context:&ItemStatusContext];
        [playerItem removeObserver:self forKeyPath:@"loadedTimeRanges" context:&ItemLoadedTimeContext];
        [playerItem removeObserver:self forKeyPath:@"duration" context:&ItemDurationContext];
        [playerItem removeObserver:self forKeyPath:@"playbackBufferEmpty" context:&ItemPlaybackBufferEmptyContext];
        [playerItem removeObserver:self forKeyPath:@"playbackLikelyToKeepUp" context:&ItemPlaybackLikelyToKeepUpContext];
        [self.layer removeObserver:self forKeyPath:@"readyForDisplay" context:&ReadyForDisplayContext];
    }
    
    [self removeObserver:self forKeyPath:@"frame" context:&PlayerViewFrameContext];

    playerItem = nil;
    [[self player] removeAllItems];
    [self setPlayer:nil];
}


- (void)playerItemDidReachEnd:(NSNotification *)notification {
    [[self player] seekToTime:kCMTimeZero];
    [[self player] pause];
}

- (void)setCurrentTime:(int64_t)currentTime
{
    [[self player] pause];
    CMTime time = CMTimeMake(currentTime, 1);
    [[self player] seekToTime:time];
}

#pragma mark - 全屏、旋转相关
- (void)fullScreen{
    
    // 在还不能播放的情况下，不允许旋转
    if (playerItem.status != AVPlayerItemStatusReadyToPlay) {
        return;
    }
    
    
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

- (void)setPlayerItemStatusChangeBlock:(void (^)(AVPlayerItemStatus status, WYVideoPlayerView *playerView))block
{
    playerItemStatusChangeBlock = block;
}

- (void)setCurrentTimeUpdateBlock:(void(^)(int64_t currentTime, WYVideoPlayerView *playerView))block
{
    currentTimeUpdateBlock = block;
}

- (void)setOrientationWillChangeBlock:(void(^)(float animationDuration, UIInterfaceOrientation orientationWillChangeTo, float angle, WYVideoPlayerView *playerView))block
{
    orientationWillChangeBlock = block;
}

- (void)setLoadedTimeUpdateBlock:(void(^)(int64_t loadTime, WYVideoPlayerView *playerView))block
{
    loadedTimeUpdateBlock = block;
}

- (void)setNeedShowActivityIndicatorViewBlock:(void (^)(BOOL shouldShow, WYVideoPlayerView *playerView))block
{
    needShowActivityIndicatorViewBlock = block;
}


#pragma mark - 记住最后的播放时间
#define CACHE_FILE_NAME         @"videoPlayTimeCache"
- (NSString *)md5:(NSString *)string;
{
    const char *original_str = [string UTF8String];
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5(original_str, (uint32_t)strlen(original_str), result);
    NSMutableString *hash = [NSMutableString string];
    for (int i = 0; i < 16; i++)
        [hash appendFormat:@"%02X", result[i]];
    return [hash uppercaseString];
}

// 这里会特意的把时间做一个调整，感觉这样有助于用户回忆起上次播放到哪儿
- (void)saveLastPlayTime;
{
    NSString *cache = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0];
    NSString *filePath = [cache stringByAppendingPathComponent:CACHE_FILE_NAME];
    NSMutableDictionary *cacheDictionary = [NSMutableDictionary dictionaryWithContentsOfFile:filePath];
    if(!cacheDictionary){
        cacheDictionary = [NSMutableDictionary dictionary];
    }
    NSString *key = [self md5:videoURL.absoluteString];
    
    if (_currentTime < 10) {
        cacheDictionary[key] = @(0);
    }else{
        cacheDictionary[key] = @(_currentTime - 3);
    }
    
    
    
    [cacheDictionary writeToFile:filePath atomically:YES];
}


- (int64_t)lastPlayedTime{
    NSString *cache = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0];
    NSString *filePath = [cache stringByAppendingPathComponent:CACHE_FILE_NAME];
    NSMutableDictionary *cacheDictionary = [NSMutableDictionary dictionaryWithContentsOfFile:filePath];

    NSString *key = [self md5:videoURL.absoluteString];
    NSNumber *time = cacheDictionary[key];
    return [time longLongValue];
}


@end
