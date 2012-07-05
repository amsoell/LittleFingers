//
//  NGVTabBarController.m
//  NGVerticalTabBarControllerDemo
//
//  Created by Tretter Matthias on 24.04.12.
//  Copyright (c) 2012 NOUS Wissensmanagement GmbH. All rights reserved.
//

#import "NGVTabBarController.h"

@interface NGVTabBarController ()

- (void)setupForInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation;

@end

@implementation NGVTabBarController

- (id)initWithDelegate:(id<NGTabBarControllerDelegate>)delegate {
    self = [super initWithDelegate:delegate];
    if (self) {
        self.animation = NGTabBarControllerAnimationMoveAndScale;
        self.tabBar.tintColor = [UIColor colorWithRed:143.f/255.f green:139.f/255.f blue:47.f/255.f alpha:1.f];
        self.tabBar.itemPadding = 10.f;
        [self setupForInterfaceOrientation:[UIApplication sharedApplication].statusBarOrientation];
    }
    return self;
}


- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    
    [self setupForInterfaceOrientation:toInterfaceOrientation];
}

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)orientation {
    return YES;
}

////////////////////////////////////////////////////////////////////////
#pragma mark - Private
////////////////////////////////////////////////////////////////////////

- (void)setupForInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation; {

    self.tabBarPosition = NGTabBarPositionLeft;
    self.tabBar.drawItemHighlight = YES;
    self.tabBar.drawGloss = YES;
    self.tabBar.layoutStrategy = NGTabBarLayoutStrategyStrungTogether;

}

- (void)didSelectViewController:(UIViewController *)viewController atIndex:(NSUInteger)index {
    NSLog(@"index %@", index);
}


@end
