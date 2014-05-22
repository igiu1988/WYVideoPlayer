//
//  WYMoviePlayerController.h
//  paper
//
//  Created by wangyang on 14-4-1.
//  Copyright (c) 2014年 com.zkyj. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

/*
 播放控制不要加到WYVidoePlayerView里，需要在这里自定义。
 */
@class WYVideoPlayerView;
@interface WYMoviePlayerController : UIViewController
@property (nonatomic) AVPlayer *player;

@property (nonatomic, weak) IBOutlet WYVideoPlayerView *playerView;


@end