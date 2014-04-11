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
    void(^orientationWillChangeBlock)(float animationDuration, WYVidoePlayerView *playerView);
    void(^loadedTimeUpdateBlock)(int64_t loadTime, WYVidoePlayerView *playerView);
    id periodicTimeObserver;
    
//    BOOL subViewHide;
}


@end

// Define this constant for the key-value observation context.
static const NSString *ItemStatusContext;
static const NSString *ItemLoadedTimeContext;
static const NSString *ItemDurationContext;
static const NSString *ItemTimedMetadataContext;
static const NSString *PlayerViewFrameContext;
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
    
    [self loadAssetFromFile];
    
    
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
    [player pause];
    [player removeTimeObserver:periodicTimeObserver];

    [playerItem removeObserver:self forKeyPath:@"status" context:&ItemStatusContext];
    [playerItem removeObserver:self forKeyPath:@"loadedTimeRanges" context:&ItemLoadedTimeContext];
    [playerItem removeObserver:self forKeyPath:@"duration" context:&ItemDurationContext];
    [playerItem removeObserver:self forKeyPath:@"timedMetadata" context:&ItemTimedMetadataContext];
    [self removeObserver:self forKeyPath:@"frame" context:&PlayerViewFrameContext];
    playerItem = nil;
    
    player = nil;
}
- (void)fullScreen{
    
    // 旋转 status bar
    // 旋转 palyer 并正确设置 player size
    
    if (UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
        [[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationPortrait animated:YES];
//        if (orientationWillChangeBlock) {
//            orientationWillChangeBlock([UIApplication sharedApplication].statusBarOrientationAnimationDuration, self);
//        }
        [UIView animateWithDuration:[UIApplication sharedApplication].statusBarOrientationAnimationDuration animations:^{
            self.transform = CGAffineTransformIdentity;
            self.center = playerOriginalCenter;
            self.bounds = playerOriginalBounds;
        }];
        
    }else{
        // setStatusBarOrientation 在文档里有说明，如果由设备来管理旋转，该方法不好使（not working）。所以shouldAutorotate应该返回NO，意思完全交由我们自己管理，同时要注意到shouldAutorotate是在ios6以后有的方法
        [[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationLandscapeRight animated:YES];
        if (orientationWillChangeBlock) {
            orientationWillChangeBlock([UIApplication sharedApplication].statusBarOrientationAnimationDuration, self);
        }
        if ([UIDevice currentDevice].systemVersion.floatValue < 7) {
            [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackTranslucent];
        }
        [UIView animateWithDuration:[UIApplication sharedApplication].statusBarOrientationAnimationDuration animations:^{
            
            // 将center移动到屏幕的中间
            float deviceHeight = [[UIScreen mainScreen] bounds].size.height;
            float deviceWidth = [[UIScreen mainScreen] bounds].size.width;
            
            self.bounds = CGRectMake(0, 0, deviceHeight, deviceWidth);
            self.center = CGPointMake(deviceWidth/2, deviceHeight/2);
            
            self.transform = CGAffineTransformMakeRotation(M_PI_2);
            
        }];
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

- (void)setOrientationWillChangeBlock:(void(^)(float animationDuration, WYVidoePlayerView *playerView))block
{
    orientationWillChangeBlock = block;
}

- (void)setLoadedTimeUpdateBlock:(void(^)(int64_t loadTime, WYVidoePlayerView *playerView))block
{
    loadedTimeUpdateBlock = block;
}
#pragma mark - 视频载入
- (void)loadAssetFromFile{
    
    //代码公开时，要使用这个视频地址
    NSURL *url = [NSURL URLWithString:@"http://devimages.apple.com/iphone/samples/bipbop/bipbopall.m3u8"];
    
//    NSString *path = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/IMG_0313.MOV"];
//    NSURL *url = [NSURL fileURLWithPath:path];
    
    
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
                                [playerItem addObserver:self forKeyPath:@"timedMetadata"
                                                options:NSKeyValueObservingOptionNew context:&ItemTimedMetadataContext];
                                
                                // 播放结束时的通知
                                
                                [[NSNotificationCenter defaultCenter] addObserver:self
                                                                         selector:@selector(playerItemDidReachEnd:)
                                                                             name:AVPlayerItemDidPlayToEndTimeNotification
                                                                           object:playerItem];
                                player = [AVPlayer playerWithPlayerItem:playerItem];
                                [self setPlayer:player];
                                
                                
                                
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
            NSLog(@"presentationSize %@", NSStringFromCGSize([[self.player currentItem] presentationSize]));
            _duration = playerItem.duration.value/playerItem.duration.timescale;
            if (currentTimeUpdateBlock) {
                currentTimeUpdateBlock(0, self);
            }
            
        });
        return;
    }else if (context == &ItemTimedMetadataContext){
        dispatch_async(dispatch_get_main_queue(), ^{
            NSArray *timeMetadataArray = playerItem.timedMetadata;
            
        });
        return;
    }else if (context == &PlayerViewFrameContext){
        playerOriginalBounds = self.bounds;
        playerOriginalCenter = self.center;
        
        return;
    }
    
    [super observeValueForKeyPath:keyPath ofObject:object
                           change:change context:context];
    return;
}

- (void)playerItemDidReachEnd:(NSNotification *)notification {
    [self.player seekToTime:kCMTimeZero];
}

@end
