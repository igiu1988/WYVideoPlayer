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
@interface WYVideoPlayerView : UIView

/**
 *  视频时长，单位是s。
 *  在setPlayerItemStatusChangeBlock调用时该duration才被正确初始化。所以最好在那里调用该duration。或者也可以使用key-observer
 */
@property (assign, readonly) int64_t duration;

/**
 *  当前视频时间，在视频正在加载或者播放时，直接赋值可更改视频播放起点。单位是s
 */
@property (assign, nonatomic) int64_t currentTime;

/**
 *  当rate是0时，表示视频是暂停状态。更改此值就可以改变播放速率
 */
@property (assign, nonatomic) float rate;

@property (readonly, nonatomic) BOOL isPauseByUser;
/**
 *  当前正要播放的视频最后一次播放的时间点，再次播放该视频时，播放器会从该时间点开始。
 *  如果上一次视频已播放结束，那么lastPlayedTime为0
 *  如果useLastPlayedTime为NO，该属性失效
 *  会创建一个plist文件，以视频md5(fileURL)作为key，以播放的秒数作为value
 */
@property (readonly, nonatomic) int64_t lastPlayedTime;

// 默认是YES
@property (assign, nonatomic) BOOL useLastPlayedTime;


/**
 *  默认在加载时什么也不显示。一般来说是一个图片，播放器会自动将customActivityIndicatorView显示在loadingView中间
 */
@property (nonatomic, strong) UIView *loadingView;

/**
 *  载入视频，可以是fileURL，或者是neturl
 *
 */
- (void)loadURL:(NSURL *)url;


- (void)fullScreen;

// 播放时，rate是1
- (void)play;
// 暂停时，rate是0
- (void)userPause;

// 只在view controller pop时调用
- (void)stop;

/**
 *  视频第一次缓冲并可以播放时的回调
 */
- (void)setPlayerItemStatusChangeBlock:(void (^)(AVPlayerItemStatus status, WYVideoPlayerView *playerView))block;

/**
 *  视频播放进度回调
 *  currentTime是以秒为单位
 */
- (void)setCurrentTimeUpdateBlock:(void(^)(int64_t currentTime, WYVideoPlayerView *playerView))block;

/**
 *  播放器旋转时的回调
 *
 */
- (void)setOrientationWillChangeBlock:(void(^)(float animationDuration, UIInterfaceOrientation orientationWillChangeTo, float angle, WYVideoPlayerView *playerView))block;

/**
 *  视频已加载的时间的回调。一般用于远程视频
 *
 */
- (void)setLoadedTimeUpdateBlock:(void(^)(int64_t loadTime, WYVideoPlayerView *playerView))block;

/**
 *  播放器是否需要显示activityIndicator的回调
 *
 */
- (void)setNeedShowActivityIndicatorViewBlock:(void (^)(BOOL shouldShow, WYVideoPlayerView *playerView))block;
@end



