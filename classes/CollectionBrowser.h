//
//  CollectionBrowser.h
//  NGVerticalTabBarControllerDemo
//
//  Created by Andy Soell on 7/3/12.
//  Copyright (c) 2012 NOUS Wissensmanagement GmbH. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PlaybackViewController;

@interface CollectionBrowser : UIViewController <UITableViewDataSource,UITableViewDelegate> {
    NSArray *dataSource;   
	PlaybackViewController* playbackViewController;
    UINavigationController* videoPlaybackController;
    UIViewController *owner;
}

- (id)initWithCollection:(NSArray *)collection andOwner:(UIViewController *)viewController;

@property (nonatomic, strong) NSArray *dataSource;
@property (nonatomic, strong) UIViewController *owner;

@end
