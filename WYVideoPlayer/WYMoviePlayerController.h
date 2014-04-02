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
@class WYVidoePlayerView;
@interface WYMoviePlayerController : UIViewController
@property (nonatomic) AVPlayer *player;
@property (nonatomic) AVPlayerItem *playerItem;
@property (nonatomic, weak) IBOutlet WYVidoePlayerView *playerView;
@property (nonatomic, weak) IBOutlet UIButton *playButton;

@end
