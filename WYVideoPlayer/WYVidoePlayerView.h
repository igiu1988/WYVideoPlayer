//
//  WYVidoePlayerView.h
//  paper
//
//  Created by wangyang on 14-4-2.
//  Copyright (c) 2014年 com.wy All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>


/**
 *  1. play view 只管理播放的基本控制及信息。只提供控制接口，不提供控制相关的UI. 全屏，播放，暂停，进度，总时长
 *  2. play view 不提供手势操作，想要实现在你自己的view controller里自己加。一般来说有单击隐藏控制栏，双击全屏。
 */
@interface WYVidoePlayerView : UIView

@property (assign, readonly) int64_t duration;  // 视频时长

/**
 *  当前视频时间，在视频正在加载或者播放时，直接赋值可更改视频播放起点
 */
@property (assign) float currentTime;

/**
 *  当rate是0时，表示视频是暂停状态。更改此值就可以改变播放速率
 */
@property (assign) float rate;

///**
// *  默认是黑色
// */
//@property (nonatomic, strong) UIColor *backgroundColor;

/**
 *  默认在加载时什么也不显示。一般来说是一个图片，播放器会自动将customActivityIndicatorView显示在loadingView中间
 */
@property (nonatomic, strong) UIView *loadingView;

/**
 *  当没有网络时，或者需要缓冲时要显示的ActivityIndicatorView
 */
@property (nonatomic, strong) UIView *customActivityIndicatorView;
/**
 *  载入视频，可以是fileURL，或者是neturl
 *
 */
- (void)loadURL:(NSURL *)url;
- (void)fullScreen;

// 播放时，rate是1
- (void)play;
// 暂停时，rate是0
- (void)pause;

// 只在view controller pop时调用
- (void)stop;

- (void)setPlayerItemStatusChangeBlock:(void (^)(AVPlayerItemStatus status, WYVidoePlayerView *playerView))block;
- (void)setCurrentTimeUpdateBlock:(void(^)(int64_t currentTime, WYVidoePlayerView *playerView))block;
- (void)setOrientationWillChangeBlock:(void(^)(float animationDuration, UIInterfaceOrientation orientationWillChangeTo, float angle, WYVidoePlayerView *playerView))block;
- (void)setLoadedTimeUpdateBlock:(void(^)(int64_t loadTime, WYVidoePlayerView *playerView))block;

@end

