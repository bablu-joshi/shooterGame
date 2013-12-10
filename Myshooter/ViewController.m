//
//  ViewController.m
//  Myshooter
//
//  Created by qainfotech on 10/12/13.
//  Copyright (c) 2013 qainfotech. All rights reserved.
//

#import "ViewController.h"
#import "MyScene.h"

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Configure the view.
    SKView * skView = (SKView *)self.view;
    skView.showsFPS = NO;
    skView.showsNodeCount = NO;
    
    // Create and configure the scene.
    SKScene * scene = [MyScene sceneWithSize:skView.bounds.size];
    scene.scaleMode = SKSceneScaleModeAspectFill;
    
    // Present the scene.
    [skView presentScene:scene];
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    // Configure the view.
    // Configure the view after it has been sized for the correct orientation.
    SKView *skView = (SKView *)self.view;
    if (!skView.scene) {
        skView.showsFPS = NO;
        skView.showsNodeCount = NO;
        
        // Create and configure the scene.
        MyScene *theScene = [MyScene sceneWithSize:skView.bounds.size];
        theScene.scaleMode = SKSceneScaleModeAspectFill;
        
        // Present the scene.
        [skView presentScene:theScene];
    }
}




- (BOOL)shouldAutorotate
{
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return UIInterfaceOrientationMaskAllButUpsideDown;
    } else {
        return UIInterfaceOrientationMaskAll;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

@end
