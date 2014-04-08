//
//  WYVidoePlayerView.m
//  paper
//
//  Created by wangyang on 14-4-2.
//  Copyright (c) 2014年 com.wy. All rights reserved.
//

#import "WYVidoePlayerView.h"

@implementation WYVidoePlayerView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

+ (Class)layerClass {
    return [AVPlayerLayer class];
}

- (AVPlayer*)player {
    return [(AVPlayerLayer *)[self layer] player];
}

- (void)setPlayer:(AVPlayer *)player {
    [(AVPlayerLayer *)[self layer] setPlayer:player];    
    
}

@end
