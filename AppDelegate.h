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

@interface AppDelegate : UIResponder <UIApplicationDelegate, NGTabBarControllerDelegate, UITextViewDelegate> {
    int currentIndex;
    MediaLibrary* mediaIndex;
    NGTabBarController *tbc;
	ALAssetsLibrary *assetsLibrary;    
    NSMutableArray *viewController;
}

-(void)indexIPodLibrary;

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic) int currentIndex;
@property (nonatomic) MediaLibrary* mediaIndex;

@end
