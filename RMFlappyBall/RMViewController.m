//
//  RMViewController.m
//  RMFlappyBall
//
//  Created by Ryosuke Mihara on 2014/02/22.
//  Copyright (c) 2014年 Ryosuke Mihara. All rights reserved.
//

#import "RMViewController.h"
#import "RMMyScene.h"

@implementation RMViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Configure the view.
    SKView * skView = (SKView *)self.view;
//    skView.showsFPS = YES;
//    skView.showsNodeCount = YES;
    
    // Create and configure the scene.
    SKScene * scene = [RMMyScene sceneWithSize:skView.bounds.size];
    scene.scaleMode = SKSceneScaleModeAspectFill;
    
    // Present the scene.
    [skView presentScene:scene];
}

- (BOOL)shouldAutorotate
{
    return NO;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationPortrait;
}

@end
