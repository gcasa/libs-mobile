//
//  TNMediaPlayerTestViewController.m
//  UIKitDemo
//
//  Created by TaoZeyu on 16/3/21.
//  Copyright © 2016年 Shanghai TinyNetwork Inc. All rights reserved.
//

#import "TNMediaPlayerTestViewController.h"
#import <MediaPlayer/MediaPlayer.h>

@interface TNMediaPlayerTestViewController ()
@property (nonatomic ,strong) MPMoviePlayerController *player;
@end

@implementation TNMediaPlayerTestViewController

+ (void)load
{
    [self regisiterTestClass:self];
}

+ (NSString *)testName
{
    return @"Media Player Test";
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor greenColor];
    
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button setTitle:@"Load" forState:UIControlStateNormal];
    [button addTarget:self action:@selector(loadMovie:) forControlEvents:UIControlEventTouchUpInside];
    [button sizeToFit];
    button.center = CGPointMake(button.frame.size.width/2, 800);
    [self.view addSubview:button];
    
    UIButton *button1 = [UIButton buttonWithType:UIButtonTypeSystem];
    [button1 setTitle:@"Pause" forState:UIControlStateNormal];
    [button1 addTarget:self action:@selector(pause:) forControlEvents:UIControlEventTouchUpInside];
    [button1 sizeToFit];
    button1.center = CGPointMake(CGRectGetMaxX(button.frame) + button1.bounds.size.width/2 + 10, button.center.y);
    [self.view addSubview:button1];
    
    UIBarButtonItem *pauseItem = [[UIBarButtonItem alloc] initWithTitle:@"pause" style:UIBarButtonItemStylePlain target:self action:@selector(pause:)];
    UIBarButtonItem *loadItem = [[UIBarButtonItem alloc] initWithTitle:@"load" style:UIBarButtonItemStylePlain target:self action:@selector(loadMovie:)];
    UIBarButtonItem *playItem = [[UIBarButtonItem alloc] initWithTitle:@"play" style:UIBarButtonItemStylePlain target:self action:@selector(play:)];
    
    self.navigationItem.rightBarButtonItems = @[pauseItem,loadItem,playItem];
}

- (void)pause:(id)sender
{
    [self.player pause];
}

- (void)play:(id)sender
{
    [self.player play];
}

- (void)loadMovie:(id)sender
{
    if (self.player) {
        [self.player.view removeFromSuperview];
        self.player = nil;
    }
    
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"jobs" withExtension:@"mp4"];
    if (!url) {
        NSURL *document = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
        url = [document URLByAppendingPathComponent:@"jobs.mp4"];
    }
    MPMoviePlayerController *mpc = [[MPMoviePlayerController alloc] initWithContentURL:url];
    [mpc setControlStyle:MPMovieControlStyleDefault];
    self.player = mpc;
    mpc.view.frame = CGRectMake(0, 50, 640, 480);
    
    [self.view addSubview:mpc.view];
    
    [mpc play];
}

@end

