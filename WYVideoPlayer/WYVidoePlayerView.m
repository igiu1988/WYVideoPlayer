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
    void(^currentTimeUpdateBlock)(float currentTime, WYVidoePlayerView *playerView);
    void(^orientationWillChangeBlock)(float animationDuration, WYVidoePlayerView *playerView);
    
    id periodicTimeObserver;
}


@end

// Define this constant for the key-value observation context.
static const NSString *ItemStatusContext;

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
- (void)fullScreen{
    
    // 旋转 status bar
    // 旋转 palyer 并正确设置 player size
    if (UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
        [[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationPortrait animated:YES];
        [UIView animateWithDuration:[UIApplication sharedApplication].statusBarOrientationAnimationDuration animations:^{
            self.transform = CGAffineTransformIdentity;
            self.center = playerOriginalCenter;
            self.bounds = playerOriginalBounds;
        }];
        
    }else{
        // setStatusBarOrientation 在文档里有说明，如果由设备来管理旋转，该方法不好使（not working）。所以shouldAutorotate应该返回NO，意思完全交由我们自己管理，同时要注意到shouldAutorotate是在ios6以后有的方法
        [[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationLandscapeRight animated:YES];
        
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

- (void)setPlayerItemStatusChangeBlock:(void (^)(AVPlayerItemStatus status, WYVidoePlayerView *playerView))block
{
    playerItemStatusChangeBlock = block;
}

- (void)setCurrentTimeUpdateBlock:(void(^)(float currentTime, WYVidoePlayerView *playerView))block
{
    currentTimeUpdateBlock = block;
}

- (void)setOrientationWillChangeBlock:(void(^)(float animationDuration, WYVidoePlayerView *playerView))block
{
    orientationWillChangeBlock = block;
}
#pragma mark - 视频载入
- (void)loadAssetFromFile{
    
    //代码公开时，要使用这个视频地址
//    NSURL *url = [NSURL URLWithString:@"http://devimages.apple.com/iphone/samples/bipbop/bipbopall.m3u8"];
    
    NSString *path = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/IMG_0313.MOV"];
    NSURL *url = [NSURL fileURLWithPath:path];
    
    
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
                                // 媒体总时长
                                _duration = asset.duration.value/asset.duration.timescale;
                                playerItem = [AVPlayerItem playerItemWithAsset:asset];
                                
                                // ensure that this is done before the playerItem is associated with the player
                                [playerItem addObserver:self forKeyPath:@"status"
                                                     options:NSKeyValueObservingOptionInitial context:&ItemStatusContext];
                                
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
                                        currentTimeUpdateBlock((float)(time.value)/time.timescale, self);
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
        dispatch_async(dispatch_get_main_queue(),
                       ^{
                           if (playerItemStatusChangeBlock) {
                               playerItemStatusChangeBlock(playerItem.status, self);
                           }
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

@end
