//
//  AppDelegate.h
//  NGTabBarControllerDemo
//
//  Created by Tretter Matthias on 16.02.12.
//  Copyright (c) 2012 NOUS Wissensmanagement GmbH. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NGTabBarController.h"
#import "IASKAppSettingsViewController.h"

@class MediaLibrary, ALAssetsLibrary;

@interface AppDelegate : UIResponder <IASKSettingsDelegate, UIApplicationDelegate, NGTabBarControllerDelegate, UITextViewDelegate> {
    UIPopoverController* popover;
    int currentIndex;
    MediaLibrary* mediaIndex;
    NGTabBarController *tbc;
    IASKAppSettingsViewController *appSettingsViewController;    
	ALAssetsLibrary *assetsLibrary;    
    NSMutableArray *viewController;
}

-(void)indexIPodLibrary;

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic) int currentIndex;
@property (nonatomic) MediaLibrary* mediaIndex;
@property (nonatomic, retain) IASKAppSettingsViewController *appSettingsViewController;

@end
