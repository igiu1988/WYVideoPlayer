//
//  WYTableViewController.m
//  WYVideoPlayer
//
//  Created by wangyang on 14-4-11.
//  Copyright (c) 2014年 com.wy. All rights reserved.
//

#import "WYTableViewController.h"

@interface WYTableViewController ()
{
    NSTimer *timer;
}
@end

@implementation WYTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationController.navigationBarHidden = NO;
}


@end
